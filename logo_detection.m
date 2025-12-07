%% Lane Detection & Edge of Road using Sobel + Canny
clear; close all; clc;

%% Step 1: Read Input Image
img = imread('https://cdn.wallpapersafari.com/45/63/Ezuc1k.jpg');   % <-- Replace with your image
figure, imshow(img), title('Original Road Image');

%% Step 2: Convert to Grayscale
gray = rgb2gray(img);

%% Step 3: Gradient Magnitude & Direction (Sobel)
[Gx, Gy] = imgradientxy(gray, 'sobel');   
[Gmag, Gdir] = imgradient(Gx, Gy);

figure,
subplot(1,2,1), imshow(Gmag, []), title('Gradient Magnitude');
subplot(1,2,2), imshow(Gdir, []), title('Gradient Direction');

%% Step 4: Edge Detection (Canny)
edges = edge(gray, 'canny');
figure, imshow(edges), title('Canny Edge Map');

%% Step 5: Highlight Lane Markings (Using threshold on magnitude)
laneMask = Gmag > 50;   % adjust for your image
figure, imshow(laneMask), title('Strong Gradient Areas (Possible Lanes)');

%% Step 6: Region of Interest (Optional but recommended)
% Create a triangular mask to focus on road area
[h, w] = size(gray);
mask = poly2mask([0 w w/2], [h h h/2], h, w);

roi = edges & mask;
figure, imshow(roi), title('Edges in Road ROI');

%% Step 7: Hough Transform to Detect Lane Lines
[H, theta, rho] = hough(roi);
peaks = houghpeaks(H, 10);
lines = houghlines(roi, theta, rho, peaks, 'FillGap', 20, 'MinLength', 30);

figure, imshow(img), hold on, title('Detected Lane Lines');

for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    plot(xy(:,1), xy(:,2), 'LineWidth', 3, 'Color', 'yellow');

    % mark end points
    plot(xy(1,1), xy(1,2), 'ro');
    plot(xy(2,1), xy(2,2), 'go');
end
hold off;
