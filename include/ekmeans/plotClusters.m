function [] = plotClusters(data,assignments,centroids,dimensions,connect)

% (c) Henry Dalgleish 2016
%
% ----------------------------- plot Clusters -----------------------------
%
%
% Take clustered data (either in 2 or 3 dimensions) and plot points
% connected to the centroid of their assigned cluster with arbitrary graded
% colourscheme to aid visualisation.
%
% For use with ekmeansGUI.
%
%
% N.B. Direction of y-axis is reversed in these plots to mimic the effect
% of data points being stored as 1's in an n-dimensional matrix of 0's
% (i.e. finding elements in this matrix will return row indices calculated
% from top to bottom, as opposed to bottom to top as is normally plotted in
% scatter plots).
%
% --------------------------------- Inputs --------------------------------
%
% Data:         num_datapoints * num_dimensions matrix containing clustered
%               data
%
% Assignments:  num_datapoints * 1 vector where each element is the cluster
%               assignment of the corresponding data-point in Data
%
% Centroids:    num_clusters * num_dimensions matrix where each row is the
%               centroid co-ordinate for clusters to which points are
%               assigned in Assigments (defined as the mean of all points
%               in each cluster)
%
% Dimensions:   1 * num_dimensions vector where each element is the extent
%               of the
%
% Connect:      binary, connect (1) or don't connect (0) the points to
%               their centroid
%
% -------------------------------------------------------------------------
%%

num_vars = size(data,2);

num_points = size(data,1);

num_clusts = size(centroids,1);

if num_vars == 3 && numel(unique(data(:,3))) == 1
    
    data = data(:,1:2);
    
    num_vars = 2;
    
    dimensions = dimensions(:,1:2);
    
end

if size(dimensions,2) ~= num_vars
    
    error(sprintf(['\n********************* Error *********************'...
                   '\nDimensions specified do not match number of data'...
                   '\n                    variables'...
                   '\n*************************************************']))
    
elseif size(dimensions,1) ~= 2
    
    error(sprintf(['\n********************* Error *********************'...
                   '\nMin and max dimensions for each variable not set '...
                   '\n*************************************************']))
    
end

if num_vars == 2
    
    if connect
        
        colors = [0 0 0;0.2 0.2 0.2;0.4 0.4 0.4;0.6 0.6 0.6];
        
        colors = repmat(colors,ceil(num_clusts/size(colors,1)),1);
        
        colors = colors(1:num_clusts,:);
        
        scatter(data(:,2),data(:,1),'.','k')
        
        ylim([dimensions(1,1) dimensions(2,1)])
        
        xlim([dimensions(1,2) dimensions(2,2)])
        
        axis off
    
        hold on
        
        for p = 1:num_points
            
            line([data(p,2) centroids(assignments(p),2)],[data(p,1) centroids(assignments(p),1)],...
                'Color',colors(assignments(p),:))
            
        end
        
    else
        
        scatter(data(:,2),data(:,1),'.','k')
        
        ylim([dimensions(1,1) dimensions(2,1)])
        
        xlim([dimensions(1,2) dimensions(2,2)])
        
        axis off
    
    end
    
    set(gca,'Ydir','reverse')
    
elseif num_vars == 3
    
    hold on

    if connect
        
        cmap = jet(num_clusts);
        
        for clust = 1:num_clusts
        
            scatter3(data(assignments == clust,2),data(assignments == clust,1),data(assignments == clust,3),25,cmap(clust,:),'fill')
        
            scatter3(centroids(clust,2),centroids(clust,1),centroids(clust,3),50,cmap(clust,:),'fill')
        
        end
    
        for p = 1:num_points
            
            line([data(p,2) centroids(assignments(p),2)], ...
                [data(p,1) centroids(assignments(p),1)], ...
                [data(p,3) centroids(assignments(p),3)], ...
                'Color',cmap(assignments(p),:))
        end
        
    else
        
        scatter3(data(:,2),data(:,1),data(:,3),25,'k','fill')
    
    end
    
    grid on
    
    set(gca,'Ydir','reverse')
    
    xlabel('X')
    
    ylabel('Y')
    
    zlabel('Z')
    
    ylim([dimensions(1,1) dimensions(2,1)])
        
    xlim([dimensions(1,2) dimensions(2,2)])
    
    zlim([dimensions(1,3) dimensions(2,3)])
    
elseif num_vars > 3
    
    error(sprintf(['\n********************* Error *********************'...
                   '\nplotClusters can only plot in maximum 3 dimensions'...
                   '\nYou have specified ' num2str(num_vars) ' dimensions'...
                   '\n*************************************************'])) 
               
               
end


end

