function distances = pairwiseDistance(xy1, xy2)
% calculate pairwise distances between all coordinates in xy1 and those in xy2
% xy1 and xy2 do not need to be the same size

% calculate pairwise distances of all points
distances = sqrt(bsxfun(@minus,xy1(:,1),xy2(:,1)').^2 + bsxfun(@minus,xy1(:,2),xy2(:,2)').^2);
