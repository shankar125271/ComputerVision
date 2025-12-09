close all; clear; clc;

%% -------------------- GRAYSCALE IMAGE --------------------
I = im2double(imread('cameraman.tif'));

F  = fft2(I);
F  = fftshift(F);

mag = log(1 + abs(F));
phs = angle(F);

figure('Name','Grayscale FFT');

subplot(1,3,1), imshow(I,[]);     title('Original');
subplot(1,3,2), imshow(mag,[]);   title('Magnitude Spectrum');
subplot(1,3,3), imshow(phs,[]);   title('Phase Spectrum');


%% -------------------- COLOUR IMAGE --------------------
Ic = im2double(imread('peppers.png'));

% Convert to FFT magnitude for each channel
R = Ic(:,:,1); G = Ic(:,:,2); B = Ic(:,:,3);

FR = fftshift(fft2(R));
FG = fftshift(fft2(G));
FB = fftshift(fft2(B));

magR = log(1 + abs(FR));
magG = log(1 + abs(FG));
magB = log(1 + abs(FB));

figure('Name','Colour FFT');

subplot(2,2,1), imshow(Ic);     title('Original Colour Image');
subplot(2,2,2), imshow(magR,[]); title('Red Channel Spectrum');
subplot(2,2,3), imshow(magG,[]); title('Green Channel Spectrum');
subplot(2,2,4), imshow(magB,[]); title('Blue Channel Spectrum');
