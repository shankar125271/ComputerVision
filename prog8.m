% Interactive 3D random points viewer (10–15 points) - corrected

% ---------- Parameters ----------
N = randi([10 15]);      % random number of points between 10 and 15
rangeX = [-10, 10];
rangeY = [-8, 8];
rangeZ = [-5, 15];
pointSize = 80;          % marker size

% ---------- Generate points ----------
x = rangeX(1) + (rangeX(2)-rangeX(1)) * rand(N,1);
y = rangeY(1) + (rangeY(2)-rangeY(1)) * rand(N,1);
z = rangeZ(1) + (rangeZ(2)-rangeZ(1)) * rand(N,1);

% color by height (z)
c = z;

% ---------- Plot ----------
hFig = figure('Name','Interactive 3D Point Cloud','NumberTitle','off');
hAx = axes('Parent',hFig);

% Draw points
hScatter = scatter3(hAx, x, y, z, pointSize, c, 'filled', 'MarkerEdgeColor','none');

% Labels and title
xlabel(hAx,'X'); ylabel(hAx,'Y'); zlabel(hAx,'Z');
title(hAx, ['Random 3D Points (interactive) — N = ' num2str(N)]);

% Appearance
axis(hAx,'equal');
grid(hAx,'on');
box(hAx,'on');
colormap('parula');

% Proper colorbar labeling (compatible across MATLAB versions)
cb = colorbar(hAx);
if isprop(cb, 'Label') && isprop(cb.Label, 'String')
    cb.Label.String = 'Z value';
else
    % older fallback: set the Title of the colorbar axis (rare)
    title(cb, 'Z value');
end

% Improve rotation/interaction behavior
axis(hAx,'vis3d');
view(hAx, 3);
set(hFig, 'Renderer','opengl');

% Enable built-in interactive tools
rotate3d(hAx,'on');    % left-click drag to rotate
zoom(hFig,'on');       % mouse wheel / toolbar zoom
pan(hFig,'on');        % right-click drag to pan

% Show camera toolbar in orbit mode
try
    cameratoolbar(hFig,'Show');
    cameratoolbar(hFig,'SetMode','orbit');
catch
    % silently continue if cameratoolbar is unsupported in very old MATLAB
end
