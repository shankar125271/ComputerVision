clc; clear; close all;

%% -----------------------------------------------------------
% Part A – Load Stereo Parameters and Images
% ------------------------------------------------------------
% This .mat file is part of the Computer Vision Toolbox examples.
% It contains 'stereoParams' for a calibrated stereo camera.
addpath('C:\Users\shank\OneDrive\Documents\MATLAB\Examples\R2024b\vision\StitchPointCloudsExample');
load visionStereoParameters.mat


% Sample stereo pair from the same example set
Ileft  = imread('left_stereo_generated.jpg');
Iright = imread('right_stereo.jpg');

figure;
subplot(1,2,1); imshow(Ileft);  title('Left Image');
subplot(1,2,2); imshow(Iright); title('Right Image');

%% -----------------------------------------------------------
% Rectify images
% ------------------------------------------------------------
[Jleft, Jright] = rectifyStereoImages(Ileft, Iright, stereoParams);

figure;
subplot(1,2,1); imshow(Jleft);  title('Rectified Left');
subplot(1,2,2); imshow(Jright); title('Rectified Right');

%% -----------------------------------------------------------
% Part B – Compute Disparity Map
% ------------------------------------------------------------
IL = rgb2gray(Jleft);
IR = rgb2gray(Jright);

% Set disparity range (tune if needed)
disparityRange = [0 64];

disparityMap = disparitySGM(IL, IR, ...
    'DisparityRange', disparityRange, ...
    'UniquenessThreshold', 15);

figure;
imshow(disparityMap, disparityRange);
title('Disparity Map');
colormap(gca, jet); colorbar;
drawnow;

%% -----------------------------------------------------------
% Part C – Depth Estimation
% ------------------------------------------------------------
% Reconstruct 3D scene (in millimeters)
points3D = reconstructScene(disparityMap, stereoParams);

% Extract Z (depth) and convert -> meters
Z = points3D(:,:,3) / 1000;  % mm -> meters

% Invalid depth where disparity is invalid or <= 0
Z(disparityMap <= 0) = NaN;

figure;
imagesc(Z, [0 10]);          % show depth up to 10 m
axis image; colorbar;
title('Depth Map (meters)');
colormap(gca, jet);

%% -----------------------------------------------------------
% Part D – Obstacle Map (Binary)
% ------------------------------------------------------------
% Consider anything closer than 3 m as obstacle
minDepth = 0.1;     % ignore very tiny distances/noise
maxSafeDepth = 3.0; % threshold for "too close"

obstacleMap = (Z > minDepth) & (Z < maxSafeDepth);

% Clean up noise
obstacleMap = imclose(obstacleMap, strel('disk', 3));
obstacleMap = imfill(obstacleMap, 'holes');

figure;
imshow(obstacleMap);
title('Binary Obstacle Map (white = obstacle)');

%% -----------------------------------------------------------
% Part E – Simple Path Planning (Image-space path)
% ------------------------------------------------------------
% Idea:
%   - Treat image as grid.
%   - Bottom row = robot start, top row = goal.
%   - White (1) in obstacleMap = blocked.
%   - Use dynamic programming to find a low-cost path from bottom to top.

[H, W] = size(obstacleMap);

% Cost matrix (initialize with Inf for obstacles)
cost = inf(H, W);
parentCol = zeros(H, W, 'int32');  % to backtrack path

% Start from bottom row: all free cells have cost 0
for c = 1:W
    if ~obstacleMap(H, c)
        cost(H, c) = 0;
    end
end

% Propagate cost from bottom -> top
for r = H-1:-1:1
    for c = 1:W
        if obstacleMap(r, c)
            continue; % cannot pass through obstacles
        end
        
        % allowed moves: down-left, down, down-right
      % Preallocate for 3 possible moves
candidates = inf(1,3);
candCols   = zeros(1,3);

idx = 1;
for dc = -1:1
    cc = c + dc;
    if cc >= 1 && cc <= W
        candidates(idx) = cost(r+1, cc);
        candCols(idx)   = cc;
    end
    idx = idx + 1;
end

[minCost, idxMin] = min(candidates);
if isfinite(minCost)
    cost(r, c) = 1 + minCost;
    parentCol(r, c) = candCols(idxMin);
end

        
        [minCost, idxMin] = min(candidates);
        if isfinite(minCost)
            cost(r, c) = 1 + minCost;    % uniform step cost = 1
            parentCol(r, c) = candCols(idxMin);
        end
    end
end


% Choose best starting column at the top row
[~, startCol] = min(cost(1, :));

if ~isfinite(cost(1, startCol))
    warning('No feasible path found from bottom to top.');
    pathRows = [];
    pathCols = [];
else
    % Backtrack from top row (r=1) to bottom row (r=H)
    pathCols = zeros(H,1,'int32');
    pathRows = (1:H).';  % 1,2,...,H
    
    col = startCol;
    for r = 1:H
        pathCols(r) = col;
        if r < H
            nextCol = parentCol(r, col);
            if nextCol == 0
                % dead end (should not happen often)
                pathRows = pathRows(1:r);
                pathCols = pathCols(1:r);
                break;
            end
            col = nextCol;
        end
    end
end

%% -----------------------------------------------------------
% Visualization: path over depth map and over original image
% ------------------------------------------------------------
figure;
imagesc(Z, [0 10]);
axis image; hold on;
colormap(gca, jet); colorbar;
title('Depth Map with Planned Path');
if ~isempty(pathCols)
    plot(pathCols, pathRows, 'k-', 'LineWidth', 2);
end
set(gca,'YDir','reverse'); % so row 1 is top visually

figure;
imshow(Jleft); hold on;
title('Planned Path Overlaid on Left Image');
if ~isempty(pathCols)
    % Plot same indices on original rectified image
    plot(pathCols, pathRows, 'g-', 'LineWidth', 2);
end
hold off;
