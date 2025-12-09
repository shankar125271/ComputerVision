% color_spectra_diff_image.m
% Create a color image with very different R/G/B content and show FFT spectra.
% Save and run: >> color_spectra_diff_image

clear; close all; clc;

% --- Parameters ---
N = 512;                 % image size (NxN)
freqR = 32;              % horizontal stripe frequency (cycles across height)
freqG = 8;               % vertical stripe frequency (cycles across width)
checkerSize = 8;         % size of checker squares in pixels (for blue channel)

% --- Create coordinate grids ---
[x, y] = meshgrid(1:N, 1:N);
xc = (x - N/2) / N;
yc = (y - N/2) / N;

% --- Red channel: high-frequency horizontal stripes (sinusoidal) ---
red = 0.5 + 0.5 * sin(2*pi*freqR * (y / N));   % values in [0,1]

% --- Green channel: vertical stripes plus a horizontal gradient (medium freq) ---
green_stripes = 0.5 + 0.5 * sin(2*pi*freqG * (x / N));
green_grad = repmat(linspace(0,1,N), N, 1);    % left-to-right gradient
green = 0.6*green_stripes + 0.4*green_grad;
green = green / max(green(:));                 % normalize to [0,1]

% --- Blue channel: checkerboard (2D high-frequency) ---
bx = floor(x / checkerSize);
by = floor(y / checkerSize);
checker = mod(bx + by, 2);     % 0/1 checker
blue = checker;                % values 0 or 1

% --- Compose RGB image ---
I = cat(3, red, green, blue);

% Convert to double in [0,1]
I = im2double(I);

% --- Compute FFT log-magnitude spectra per channel ---
logMag = cell(1,3);
mag = cell(1,3);
for ch = 1:3
    F = fftshift(fft2(I(:,:,ch)));
    mag{ch} = abs(F);
    logMag{ch} = mat2gray(log(1 + mag{ch})); % normalized for display
end

% --- Compute difference spectra to highlight differences ---
diffRG = mat2gray(abs(logMag{1} - logMag{2}));
diffGB = mat2gray(abs(logMag{2} - logMag{3}));

% --- Display results ---
figure('Name','Different R/G/B Spectra Demo','Units','normalized','Position',[0.05 0.05 0.9 0.7]);

% Top row: original and separate channels
subplot(2,4,1); imshow(I); title('Original RGB');
subplot(2,4,2); imshow(I(:,:,1)); title('Red channel (horizontal stripes)');
subplot(2,4,3); imshow(I(:,:,2)); title('Green channel (vertical + gradient)');
subplot(2,4,4); imshow(I(:,:,3)); title('Blue channel (checkerboard)');

% Bottom row: log-magnitude spectra
subplot(2,4,5); imagesc(logMag{1}); axis image off; colormap(gca,'hot'); title('Log Spectrum - Red');
subplot(2,4,6); imagesc(logMag{2}); axis image off; colormap(gca,'hot'); title('Log Spectrum - Green');
subplot(2,4,7); imagesc(logMag{3}); axis image off; colormap(gca,'hot'); title('Log Spectrum - Blue');

% last panel: difference spectra
subplot(2,4,8); 
imshow([im2uint8(diffRG) im2uint8(diffGB)]); axis image off;
title('Diff spectra: |R-G| (left)  |G-B| (right)');

sgtitle('Color Image with Distinct Channel Spectra');

% --- print quick guidance ---
fprintf('Image created with distinct R/G/B patterns.\n');
fprintf('Observe: Red spectrum will show strong horizontal-frequency lobes,\nGreen will show vertical-frequency lobes and DC gradient, Blue shows 2D checkerboard harmonics.\n');

% --- Optional: save the synthetic image (uncomment to save) ---
% imwrite(I, 'synthetic_rgb_diff.png');

