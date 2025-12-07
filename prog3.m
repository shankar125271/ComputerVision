% ---- GEOMETRIC TRANSFORMATIONS DEMO ----

% 1. Read an in-built image
img = imread('cameraman.tif');   % grayscale test image

figure;
subplot(2,3,1);
imshow(img); title('Original Image');

% 2. Translation (shift image)
tform_translate = affine2d([1 0 0; 0 1 0; 50 30 1]); % shift by (50,30)
translated = imwarp(img, tform_translate);
subplot(2,3,2);
imshow(translated); title('Translation (50,30)');

% 3. Rotation
tform_rotate = affine2d([cosd(30) sind(30) 0; -sind(30) cosd(30) 0; 0 0 1]); % 30 deg
rotated = imwarp(img, tform_rotate);
subplot(2,3,3);
imshow(rotated); title('Rotation (30°)');

% 4. Scaling
tform_scale = affine2d([1.5 0 0; 0 1.5 0; 0 0 1]); % scale by 1.5x
scaled = imwarp(img, tform_scale);
subplot(2,3,4);
imshow(scaled); title('Scaling (1.5x)');

% 5. Affine Transformation
% Shearing example
tform_affine = affine2d([1 0.3 0; 0.2 1 0; 0 0 1]);
affine_img = imwarp(img, tform_affine);
subplot(2,3,5);
imshow(affine_img); title('Affine Transformation');

% 6. Projective Transformation
% Map 4 corners of original to new quadrilateral
input_points  = [0 0; size(img,2) 0; size(img,2) size(img,1); 0 size(img,1)];
output_points = [0 0; size(img,2)-50 50; size(img,2)-30 size(img,1)-20; 30 size(img,1)];
tform_projective = fitgeotrans(input_points, output_points, 'projective');
projective_img = imwarp(img, tform_projective);
subplot(2,3,6);
imshow(projective_img); title('Projective Transformation');