function visualSS( W, mag, rows,clims, varargin)
% visual - display a basis for image patches
%
% W        the basis, with patches as column vectors
% mag      magnification factor
% cols     number of columns (x-dimension of map)
% ysize    [optional] height of each subimage
%
    
mini=min(W(:));
   
% This is the side of the window

if ~isempty(varargin)
    A = varargin{1};    
    xsize = A(1);
    ysize = A(2);
else
    ysize = sqrt(size(W,1));
    xsize = size(W,1)/ysize;
end

% Helpful quantities
xsizem = xsize-1;
xsizep = xsize+1;
ysizem = ysize-1;
ysizep = ysize+1;
cols = ceil(size(W,2)/rows);

% Initialization of the image
I = mini*ones(2+ysize*rows+rows-1,2+xsize*cols+cols-1);

for j=0:cols-1
    for i=0:rows-1        
        if j*rows+i+1>size(W,2)
            1;
            % This leaves it at background color            
        else
            % This sets the patch
            I(i*xsizep+2:i*xsizep+xsize+1, ...
                j*ysizep+2:j*ysizep+ysize+1) = ...
                reshape(W(:,j*rows+i+1),[xsize ysize]);
        end
        
    end
end

% Make a black border
I(1,:) = 0;
I(:,1) = 0;
I(end,:) = 0;
I(:,end) = 0;

I = imresize(I,mag);

imagesc(I, clims);
axis image
axis off
colormap('gray')
% colorbar
% iptsetpref('ImshowBorder','tight'); 
truesize;  
drawnow
end