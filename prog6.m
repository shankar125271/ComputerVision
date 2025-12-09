% simple_aliasing.m
% Simple 2D aliasing demo (checkerboard undersampling)
clear; close all; clc;

% parameters
orig_checks = 12;     % number of checks across the image
pixelsPerCheck = 16;  % high-res sampling inside each check (ground truth)
f = 4;                % undersampling factor (integer >=1). Try 2,4,8.

% build high-res checkerboard (no toolboxes)
block = pixelsPerCheck;
N = orig_checks * block;
CB = zeros(N,N);
for r = 1:orig_checks
    for c = 1:orig_checks
        val = mod(r+c,2);
        rs = (r-1)*block + 1;
        cs = (c-1)*block + 1;
        CB(rs:rs+block-1, cs:cs+block-1) = val;
    end
end
CB = uint8(CB*255);

% undersample (take every f-th pixel) and reconstruct by nearest neighbor
sampled = CB(1:f:end, 1:f:end);
recon_nearest = imresize(sampled, [N N], 'nearest');

% compute log magnitude spectra for visualization
logSpec = @(I) mat2gray(log(1 + abs(fftshift(fft2(double(I))))));

% display
figure('Name','Simple 2D Aliasing Demo','NumberTitle','off','Position',[100 100 1000 450]);

subplot(2,4,1); imshow(CB); title('Ground truth');
subplot(2,4,2); imshow(sampled, 'InitialMagnification','fit'); title(sprintf('Sampled (1/%d)', f));
subplot(2,4,3); imshow(recon_nearest); title('Reconstructed (nearest)');
subplot(2,4,4); imshowpair(CB, recon_nearest,'montage'); title('GT (left) vs Recon (right)');

subplot(2,4,5); imagesc(logSpec(CB)); axis image off; colormap gray; title('Spectrum: GT');
subplot(2,4,6); imagesc(logSpec(sampled)); axis image off; colormap gray; title('Spectrum: Sampled');
subplot(2,4,7); imagesc(logSpec(recon_nearest)); axis image off; colormap gray; title('Spectrum: Recon (nearest)');
subplot(2,4,8); imshow(recon_nearest(round(end/2)-64:round(end/2)+63, round(end/2)-64:round(end/2)+63));
title('Zoom (recon center)');

% short message
fprintf('Undersampling factor f = %d. Try changing f to 2,4,8 and re-run to see stronger aliasing.\n', f);
