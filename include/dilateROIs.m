function [rois,halos] = dilateROIs(x,y,varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

roi_radius = 7;
watershed_width = 4;
halo_width = 7;
dims = [512 512];
do_plot = 0;
for v = 1:numel(varargin)
    if strcmpi(varargin{v},'roi_radius')
        roi_radius = varargin{v+1};
    elseif strcmpi(varargin{v},'watershed_width')
        watershed_width = varargin{v+1};
    elseif strcmpi(varargin{v},'halo_width')
        halo_width = varargin{v+1};
    elseif strcmpi(varargin{v},'dims')
        dims = varargin{v+1};
    elseif strcmpi(varargin{v},'plot')
        do_plot = varargin{v+1};
    end
end

centroid_img = zeros(dims(1),dims(2));
[img_col, img_row] = meshgrid(1:size(centroid_img, 1), 1:size(centroid_img, 2));
num_rois = numel(y);

blank_im = 0 * centroid_img;
roi_masks = zeros(size(centroid_img,1),size(centroid_img,2),num_rois);
watershed_masks = roi_masks;
halos_masks = roi_masks;
for j = 1:num_rois
    temp = blank_im;
    temp((img_row - y(j)).^2 + (img_col - x(j)).^2 <= roi_radius.^2) = 1;
    roi_masks(:,:,j) = temp;
    
    temp = blank_im;
    temp((img_row - y(j)).^2 + (img_col - x(j)).^2 <= (roi_radius+watershed_width).^2) = 1;
    watershed_masks(:,:,j) = temp;
    
    temp = blank_im;
    temp((img_row - y(j)).^2 + (img_col - x(j)).^2 <= (roi_radius+watershed_width+halo_width).^2) = 1;
    halos_masks(:,:,j) = temp;
end

all_masks = sum(roi_masks,3);
all_watersheds = sum(watershed_masks,3);

[halo_overlap_y,halo_overlap_x] = find((all_masks + all_watersheds) > 0);
[mask_overlap_y,mask_overlap_x] = find(sum(roi_masks,3) > 1);
rois = cell(num_rois,1);
halos = rois;
for m = 1:num_rois
    roi_masks(sub2ind(size(roi_masks),mask_overlap_y,mask_overlap_x,m*ones(numel(mask_overlap_y),1))) = 0;
    rois{m} = find(roi_masks(:,:,m) > 0);
    halos_masks(sub2ind(size(roi_masks),halo_overlap_y,halo_overlap_x,m*ones(numel(halo_overlap_y),1))) = 0;
    halos{m} = find(halos_masks(:,:,m) > 0);
end

if do_plot
    figure('Color',[1 1 1])
    imshow(sum(roi_masks,3) + sum(halos_masks,3))
    axis square
    box off
end
