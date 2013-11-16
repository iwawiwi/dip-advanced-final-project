clc
clear all

tic
currDirectory = pwd;
% Base folder path
baseFolder = 'D:\Documents\Research\Research Dataset\ck-face-db\ck-plus\';

cd([baseFolder, 'Emotion\']); % please replace "..." by your images path
% List directories in path. Taken from:
% http://stackoverflow.com/questions/8748976/
% list-the-subfolders-in-a-folder-matlab-only-subfolders-not-files
%
d = dir();
isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];


pathArr = [];
classArr = [];
emotionPath = pwd;
for i = 1:size(nameFolds,1)
    %% Ke folder individunya
    path1 = nameFolds{i};
    fPath1 = [emotionPath, '\', path1];
    cd(fPath1);
    % Cek ke dalam lagi untuk liat daftar sampel
    d2 = dir();
    isub2 = [d2(:).isdir]; %# returns logical vector
    nameFolds2 = {d2(isub2).name}';
    nameFolds2(ismember(nameFolds2,{'.','..'})) = [];
    for j = 1:size(nameFolds2,1)
        %% Masuk ke folder tiap sampel
        path2 = nameFolds2{j};
        fPath2 = [fPath1, '\', path2];
        cd(fPath2)
        % Cek ke dalam lagi untuk liat daftar sampel
        d3 = dir();
        isub3 = [d3(:).isdir]; %# returns logical vector
        isub3 = ~isub3; %# inverse to know file properties
        % Dapat nama filenya
        nameFolds3 = {d3(isub3).name}';
        if (size(nameFolds3,1) ~= 0)
            filename = nameFolds3{1};
            % Baca isi file, itu kelasnya
            fid = fopen(filename);
            text = textscan(fid, '%f'); %# Tipe datanya cell
            fclose(fid);
            shortname = filename(1:17); %# Cari nama filenya aja supaya bisa di manipulasi
            faceImage = [baseFolder, 'cohn-kanade-images\', path1, '\', path2, '\'];
            pathArr = [pathArr; faceImage];
            classArr = [classArr; text];
        end
    end
end
toc
tic
%% Read CK-plus Image
vlbp_histArr = [];
lbptop_xy_histArr = [];
lbptop_xt_histArr = [];
lbptop_yt_histArr = [];
for i=1:size(pathArr,1)
    %% Read All sequence
    cd(pathArr(1,:)); % please replace "..." by your images path
    a = dir('*.png'); % directory of images, ".jpg" can be changed, for example, ".bmp" if you use
    clear VolData
    for j=1:length(a)
        ImgName = getfield(a, {j}, 'name');
        Imgdat = imread(ImgName);
        if size(Imgdat, 3) == 3 % if color images, convert it to gray
            Imgdat = rgb2gray(Imgdat);
        end
        [height width] = size(Imgdat);
        if j == 1
            VolData = zeros(height, width, length(a));
        end
        VolData(:, :, j) = Imgdat;
    end
    %% Analyze Texture
    cd(currDirectory); %# restore directory
    [vlbp_hist, lbptop_hist] = analyzeTexture(VolData);
    size(vlbp_hist)
    size(lbptop_hist)
    %% Concat Feature
    vlbp_histArr = [vlbp_histArr; vlbp_hist'];
    lbptop_xy__histArr = [lbptop_xy_histArr; lbptop_hist(1,:)];
    lbptop_xt__histArr = [lbptop_xt_histArr; lbptop_hist(2,:)];
    lbptop_yt__histArr = [lbptop_yt__histArr; lbptop_hist(3,:)];
end
toc

% cd('..\ck-face-db\ck-plus\cohn-kanade-images\'); % please replace "..." by your images path