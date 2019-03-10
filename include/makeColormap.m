function cmap = makeColormap(colors, n)
% LR 2017. Based on lbmap.m
%
% Inputs:
% colors = x-by-3 array of colors (0 to 1 range)
% n = number of elements final LUT will have
%
% Usage:
% cmap = makeColormap([0 0 1; 1 1 1; 1 0 0], 255);  % for a Blue-White-Red cmap with 255 elements
% colormap(cmap)  % set the colormap for current figure
% caxis(max(abs(caxis)) * [-1 1]);  % set colormap limits (equal +/- extents)


idx1 = linspace(0, 1, size(colors,1));
idx2 = linspace(0, 1, n);
cmap = interp1(idx1, colors, idx2);
