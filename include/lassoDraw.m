function [lassoX,lassoY] = lassoDraw(axHandle)
% Lloyd 2017
% This will return XY coordinates of the polygon drawn by the lasso tool.
% These coordinates can then be used to find objects within the selection
% (currently done outside of this simple function).
% e.g. selectedPoints = inpolygon(AllPointsX, AllPointsY, lassoX, lassoY);

% input = the handle to the axes in which to draw the lasso.
% Based heavily on selectdata.m (John D'Errico):
% https://uk.mathworks.com/matlabcentral/fileexchange/13857-graphical-data-selection-tool


% selection colour
COLOR = [0.3 .7 1];
COLOR = [1 0 0];

% get the figure containing the designated axes
figHandle = ancestor(axHandle, 'figure');

% save original mouse button callbacks
oldWindowButtonDownFcn = figHandle.WindowButtonDownFcn;
oldWindowButtonMotionFcn = figHandle.WindowButtonMotionFcn;
oldWindowButtonUpFcn = figHandle.WindowButtonUpFcn;

% set new window callbacks
figHandle.WindowButtonDownFcn = @lassoStart;

% initialise
lassoHandle = [];
lassoX = [];
lassoY = [];

% wait for the user input
uiwait

    function lassoStart(src, event)
        coords = get(axHandle,'currentpoint');
        x = round(coords(1,1,1));
        y = round(coords(1,2,1));

        % check to see if click was inside axes
        if x>axHandle.XLim(1) & x<axHandle.XLim(2) & y>axHandle.YLim(1) & y<axHandle.YLim(2)
            % button down detected
            currentPoint = get(gca,'CurrentPoint');
            currentX = currentPoint(1,1);
            currentY = currentPoint(1,2);

            % form the polygon
            lassoX = [currentX currentX];
            lassoY = [currentY currentY];
            lassoHandle = fill(lassoX, lassoY, COLOR);
            set(lassoHandle, 'facealpha',0.5, 'linewidth',1.5, 'linestyle','-', 'edgecolor',COLOR)

            % set mouse motion callback
            figHandle.WindowButtonMotionFcn = @lassoMotion;
            figHandle.WindowButtonUpFcn = @lassoDone;
        end
    end

    function lassoMotion(src, event)
        % get the new mouse position
        currentPoint = get(gca,'CurrentPoint');
        currentX = currentPoint(1,1);
        currentY = currentPoint(1,2);
        
        % make the new lasso and close it to form the polygon
        lassoX = [lassoX(1:end-1) currentX lassoX(end)];
        lassoY = [lassoY(1:end-1) currentY lassoY(end)];
        
        % replot the newly extended lasso
        lassoHandle.XData = lassoX;
        lassoHandle.YData = lassoY;
    end

    function lassoDone(src, event)
        % reset the WindowButtonFcn's
        figHandle.WindowButtonDownFcn = oldWindowButtonDownFcn;
        figHandle.WindowButtonMotionFcn = oldWindowButtonMotionFcn;
        figHandle.WindowButtonUpFcn = oldWindowButtonUpFcn;
        
        % delete the selection object from the plot
        delete(lassoHandle)
        lassoHandle = [];
        
        % resume application
        uiresume
    end
end