function [offset_points, zo_position] = ZOBlockAvoider(points)
% quick demo to find where to put the zo block
% lr, hausser lab 2017
% points = n*2 (xy)

do_plot = false;

% define zo block size in pixles (calibrated by imaging with a camera a grid of slm spots centred around the zero order)
yaml = ReadYaml('settings.yml');
zo_block_size_px = yaml.ZeroOrderBlockSize_PX;
slm_size = [yaml.SLM_Pixels_X yaml.SLM_Pixels_Y];

% make a binary image of spot locations
img = zeros(slm_size);
num_points = size(points,1);
for i = 1:num_points
    x = round(points(i,1));
    y = round(points(i,2));
    img(y, x) = img(y, x) + 1;  % +1 in case multiple same xy coords (eg with multiple z planes)
end

% make an image showing distance from nearest spot
nearest_dist_img = bwdist(img);
thresh_nearest_dist_img = nearest_dist_img > zo_block_size_px;
within_reach = conv2(img, ones(slm_size), 'same') == num_points;

% calculate centroid of slm spots, find the region to put the zo order (in a region that is greater than zo-size away from spots, but is the minimum possible distance from the pattern centroid for efficiency)
centroid = mean(points,1);
[good_positions_y, good_positions_x] = find(thresh_nearest_dist_img & within_reach);
good_positions = [good_positions_x good_positions_y];
distances = pairwiseDistance(good_positions, centroid);
[~, best_position] = min(distances);
zo_position = good_positions(best_position,:);

offset_points = points - zo_position + (slm_size/2);

if do_plot
    % make an image showing the distance from slm pattern centroid
    centroid_dist_img = inf(slm_size);
    centroid_dist_img(sub2ind(slm_size, good_positions_y, good_positions_x)) = distances;

    % plots
    figure
    subplot(1,5,1)
    imagesc(img)
    hold on
    scatter(points(:,1), points(:,2), 'wo')
    axis image; axis off
    title('SLM spots')

    subplot(1,5,2)
    imagesc(nearest_dist_img)
    axis image; axis off
    title('Distance from nearest SLM spot')

    subplot(1,5,3)
    imagesc(within_reach)
    axis image; axis off
    title('All spots within range')
    
    subplot(1,5,4)
    imagesc(thresh_nearest_dist_img & within_reach)
    axis image; axis off
    title('Good ZO positions')

    subplot(1,5,5)
    imagesc(centroid_dist_img)
    axis image; axis off
    hold on
    plot(zo_position(1), zo_position(2), 'r*')
    plot(zo_position(1), zo_position(2), 'ro')
    title('Best ZO position')
end
