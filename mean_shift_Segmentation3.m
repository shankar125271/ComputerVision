clc; clear; close all;

% -----------------------------------------------------------
% 1. Load MATLAB inbuilt image
% -----------------------------------------------------------
img = imread('peppers.png'); 
img = im2double(img);

[rows, cols, ch] = size(img);

% Create coordinate grid
[x, y] = meshgrid(1:cols, 1:rows);

% Full 5D features: [x y R G B]
features_all = [x(:), y(:), reshape(img, [], 3)];
N_all = size(features_all, 1);

% -----------------------------------------------------------
% 2. Subsample for Mean Shift to make it fast
% -----------------------------------------------------------
N_sample = 3000;                         % try 1000–5000
N_sample = min(N_sample, N_all);
rng(0);                                  % reproducible
idx = randperm(N_all, N_sample);
features = features_all(idx, :);         % sampled 5D data
N = size(features, 1);

% -----------------------------------------------------------
% 3. Mean Shift Parameters
% -----------------------------------------------------------
hs = 10;        % spatial bandwidth (pixels)
hr = 0.10;      % color bandwidth (RGB distance)
max_iters = 10; % fewer iters for speed
epsilon = 1e-3; % convergence threshold

% Start modes at initial feature locations
modes = features;

fprintf("Running 5D Mean Shift Segmentation on %d sampled pixels...\n", N);

% -----------------------------------------------------------
% 4. Mean Shift Iterations (on sampled points)
% -----------------------------------------------------------
for iter = 1:max_iters
    fprintf("Iteration %d/%d\n", iter, max_iters);

    for i = 1:N
        cur_point = modes(i, :);  % [x y R G B]

        % Spatial distance
        spatial_dist = sqrt( ...
            (features(:,1) - cur_point(1)).^2 + ...
            (features(:,2) - cur_point(2)).^2 );

        % Color distance
        color_dist = sqrt(sum( (features(:,3:5) - cur_point(3:5)).^2, 2 ));

        % Neighborhood in both spatial + color space
        mask = (spatial_dist < hs) & (color_dist < hr);
        neighbors = features(mask, :);

        if ~isempty(neighbors)
            new_point = mean(neighbors, 1);
        else
            new_point = cur_point;
        end

        shift = norm(new_point - cur_point);
        modes(i,:) = new_point;

        if shift < epsilon
            continue;
        end
    end
end

% -----------------------------------------------------------
% 5. Cluster sampled modes (merge nearby modes)
%    We merge based on COLOR ONLY to avoid scale issues
% -----------------------------------------------------------
fprintf("Clustering modes...\n");

cluster_labels_sample = zeros(N,1);
cluster_count = 0;

% store full 5D mode of each cluster
modes_final = zeros(N, 5);  

color_merge_thr = 0.05;   % how close in RGB to be same cluster

for i = 1:N
    assigned = false;

    for j = 1:cluster_count
        % Compare only RGB (columns 3:5)
        if norm(modes(i,3:5) - modes_final(j,3:5)) < color_merge_thr
            cluster_labels_sample(i) = j;
            assigned = true;
            break;
        end
    end

    if ~assigned
        cluster_count = cluster_count + 1;
        modes_final(cluster_count,:) = modes(i,:);   % full 5D mode
        cluster_labels_sample(i) = cluster_count;
    end
end

modes_final = modes_final(1:cluster_count, :);
fprintf("Total clusters found (on samples): %d\n", cluster_count);

% -----------------------------------------------------------
% 6. Assign ALL pixels to nearest color mode (fast)
% -----------------------------------------------------------
fprintf("Assigning all pixels to nearest mode color...\n");

pixels_rgb_all = features_all(:,3:5);   % N_all x 3 (R,G,B)
cluster_labels_all = zeros(N_all,1);
best_dist = inf(N_all,1);

for k = 1:cluster_count
    mode_rgb = modes_final(k, 3:5);                % 1 x 3
    diff = pixels_rgb_all - mode_rgb;              % N_all x 3
    dist_k = sum(diff.^2, 2);                      % N_all x 1 (squared)
    
    mask = dist_k < best_dist;
    cluster_labels_all(mask) = k;
    best_dist(mask) = dist_k(mask);
end

% -----------------------------------------------------------
% 7. Build segmented image using mode colors
% -----------------------------------------------------------
seg_img = modes_final(cluster_labels_all, 3:5);    % use RGB of modes
seg_img = reshape(seg_img, rows, cols, 3);

% -----------------------------------------------------------
% 8. Display Original and Segmented Images
% -----------------------------------------------------------
figure;
subplot(1,2,1);
imshow(img);
title('Original Image');

subplot(1,2,2);
imshow(seg_img);
title('Mean Shift Segmented Image (5D, Fast)');
