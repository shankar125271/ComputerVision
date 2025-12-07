clc; clear; close all;

% ---------------------------------------------------------
% Step 1: Load an inbuilt MATLAB image (choose one)
% ---------------------------------------------------------
img = imread('peppers.png');     % You can change to 'onion.png', 'saturn.png', etc.
figure; imshow(img); title('Original Image');

% Convert to grayscale (watershed works on single channel)
gray = rgb2gray(img);

% ---------------------------------------------------------
% Step 2: Compute the gradient magnitude (important for watershed)
% ---------------------------------------------------------
gmag = imgradient(gray);

figure; imshow(gmag,[]);
title('Gradient Magnitude Image');

% ---------------------------------------------------------
% Step 3: Apply Watershed transform
% ---------------------------------------------------------
L = watershed(gmag);          % Label matrix of watershed regions

% Create a binary mask for watershed ridge lines
watershedBoundaries = L == 0;

figure; imshow(watershedBoundaries);
title('Watershed Ridge Lines');

% ---------------------------------------------------------
% Step 4: Superimpose the watershed boundaries on the original image
% ---------------------------------------------------------
img2 = img;
img2(:,:,1) = img(:,:,1) + uint8(watershedBoundaries)*255;  % Red boundaries

figure; imshow(img2);
title('Watershed Segmentation Result');