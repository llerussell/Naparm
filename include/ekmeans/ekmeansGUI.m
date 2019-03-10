function [assignments,centroids] = ekmeansGUI(cluster_size,equal,varargin)

% (c) Henry Dalgleish 2016
%
% Java ekmeans alorithm by Pierre David Belanger:
% https://github.com/pierredavidbelanger/ekmeans
%
% Ported to MATLAB and modified by Henry Dalgleish:
% https://github.com/hwpdalgleish/ekmeans
%
% ------------------------------ ekmeans GUI ------------------------------
%
% GUI used to view, evaluate and manually optimise ekmeans clustering of
% input data. Data can only be viewed in a maximum of 3 dimensions (even
% though ekmeans can cluster in arbitrarily high dimensions).
%
% N.B. Direction of y-axis is reversed in these plots to mimic the effect
% of data points being stored as 1's in an n-dimensional matrix of 0's
% (i.e. finding elements in this matrix will return row indices calculated
% from top to bottom, as opposed to bottom to top as is normally plotted in
% scatter plots).
%
% GUI will store up to 10 cluster splits. Initially only the first split is
% clustered. Clustering on a split that precedes an unclustered split will
% result in the current split staying the same and the next split being
% clustered. Clustering on an unclustered split will cluster the split.
% Once all splits have been clustered, re-clustering on a clustered split
% will recluster that split.
%
% --------------------------- Compulsory Inputs ---------------------------
%
% - Cluster size:   Size of clusters to split into
%
% - Equal:          Boolean, sets equal cardinality of clusters (1) or
%                   not (0)
%
% ---------------------------- Optional Inputs ----------------------------
%
% - Nothing:        Opens file selection GUI in which you can select either
%                   a .tif file (with hot pixels indicating data points and
%                   zeros everywhere else), a .csv where columns are
%                   co-ordinates and rows are data points or a .mat file
%                   where the first variable is a matrix where columns are
%                   co-ordinates and rows data points. Columns are in order
%                   [y x etc.]
%
% - Input:          Followed by the input workspace variable. This
%                   can either be a matrix where columns are co-ordinates
%                   ([y x etc.]) and rows data points or an "image" with
%                   hot pixels indicating data points and zeros everywhere
%                   else
%
% - Iterations:     Followed by number of ekmeans algorithm iterations.
%                   Default = 150.
%
% - Dimensions:     Followed by either a 2*n matrix containing containing
%                   the min (1,n) and max (2,n) extents of dimension n, or
%                   a 2*1 vector containing the min and max extents of all
%                   dimensions. Default = [1 ; 150] for all dimensions.
%
% -------------------------------- Outputs --------------------------------
%
% - Assignments:    Num_points * 1 vector where each element is the number
%                   of the cluster to which that indexed point is assigned
%
% - Centroids:      Num_centroids * num_dimensions matrix of where each row
%                   is contains the n-dimensional co-ordinates of each
%                   centroid (defined as mean co-ordinate of all points in
%                   that cluster)
%
% -------------------------------------------------------------------------

%% Parse inputs

num_iters = 150;
assignments = [];
centroids = [];
input = [];
dims = [];
for v = 1:numel(varargin)   
    if strcmpi(varargin{v},'iterations')       
        num_iters = varargin{v+1};        
    elseif strcmpi(varargin{v},'input')        
        input = varargin{v+1};        
    elseif strncmpi(varargin{v},'dim',3)        
        dims = varargin{v+1};       
    end    
end
if isempty(input)    
    [f,d] = uigetfile('*.*');
    if f == 0
       return;
    end
    ext_idcs = strfind(f,'.');    
    ext = f(ext_idcs(end):end);    
    if strncmp(ext,'.tif',4)        
       input = imread([d f]); 
       if isempty(dims)
           dims = size(input);
           dims = [ones(1,numel(dims)) ; dims];
       end
    elseif strncmp(ext,'.csv',4)        
       input = csvread([d f]);       
    elseif strncmp(ext,'.mat',4)        
       mfile = load([d f]);       
       v = fieldnames(mfile);     
       input = mfile.(v{1});
    elseif strncmp(ext,'.txt',4)
       input = dlmread([d f],',');
    end    
end       
if ~isempty(input) && ((numel(find(input==0)) / numel(input)) > 0.7)   
    [data(:,1),data(:,2)] = ind2sub(size(input),find(input>0));
    dims = size(input);
    dims = [ones(1,numel(dims)) ; dims];
elseif ~isempty(input) && ~((numel(find(input==0)) / numel(input)) > 0.7)    
    data = input;    
end

num_points = size(data,1);
num_vars = size(data,2);
if isempty(dims)
    dims = [min(input,[],1) ; max(input,[],1)];
elseif size(dims,2) == 1
    dims = [dims(1) * ones(1,num_vars) ; dims(2) * ones(1,num_vars)];
elseif size(dims,2) ~= 1 && size(dims,2) ~= num_vars
    error(sprintf(['\n********************* Error *********************'...
                   '\nDimensions specified do not match number of data'...
                   '\n                    variables'...
                   '\n*************************************************']))
end

if num_vars > 3
    
    error(sprintf(['\n********************* Error *********************'...
        '\nekMeans GUI can only plot in maximum 3 dimensions'...
        '\n         You have specified ' num2str(num_vars) ' dimensions'...
        '\n*************************************************']))
    
