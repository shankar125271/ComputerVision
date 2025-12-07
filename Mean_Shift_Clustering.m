clc; clear; close all;

% --------------------------------------------------------------
% Step 1: Load inbuilt MATLAB color image
% --------------------------------------------------------------
img = imread('peppers.png');      % Make sure peppers.png is on MATLAB path
img = im2double(img);
[rows, cols, ch] = size(img);

% All pixels (for final assignment)
pixels_all = reshape(img, [], 3);     % (N_all x 3)
N_all = size(pixels_all, 1);

% --------------------------------------------------------------
% Step 2: Subsample pixels for Mean Shift (to speed up)
% --------------------------------------------------------------
N_sample = 3000;                         % You can change this (1000–5000)
rng(0);                                  % For reproducibility
idx = randperm(N_all, N_sample);         % Randomly pick sample pixels
pixels = pixels_all(idx, :);             % (N x 3)
N = size(pixels, 1);

% Mean Shift parameters
hs        = 0.1;     % Color bandwidth (smaller = more clusters)
max_iters = 10;      % Reduced for speed
threshold = 1e-3;    % Convergence threshold
merge_thr = 0.02;    % Threshold for merging modes into same cluster

fprintf('Running Mean Shift Clustering on %d sampled pixels...\n', N);

% --------------------------------------------------------------
% Step 3: Mean Shift Mode-Seeking (on sampled pixels only)
% --------------------------------------------------------------
modes = pixels;       % Start each pixel at its own initial location

for iter = 1:max_iters
    fprintf("Iteration %d/%d\n", iter, max_iters);
    
    for i = 1:N
        % Distance from current mode of point i to all sampled pixels
        dist = sqrt(sum((pixels - modes(i,:)).^2, 2));
        
        % Find neighbors within bandwidth
        neighbors = pixels(dist < hs, :);
        
        % Compute mean of neighbors
        if ~isempty(neighbors)
            new_point = mean(neighbors, 1);
        else
            new_point = modes(i,:);
        end
        
        % Shift amount
        shift = norm(new_point - modes(i,:));
        modes(i,:) = new_point;
        
        % If shift is very small, we consider it converged and move on
        if shift < threshold
            continue;
        end
    end
end

% --------------------------------------------------------------
% Step 4: Group sampled points that converge to the same mode
% --------------------------------------------------------------
fprintf("Assigning clusters to sampled pixels based on converged modes...\n");

cluster_labels_sample = zeros(N,1);
cluster_count  = 0;

% Pre-allocate maximum possible modes (worst case: every point its own mode)
modes_final = zeros(N, 3);

for i = 1:N
    assigned = false;
    
    for j = 1:cluster_count
        if norm(modes(i,:) - modes_final(j,:)) < merge_thr
            cluster_labels_sample(i) = j;
            assigned = true;
            break;
        end
    end
    
    if ~assigned
        cluster_count = cluster_count + 1;
        modes_final(cluster_count,:) = modes(i,:);
        cluster_labels_sample(i) = cluster_count;
    end
end

% Trim unused rows
modes_final = modes_final(1:cluster_count, :);
fprintf("Total clusters found (on samples): %d\n", cluster_count);

% --------------------------------------------------------------
% Step 5: Assign EVERY pixel in the image to nearest mode
% --------------------------------------------------------------
fprintf("Assigning all image pixels to nearest cluster center...\n");

cluster_labels_all = zeros(N_all, 1);
best_dist = inf(N_all, 1);

for k = 1:cluster_count
    % Squared distance of all pixels to mode k
    diff = pixels_all - modes_final(k, :);
    dist_k = sum(diff.^2, 2);   % (N_all x 1)
    
    % Update label where this cluster is closer
    mask = dist_k < best_dist;
    cluster_labels_all(mask) = k;
    best_dist(mask) = dist_k(mask);
end

% --------------------------------------------------------------
% Step 6: Reconstruct segmented image (vectorized)
% --------------------------------------------------------------
seg_img = modes_final(cluster_labels_all, :);   % N_all x 3
seg_img = reshape(seg_img, rows, cols, 3);

% --------------------------------------------------------------
% Step 7: Display Results
% --------------------------------------------------------------
figure;
subplot(1,2,1); imshow(img);     title('Original Image');
subplot(1,2,2); imshow(seg_img); title('Mean Shift Segmented Image (Fast)');
