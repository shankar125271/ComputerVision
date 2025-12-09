% eight_point_auto.m
% Robust demo of the normalized 8-point algorithm.
% If image1.jpg and image2.jpg exist, it will use them and ask for points.
% Otherwise it generates synthetic images and synthetic matching points.

clear; close all; clc;

% ---------------- Config ----------------
useInteractiveIfImagesExist = true; % if images found, let user pick pts; set false to skip
minPts = 8;

% ------------------ Load or create images ------------------
if exist('image1.jpg','file') && exist('image2.jpg','file')
    I1 = imread('image1.jpg');
    I2 = imread('image2.jpg');
    haveImages = true;
else
    % Create synthetic placeholder images (gray) and mark size
    w = 600; h = 400;
    I1 = uint8(200 * ones(h,w,3));   % light gray
    I2 = uint8(220 * ones(h,w,3));   % slightly different gray
    haveImages = false;
end

% ------------------ Get or create corresponding points ------------------
if haveImages && useInteractiveIfImagesExist
    figure('Name','Image 1'); imshow(I1); title('Select >=8 points in Image 1 then press Enter');
    [x1,y1] = getpts;
    close;
    figure('Name','Image 2'); imshow(I2); title('Select corresponding points in Image 2 then press Enter');
    [x2,y2] = getpts;
    close;
    if numel(x1) ~= numel(x2) || numel(y1) ~= numel(y2) || numel(x1) < minPts
        warning('Interactive selection failed or insufficient points. Switching to synthetic points.');
        havePoints = false;
    else
        P1 = [x1(:) y1(:)];
        P2 = [x2(:) y2(:)];
        havePoints = true;
    end
else
    havePoints = false;
end

if ~havePoints
    % Generate synthetic corresponding points using a random homography + noise
    rng(1); % reproducible
    N = 12; % number of synthetic correspondences (>=8)
    if size(I1,1) >= 2
        hI = size(I1,1); wI = size(I1,2);
    else
        hI = 400; wI = 600;
    end
    % random points in image1
    margin = 40;
    x = margin + (wI-2*margin) * rand(N,1);
    y = margin + (hI-2*margin) * rand(N,1);
    P1 = [x y];
    % build a random homography H (slight projective transform)
    theta = 0.05*randn; tx = 20*randn; ty = 10*randn;
    S = [1+0.05*randn 0; 0 1+0.05*randn];
    R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
    A = R * S;
    H_affine = [A [tx;ty]; 0 0 1];
    % apply H and add small noise
    P1_h = [P1 ones(N,1)]';
    P2_h = H_affine * P1_h;
    P2 = (P2_h(1:2,:)./P2_h(3,:))' + 1.5 * randn(N,2); % small noise
    % display we used synthetic points
    disp('Using synthetic correspondences (auto-generated).');
end

% Ensure at least 8 points
if size(P1,1) < minPts
    error('Insufficient points (%d). Need at least %d correspondences.', size(P1,1), minPts);
end

% ------------------ Normalized 8-point algorithm ------------------
[T1, P1n] = normalizePoints(P1);
[T2, P2n] = normalizePoints(P2);

Npts = size(P1n,1);
A = zeros(Npts,9);
for i = 1:Npts
    x1n = P1n(i,1); y1n = P1n(i,2);
    x2n = P2n(i,1); y2n = P2n(i,2);
    A(i,:) = [x2n*x1n, x2n*y1n, x2n, ...
              y2n*x1n, y2n*y1n, y2n, ...
              x1n,      y1n,      1];
end

[~,~,V] = svd(A);
f = V(:,end);
F_norm = reshape(f,3,3)';

% enforce rank-2
[U,S,Vv] = svd(F_norm);
S(3,3) = 0;
F_norm_rank2 = U * S * Vv';

% denormalize
F = T2' * F_norm_rank2 * T1;

% scale for readability
F = F / norm(F);

disp('Estimated Fundamental Matrix (scaled):');
disp(F);

% ------------------ Visualize epipolar lines ------------------
figure('Name','Epipolar Visualization','Units','normalized','Position',[0.1 0.1 0.8 0.6]);
subplot(1,2,1); imshow(I1); hold on; title('Image 1  (epipolar lines from pts in Image 2)');
subplot(1,2,2); imshow(I2); hold on; title('Image 2  (epipolar lines from pts in Image 1)');

[h1,w1,~] = size(I1);
[h2,w2,~] = size(I2);

% plot epilines in image1 for each P2 (use F' * p2)
for i = 1:size(P2,1)
    p2 = [P2(i,:) 1]';
    l1 = F' * p2;
    subplot(1,2,1);
    plotEpipolarLine(l1, w1, h1);
    plot(P1(i,1), P1(i,2), 'ro', 'MarkerSize',6, 'LineWidth',1);
end

% plot epilines in image2 for each P1 (use F * p1)
for i = 1:size(P1,1)
    p1 = [P1(i,:) 1]';
    l2 = F * p1;
    subplot(1,2,2);
    plotEpipolarLine(l2, w2, h2);
    plot(P2(i,1), P2(i,2), 'go', 'MarkerSize',6, 'LineWidth',1);
end

% annotate number of correspondences
subplot(1,2,1); text(10,20, sprintf('N = %d', size(P1,1)), 'Color','yellow','FontSize',12,'FontWeight','bold');
subplot(1,2,2); text(10,20, sprintf('N = %d', size(P1,1)), 'Color','yellow','FontSize',12,'FontWeight','bold');

% ------------------ Helper functions ------------------
function [T, Pn] = normalizePoints(P)
    % Robust Hartley normalization for Nx2 points
    P = double(P);
    centroid = mean(P,1);
    P_shift = P - centroid;
    d = sqrt(sum(P_shift.^2,2));
    meanDist = mean(d);
    if meanDist < eps
        s = 1;
    else
        s = sqrt(2)/meanDist;
    end
    T = [s 0 -s*centroid(1); 0 s -s*centroid(2); 0 0 1];
    P_h = [P ones(size(P,1),1)]';
    Pn_h = T * P_h;
    Pn = (Pn_h(1:2,:)./Pn_h(3,:))';
end

function plotEpipolarLine(l, imgWidth, imgHeight)
    a = l(1); b = l(2); c = l(3);
    pts = [];
    tol = 1e-6;
    if abs(b) > tol
        y1 = -(a*1 + c)/b; pts = [pts; 1, y1];
        y2 = -(a*imgWidth + c)/b; pts = [pts; imgWidth, y2];
    end
    if abs(a) > tol
        x1 = -(b*1 + c)/a; pts = [pts; x1, 1];
        x2 = -(b*imgHeight + c)/a; pts = [pts; x2, imgHeight];
    end
    % keep valid
    valid = pts(:,1) >= -1 & pts(:,1) <= imgWidth+1 & pts(:,2) >= -1 & pts(:,2) <= imgHeight+1;
    pts = pts(valid,:);
    if size(pts,1) < 2
        return;
    end
    pts = unique(round(pts,6),'rows','stable');
    if size(pts,1) >= 2
        p1 = pts(1,:); p2 = pts(2,:);
        plot([p1(1) p2(1)], [p1(2) p2(2)], 'y-', 'LineWidth',1.2);
    end
end