end

%% Run initial clustering

to_remember = 10;
r = 1;
num_clusters = round(num_points / cluster_size);
assignments = zeros(num_points,to_remember);
centroids = zeros(num_clusters,num_vars,to_remember);
max_err = zeros(to_remember,1);
mean_err = zeros(to_remember,1);
[assignments(:,r),centroids(:,:,r),~,mean_err(r),max_err(r)] = ekmeans(data,num_clusters,num_iters,equal);
cents = squeeze(round(centroids(:,:,r)));

%% Create GUI

% Figure
scrsz = get(0,'ScreenSize');

scrHeight = scrsz(4);

scrWidth = scrsz(3);

fig = figure('Position',[0.2*scrWidth 0.2*scrHeight scrHeight*0.6 scrHeight*0.665], 'Color', [1 1 1],'numbertitle','off','name','ekmeans');

% Image
TitlePan = uipanel('Units','normalized','Position',[0 0.95 1 0.05]);
ImPan = uipanel('Units','normalized','Position',[0 0.05 1 0.9]);
ButtPan = uipanel('Units','normalized','Position',[0 0 1 0.05]); 
mainAx = axes('Parent',ImPan, 'Units', 'normalized', 'Position', [0 0.025 1 0.95], 'color', [1 1 1]);
tit = uicontrol('Parent',TitlePan,'Style','text','String',['Split = ' num2str(r) ' of ' num2str(to_remember) ...
            ', max error = ' num2str(round(max_err(r))) ', mean error = ' num2str(round(mean_err(r)))],'Units','normalized','Position',[0 0 1 1],'fontsize',14);
axis tight
axis square
plotClusters(data,assignments(:,r),centroids(:,:,r),dims,1);
rotate3d(mainAx);

% Buttons
Cluster = uicontrol('Parent', ButtPan, 'Units', 'normalized', 'position', [0 0 1/4 1],...
    'Style', 'pushbutton', 'String', 'Cluster',...
    'Callback', {@cluster, mainAx});

Previous = uicontrol('Parent', ButtPan, 'Units', 'normalized', 'position', [1/4 0 1/4 1],...
    'Style', 'pushbutton', 'String', '< Previous',...
    'Callback', {@previous, mainAx});

Next = uicontrol('Parent', ButtPan, 'Units', 'normalized', 'position', [1/2 0 1/4 1],...
    'Style', 'pushbutton', 'String', 'Next >',...
    'Callback', {@next, mainAx});

Accept = uicontrol('Parent', ButtPan, 'Units', 'normalized', 'position', [3/4 0 1/4 1],...
    'Style', 'pushbutton', 'String', 'Accept',...
    'Callback', {@accept, mainAx});

%% Callbacks

    function cluster(hObj, event, axesHandle)
        if r < to_remember && min(assignments(:,r)) > 0 && min(assignments(:,r+1)) == 0
            if r < to_remember
                r = r + 1;
            else
                r = 1;
            end
        end
        [assignments(:,r),centroids(:,:,r),~,mean_err(r),max_err(r)] = ekmeans(data,num_clusters,num_iters,equal);
        cents = round(squeeze(centroids(:,:,r)));
        cla
        plotClusters(data,assignments(:,r),centroids(:,:,r),dims,1);
        tit = uicontrol('Parent',TitlePan,'Style','text','String',['Split = ' num2str(r) ' of ' num2str(to_remember) ...
            ', max error = ' num2str(round(max_err(r))) ', mean error = ' num2str(round(mean_err(r)))],'Units','normalized','Position',[0 0 1 1],'fontsize',14);
    end

    function previous(hObj, event, axesHandle)
        if r == 1
           r = 10;
        else
           r = r - 1;
        end
        if sum(assignments(:,r) == 0)
            cla
            plotClusters(data,assignments(:,r),centroids(:,:,r),dims,0);
        else
            cents = round(squeeze(centroids(:,:,r)));
            cla
            plotClusters(data,assignments(:,r),centroids(:,:,r),dims,1);
        end
        tit = uicontrol('Parent',TitlePan,'Style','text','String',['Split = ' num2str(r) ' of ' num2str(to_remember) ...
            ', max error = ' num2str(round(max_err(r))) ', mean error = ' num2str(round(mean_err(r)))],'Units','normalized','Position',[0 0 1 1],'fontsize',14);
    end

    function next(hObj, event, axesHandle)
        if r < to_remember
            r = r + 1;
        else
            r = 1;
        end
        if sum(assignments(:,r) == 0)
            cla
            plotClusters(data,assignments(:,r),centroids(:,:,r),dims,0);
        else
            cents = round(squeeze(centroids(:,:,r)));
            cla
            plotClusters(data,assignments(:,r),centroids(:,:,r),dims,1);
        end
        tit = uicontrol('Parent',TitlePan,'Style','text','String',['Split = ' num2str(r) ' of ' num2str(to_remember) ...
            ', max error = ' num2str(round(max_err(r))) ', mean error = ' num2str(round(mean_err(r)))],'Units','normalized','Position',[0 0 1 1],'fontsize',14);
    end

    function accept(hObj, event, axesHandle)
        close(fig)
        assignments = assignments(:,r);
        centroids = squeeze(centroids(:,:,r));
        ['User chose split ' num2str(r)]
        return
    end

uiwait(gcf);

end