img_path = '/Users/lloyd/Desktop/20171009_L431_s-026_Cycle00001_Ch1_000001.ome.tif';
img = double(imread(img_path));
img = img ./ max(max(img));

img = medfilt2(img,[3,3]);
se = strel('disk',3);
img = imtophat(img, se);
img = histeq(img);
img = imadjust(img);

% img = imgaussfilt(img,1);
img = imtophat(img, se);
% img(img< graythresh(img)*1.2) = 0;
% img = imadjust(img);

img = imbinarize(img, graythresh(img)*2);
% img = imfill(~img, 8, 'holes');
% figure
% imshow(img)

LB = 600;
bigObjects = bwareaopen(~img, LB);
img = double(img);
img(bigObjects) = 1;
img = ~img;
figure, imshow(img);

    [centers, radii, metric] = imfindcircles(img,[4 6], 'ObjectPolarity','dark','Sensitivity',0.99,'EdgeThreshold',0.2, 'Method','twostage');
% viscircles(centers, radii,'EdgeColor','r');

%%

% % img = imdilate(img,se);
% figure
% subplot(2,3,1)
% imshow(img)
% 
% % se = strel('disk',1);
% % original = imdilate(img,se);
% original = ~img;
% filled = imfill(original, 'holes');
% subplot(2,3,2)
% imshow(filled)
% 
% holes = filled & ~original;
% subplot(2,3,3)
% imshow(holes)
% 
% bigholes = bwareaopen(holes, 30);
% subplot(2,3,4)
% imshow(bigholes)
% 
% smallholes = holes & ~bigholes;
% subplot(2,3,5)
% imshow(smallholes)
% 
% new = ~original | smallholes;
% subplot(2,3,6)
% imshow(new)

[centers, radii, metric] = imfindcircles(img,[1 10]);
viscircles(centers, radii,'EdgeColor','r');