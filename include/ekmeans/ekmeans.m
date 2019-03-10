function [assignments,centroids,varargout] = ekmeans(data,num_clusters,num_iterations,equal)

% (c) Henry Dalgleish 2016, Pierre David Belanger
%
% Java ekmeans alorithm by Pierre David Belanger:
% https://github.com/pierredavidbelanger/ekmeans
%
% Ported to MATLAB and modified by Henry Dalgleish:
% https://github.com/hwpdalgleish/ekmeans
%
% --------------------------- ekmeans algorithm ---------------------------
%
% Equal kmeans algorithm that allows an equal cardinality constraint across
% all clusters (i.e. all clusters have the same number of points).
%
% Random centroids are seeded in the data and data points are assigned to
% these centroids on the basis of their euclidian distance. Assignments and
% centroid positions are iteratively updated. If equal cardinality is
% specified, whenever a cluster becomes too large points in that cluster
% that are closest to any other centroid are removed and reassigned to
% their next closest centroid and all clusters/centroids updated.
%
% -------------------------------- Inputs ---------------------------------
%
% - data:           Matrix where columns are dimensions and rows are data
%                   points specified in the order [y x etc.]
%
% - num_clusters:   Scalar, number of clusters to split data into
%
% - num_iterations: Scalar, number of algorithm iterations
%
% - equal:          Boolean, equal cardinality (1) or not (0)
%
% -------------------------------- Outputs --------------------------------
%
% - assignments:    Num_points * 1 vector where each element is the cluster
%                   assignment of the indexed data point
%
% - centroids:      Num_clusters * num_dimensions matrix where each row is
%                   the mean n-dimensional co-ordinates of the data points
%                   in that cluster
%
% --------------------------- Optional outputs ----------------------------
%
% - counts:         Num_clusters * 1 vector where each element is the
%                   number of data points in that cluster
%
% - mean_error:     Scalar, mean distance from all points to their
%                   centroids
%
% - max_error:      Scalar, maximum distance between any one point and its
%                   centroid
%
% -------------------------------------------------------------------------

%% Initialise and run algorithm

num_points = size(data,1);
num_vars = size(data,2);
assignments = -ones(num_points,1);
changed = ones(num_clusters,1);
counts = zeros(num_clusters,1);
points = data;
distances = zeros(num_clusters,num_points);
max_cent = floor(max(data,[],1));
min_cent = ceil(min(data,[],1));
centroids = zeros(num_clusters,num_vars);
for v = 1:num_vars
    centroids(:,v) = randi([min_cent(v) max_cent(v)],num_clusters,1);
end
idealCount = num_points / num_clusters;
done = zeros(num_clusters,1);
numinclusts = zeros(num_clusters,1);
divisible = 1;
not_equal_yet = 1;

if mod(idealCount,1) ~= 0
   idealCount = ceil(idealCount);
   divisible = 0;
   sprintf(['\n******************** Warning ********************'...
            '\nNumber of data-points does not split into integer'...
            '\nnumber of clusters with your chosen cluster size.'...
            '\nCardinality will close to specified size' ...
            '\n*************************************************'])
end

run();

if nargout == 3
    varargout{1} = counts;
elseif nargout == 4
    varargout{1} = counts;
    varargout{2} = mean_err;
elseif nargout == 5
    varargout{1} = counts;
    varargout{2} = mean_err;
    varargout{3} = max_err;
