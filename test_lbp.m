clc
clear all
%% Format output value
%format long %# Change the output format you desired
%% Crop the face
CROP_FACE = 1;
BOUND_BOX_THRESHOLD = 120;
SHRINK_COEF = 1/2; %# Coefficient to Shrink the rectangle of detected face, 1 = normal

tic;
disp('Initializing System...');
%% Current root Directory
%# Change to your code root dir...
currDirectory = 'D:\Documents\Programming\MATLAB\dip-advanced-final-project';
%% Base image folder path
%# Change to your image root dir...
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
eta = toc;
disp(sprintf('Finished in %f second', eta));
disp('Read Image Batch...');
%% Read CK-plus Image
vlbp_histArr = [];
lbptop_xy_histArr = [];
lbptop_xt_histArr = [];
lbptop_yt_histArr = [];

%% Initialize Computer Vision toolbox for detecting the face
if CROP_FACE == 1
    % to detect face
    FDetect = vision.CascadeObjectDetector;
end

for i=1:size(pathArr,1)
    tic;
    disp(sprintf('Rading directory: %s', pathArr(i,:)));
    %% Read All sequence
    cd(pathArr(i,:)); % please replace "..." by your images path
    a = dir('*.png'); % directory of images, ".jpg" can be changed, for example, ".bmp" if you use
    clear VolData
    for j=1:length(a)
        ImgName = getfield(a, {j}, 'name');
        Imgdat = imread(ImgName);
        
        %% CROP THE IMAGE
        %# using computer vision toolbox to detect Face
        % Deteksi bounding box untuk gambar pertama saja supaya dimensinya
        % sama, kebetulan kameranya FIX jadi asumsi bounding box tetap
        if CROP_FACE == 1 && j == 1
            % return bounding box value
            BB = step(FDetect,Imgdat);
            
            %# Handling jika bounding box ada lebih dari 1
            if size(BB,1) == 0
                disp('ERROR: Face not detected!');
                break; % break j foor loop, data cannot be handled
            elseif size(BB,1) > 1
                disp('WARN: Two or more bounding box detected! Do greedy search for optimal bounding box!');
                choosen_idx = 1;
                for k=1:size(BB,1)
                    if BB(k,3) > BOUND_BOX_THRESHOLD && BB(k,4) > BOUND_BOX_THRESHOLD
                        BB = BB(k,:); % Overwrite current bounding box
                        break; % Break the k for loop
                    end
                end
            end
            %% Resize Bounding Box
            half_width = floor(BB(1,3)/2);
            xc_min = BB(1,1) + half_width; % x-coordinate for center of rectangle
            x_min_new = xc_min - floor(SHRINK_COEF * half_width);
            BB(1,1) = x_min_new; % Create new bounding box
            BB(1,3) = floor(SHRINK_COEF * BB(1,3));
        end
        % Do Face Crop
        if CROP_FACE == 1
            % Crop image using bounding box
            Imgdat = imcrop(Imgdat, BB);
        end
        
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
%     size(vlbp_hist)
%     size(lbptop_hist)
    %% Concat Features
    vlbp_histArr = [vlbp_histArr; vlbp_hist']; %# transpose the matrix
    lbptop_xy_histArr = [lbptop_xy_histArr; lbptop_hist(1,:)]; %# XY texture analysis
    lbptop_xt_histArr = [lbptop_xt_histArr; lbptop_hist(2,:)]; %# XT texture analysis
    lbptop_yt_histArr = [lbptop_yt_histArr; lbptop_hist(3,:)]; %# YT texture analysis
    eta = toc;
    disp(sprintf('Finished in %f', eta));
end

tic;
%% Combine All Features
disp('Concatenate All Features...');
classArr = cell2mat(classArr);
concated_vlbp = [vlbp_histArr classArr];
concated_lbptop = [lbptop_xy_histArr lbptop_xt_histArr lbptop_yt_histArr classArr];

csvwrite([currDirectory, '\vlbp_data.csv'], concated_vlbp);
csvwrite([currDirectory, '\lbptop_data.csv'], concated_lbptop);

%% Generate Label for Processing with WEKA
%# VLBP Preprocess
weka_label_1 = cell(1, size(concated_vlbp, 2));
offset_vlbp = size(concated_vlbp, 2) - 1;
for ii=1:size(concated_vlbp, 2)
    if ii >= 1 && ii <= offset_vlbp
        weka_label_1{ii} = ['attr' num2str(ii)];
    else
        weka_label_1{ii} = 'class';
    end
end
%% LBPTOP Preprocess
weka_label_2 = cell(1, size(concated_lbptop, 2));
offset_lbptop = size(concated_lbptop, 2) - 1;
offset_lbptop_xy = offset_lbptop / 3;
offset_lbptop_xt = 2 * offset_lbptop_xy;
offset_lbptop_yt = 3 * offset_lbptop_xy;
for ii=1:size(concated_lbptop, 2)
    if ii >= 1 && ii <= offset_lbptop_xy
        weka_label_2{ii} = ['attr_xy' num2str(ii)];
    elseif ii > offset_lbptop_xy && ii <= offset_lbptop_xt
        weka_label_2{ii} = ['attr_xt' num2str(ii-offset_lbptop_xy)];
    elseif ii > offset_lbptop_xt && ii <= offset_lbptop_yt
        weka_label_2{ii} = ['attr_yt' num2str(ii-offset_lbptop_xt)];
    else
        weka_label_2{ii} = 'class';
    end
end
%% Write to CSV with header
if CROP_FACE == 1
    csvwrite_with_headers([currDirectory, '\data\[SHR', num2str(SHRINK_COEF), ...
        ']weka_crop_vlbp_data.csv'], concated_vlbp, weka_label_1);
    csvwrite_with_headers([currDirectory, '\data\[SHR', num2str(SHRINK_COEF), ...
        ']weka_crop_lbptop_data.csv'], concated_lbptop, weka_label_2);
else
    csvwrite_with_headers([currDirectory, '\data\weka_raw_vlbp_data.csv'], ...
        concated_vlbp, weka_label_1);
    csvwrite_with_headers([currDirectory, '\data\weka_raw_lbptop_data.csv'], ...
        concated_lbptop, weka_label_2);
end

eta = toc;
disp(sprintf('Process Finished in %f!', eta));
clear all %# Clear All data

% cd('..\ck-face-db\ck-plus\cohn-kanade-images\'); % please replace "..." by your images path