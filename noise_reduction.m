%% Noise Reduction Demonstration (Visible Results)

clear; close all; clc;

%% Load your image
url = 'https://thumbs.dreamstime.com/b/cute-sparrow-tree-branch-making-noise-shouting-sparrow-bird-tree-branch-which-making-noise-346110686.jpg';
img = im2double(imread(url));
gray = rgb2gray(img);

%% ADD ARTIFICIAL NOISE (so filtering makes a difference)
noisy = imnoise(gray, 'gaussian', 0, 0.01);     % Add Gaussian noise
noisy_sp = imnoise(gray, 'salt & pepper', 0.05); % SP noise version

figure; imshow(noisy); title('Noisy Image (Gaussian Noise)');

%% Create filters
avgFilter = fspecial('average', [5 5]);
gaussFilter = fspecial('gaussian', [7 7], 1.5);

%% Apply filters
f_avg     = imfilter(noisy, avgFilter, 'replicate');
f_gauss   = imfilter(noisy, gaussFilter, 'replicate');
f_median  = medfilt2(noisy, [5 5]);
f_wiener  = wiener2(noisy, [5 5]);

%% Show Results
figure;

subplot(2,3,1), imshow(noisy), title('Noisy Image');
subplot(2,3,2), imshow(f_avg), title('Average Filter');
subplot(2,3,3), imshow(f_gauss), title('Gaussian Filter');
subplot(2,3,4), imshow(f_median), title('Median Filter');
subplot(2,3,5), imshow(f_wiener), title('Wiener Filter');
