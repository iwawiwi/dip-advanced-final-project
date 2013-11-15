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
            faceImage = [baseFolder, 'cohn-kanade-images\', path1, '\', path2, '\', shortname, '.png'];
            pathArr = [pathArr; faceImage];
            classArr = [classArr; text];
        end
    end
end
toc
tic
%% Read CK-plus Image
for i=1:size(pathArr,1)
    %% Read Image
    Imgdat = imread(pathArr(1,:));
    if size(Imgdat, 3) == 3 % if color images, convert it to gray
        Imgdat = rgb2gray(Imgdat);
    end
    [height width] = size(Imgdat);
    if i == 1
        VolData = zeros(height, width, size(pathArr,1));
    end
    VolData(:, :, i) = Imgdat;
end
toc
tic
%% Change to current Directory
cd(currDirectory);

%% Do Texture Analysis
%% VLBP
% "RotateIndex": 0: basic VLBP without rotation;
%                1: new Rotation invariant descriptor published in PAMI 2007;
%                2: old Rotation invariant descriptor published in ECCV
%                workshop 2006
RotateIndex = 0;

% parameter set
% 1. the radii parameter in space and Time axis; They could be 1, 2 or 3 or 4
FRadius = 1; 
TInterval = 2;

% 2. the number of the neighboring points; It can be 2 and 4.
NeighborPoints = 4;

% 3. "TimeLength" and "BorderLength" are the parameters for bordering parts in time and
% space which would not be computed for features. Usually they are same to TInterval and
% the bigger one of "FRadius";
TimeLength = 2;
BorderLength = 1;

% 4. "bBilinearInterpolation" : if use bilinear interpolation for computing a
% neighbor point in a circle: 1 (yes), 0 (not)
bBilinearInterpolation = 0;

% call VLBP
fHistogram = RIVLBP(VolData, TInterval, FRadius, NeighborPoints, BorderLength, TimeLength, RotateIndex, bBilinearInterpolation);
%% LBP-TOP
% parameter set

% 1. "FxRadius", "FyRadius" and "TInterval" are the radii parameter along X, Y and T axis; They can be 1, 2, 3 and 4. "1" and "3" are recommended.
%  Pay attention to "TInterval". "TInterval * 2 + 1" should be smaller than the length of the input sequence "Length". 
% For example, if one sequence includes seven frames, and you set TInterval
% to three, only the pixels in the frame 4 would be considered as central
% pixel and computed to get the LBP-TOP feature.
FxRadius = 1; 
FyRadius = 1;
TInterval = 2;

% 2. "TimeLength" and "BoderLength" are the parameters for bodering parts in time and space which would not
% be computed for features. Usually they are same to TInterval and the
% bigger one of "FxRadius" and "FyRadius";
TimeLength = 2;
BorderLength = 1;

% 3. "bBilinearInterpolation" : if use bilinear interpolation for computing a
% neighbor point in a circle: 1 (yes), 0 (not)
bBilinearInterpolation = 1;  % 0: not / 1: bilinear interpolation
%% 59 is only for neighboring points with 8. If won't compute uniform
%% patterns, please set it to 0, then basic LBP will be computed
Bincount = 0; %59 / 0
NeighborPoints = [8 8 8]; % XY, XT, and YT planes, respectively
if Bincount == 0
    Code = 0;
    nDim = 2 ^ (NeighborPoints(1));  %dimensionality of basic LBP
else
    % uniform patterns for neighboring points with 8
    U8File = importdata('UniformLBP8.txt');
    BinNum = U8File(1, 1);
    nDim = U8File(1, 2); %dimensionality of uniform patterns
    Code = U8File(2 : end, :);
    clear U8File;
end
% call LBPTOP
Histogram = LBPTOP(VolData, FxRadius, FyRadius, TInterval, NeighborPoints, TimeLength, BorderLength, bBilinearInterpolation, Bincount, Code);
toc

% cd('..\ck-face-db\ck-plus\cohn-kanade-images\'); % please replace "..." by your images path