end
%% Sub-functions

    function run()
        calculateDistances(); % calculate distances between all points and all centroids
        move = makeAssignments(); % assign points to centroids 
        i = 0; % initialise loop
        if equal
            while move > 0 && i <= num_iterations %% && not_equal_yet % continue running until iteration limit reached and no more shuffling occurs
                if ~isempty(find(counts==0)) % if there are any empty centroids
                    move = fillEmptyCentroids(); % fill them
                end
                moveCentroids(); % re-calculate centroid positions on basis of clusters
                calculateDistances(); % re-calculate distances between all points and all centroids
                move = move + makeAssignments(); % re-assign points to clusters
                for j = 1:num_clusters
                    numinclusts(j) = numel(find(assignments==j)); % find the number of points in each cluster
                end
                not_equal_yet = ~(sum(double(numinclusts == idealCount)) == num_clusters);
                i = i+1; % increment loop
                % if iteration limit is reached but equal cardinality has not
                % been reached, reinitialise and run again (unless equal
                % cardinality is impossible)
                if i >= num_iterations && not_equal_yet && divisible
                    assignments = -ones(num_points,1);
                    changed = ones(num_clusters,1);
                    counts = zeros(num_clusters,1);
                    centroids = zeros(num_clusters,num_vars);
                    distances = zeros(num_clusters,num_points);
                    numinclusts = zeros(num_clusters,1);
                    done = zeros(num_clusters,1);
                    not_equal_yet = 1;
                    centroids = zeros(num_clusters,num_vars);
                    for v = 1:num_vars
                        centroids(:,v) = randi([min_cent(v) max_cent(v)],num_clusters,1);
                    end
                    calculateDistances(); % calculate distances between all points and all centroids
                    move = makeAssignments(); % assign points to centroids
                    i = 0; % reinitialise iteration
                end
            end
        elseif ~equal
            while move > 0 && i < num_iterations % continue running until iteration limit reached and no more shuffling occurs
                if ~isempty(find(counts==0)) % if there are any empty centroids
                    move = fillEmptyCentroids(); % fill them
                end
                moveCentroids(); % re-calculate centroid positions on basis of clusters
                calculateDistances(); % re-calculate distances between all points and all centroids
                move = move + makeAssignments(); % re-assign points to clusters
                for j = 1:num_clusters
                    numinclusts(j) = numel(find(assignments==j)); % find the number of points in each cluster
                end
                i = i+1; % increment loop            
            end
        end
        calculateError();
    end

    function calculateDistances()
        for c = 1:size(centroids,1) % for each centroid
            if ~changed(c) % if it hasn't changed, do nothing
            else
                centroid = centroids(c,:);
                for p = 1:length(points) % for each point
                    point = points(p,:);
                    s = 0;
                    for d = 1:length(centroid)
                        s = s + (abs(centroid(d) - point(d)))^2; 
                    end
                    distances(c,p) = sqrt(s); % calculate Euclidean distance between each point and each centroid
                end
            end
        end
        changed = 0 * changed; % re-initialise change binary
    end

    function move = makeAssignments()
        move = 0;
        counts = 0 * counts; % num points in cluster
        for p = 1:length(points)
            nc = nearestCentroid(p);
            if (nc == -1) % if a nearby centroid doesn't exist, do nothing (SAFETY CHECK)
            else % if nearby centroid does exist
                if (assignments(p) ~= nc) % if assignment doesn't match nearest centroid
                    if (assignments(p) ~= -1) % if this point has previously been assigned a cluster
                        changed(assignments(p)) = 1; % previous cluster has changed
                        %counts(assignments(p)) = counts(assignments(p))-1;
                    end
                    changed(nc) = 1; % new cluster has changed
                    assignments(p) = nc; % change point assignment to nearest centroid
                    move = move + 1; % increment the number of moves
                end
                counts(nc) = counts(nc)+1; % increment number of points in this cluster
                if (equal && counts(nc) > idealCount) % if this is too larget
                    move = move + remakeAssignments(nc); % reassign points and increment the number of moves
                end
            end
        end
    end

    function nc = nearestCentroid(p) % for a point p
        md = inf;
        nc = -1;
        for c = 1:size(centroids,1) % find it's closest centroid
            d = distances(c,p);
            if (d < md)
                md = d;
                nc = c;
            end
        end
    end

    function move = remakeAssignments(cc)
        move = 0;
        md = inf;
        nc = -1;
        np = -1;
        % This loop finds a point in the offending cluster that is closest
        % to any other centroid
        for p = 1:length(points) % for each point
            if (assignments(p) ~= cc) % if point isn't in the offending centroid then do nothing
            else % if it is in the offending centroid
                for c = 1:size(centroids,1) % for each centroid
                    if (c == cc || done(c)) % if the centroid is the offending centroid then ignore it
                    else
                        d = distances(c,p); % find the point that is closest to any other centroid
                        if (d < md)
                            md = d;
                            nc = c; % centroid to which a point in offending cluster is closest to
                            np = p; % point in offending cluster that is closest to any other centroid
                        end
                    end
                end
            end
        end
        if (nc ~= -1 && np ~= -1) % assuming the nearest centroid/point combination was assigned above
            if (assignments(np) ~= nc) % if the point is not assigned to the next closest cluster
                if (assignments(np) ~= -1) % if it has been assigned to a cluster
                    changed(assignments(np)) = 1; % mark its previously assigned centroid as changed
                end
                changed(nc) = 1; % mark next closest centroid as changed
                assignments(np) = nc; % assign this point to the next closest cluster
                move = move + 1; % increment the number of moves
            end
            counts(cc) = counts(cc)-1; % decrement points in offending cluster
            counts(nc) = counts(nc)+1; % increment points in next closest cluster
            if (counts(nc) > idealCount) % if number of points in offending cluster is still too large
                done(cc) = 1;
                move = move + remakeAssignments(nc); % iteratively remake assignments
                done(cc) = 0;
            end
        end
    end

    function move = fillEmptyCentroids()
        move = 0;
        for c = 1:size(centroids,1) % for each centroid
            if (counts(c) == 0) % if centroid is empty
                lc = largestCentroid(c); % find the largest centroid 
                np = nearestPoint(lc, c); % find the nearest point in that largest centroid to the empty centroid
                assignments(np) = c; % assign the nearest point to the empty centroid
                counts(c) = counts(c)+1; % increment the number of points in empty cluster
                counts(lc) = counts(lc)-1; % decrement the number of points in largest cluster
                changed(c) = 1; % mark empty centroid as changed
                changed(lc) = 1; % mark largest centroid as changed
                move = move + 1; % increment the number of moves
            end
        end
    end

    function lc = largestCentroid(except) 
        lc = -1;
        mc = 0;
        for c = 1:size(centroids,1) % for all centroids except input argument
            if (c == except)
            elseif (counts(c) > mc) % find the largest centroid
                lc = c;
                mc = counts(c);
            end
        end

    end

    function np = nearestPoint(inc,fromc)
        md = inf;
        np = -1;
        for p = 1:length(points)
            if (assignments(p) ~= inc) % if point isn't in the centroid specified "inc", do nothing
            else
                d = distances(fromc,p); % if it is;
                if (d < md) % find the point closest to centroid "fromc"
                    md = d;
                    np = p;
                end
            end
        end
    end

    function moveCentroids() %moveCentroids(changed,assignments,centroids,points)
        for c = 1:size(centroids,1) % for each centroid
            if (~changed(c)) % if nothing changed with this centroid, do nothing
            else
                centroids(c,:) = mean(points((assignments==c),:),1);
            end
        end
    end

    function calculateError()
        mean_err = zeros(size(centroids,1),1);
        max_err = zeros(size(centroids,1),1);
        for c = 1:size(centroids,1)
            mean_err(c) = mean(distances(c,assignments==c));
            max_err(c) = max(distances(c,assignments==c));
        end
        mean_err = mean(mean_err);
        max_err = max(max_err);
    end

end

