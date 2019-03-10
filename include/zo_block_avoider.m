function [targets,cntr,translation] = zo_block_avoider(input,zo_cntr,zo_width,dimensions,translate,varargin)

% (c) Henry Dalgleish 2016
%
% ---------------------------- zo block avoider ---------------------------
%
% This function takes targets to be displayed on an SLM and checks to make
% sure that no points fall within the zero-order spot region of the SLM. If
% they do, spots will be shifted to avoid the zero-order spot region and a
% corresponding yx translation returned. This translation can be used to
% compensate for the shifting of the spots on the SLM by, for instance,
% directing these shifted spots back to their correct location in the
% sample plane by shifting a set of galvo mirrors positioned after the SLM
% in the light-path.
%
% This function has a "translate" option which will take input target
% points and translate them such that their centroid is as close as
% possible to the centre of the SLM whilst still avoiding any target points
% falling in the zero-order spot region. If "translate" is selected then a
% compensatory yx translation is returned which can be used to direct
% centralized target points back to their desired position in the sample
% plane.
%
% N.B. all co-ordinates are specified and returned in the order [y x ...]
%
% --------------------------- Compulsory Inputs ---------------------------
%
% - intput:         2D targets, either provided as an "image" (matrix of
%                   SLM xy dimensions with targets set to 255 and 0's
%                   everywhere else) or a set of 2D co-ordinates ([y x]).
%
% - zo_cntr:        2 element vector containing zero-order spot location on
%                   SLM ([y x]).
%
% - zo_width:       Scalar, width of zero order spot location (n.b. zero
%                   order spot is assumed to be a square for simplicity).
%
% - dimensions:     2 element vector containing the slm pixel array
%                   dimensions ([y x]).
%
% - translate:      Boolean, dictates whether to shift centroid of target
%                   points to centre of SLM and return a compensatory yx
%                   translation.
%
% -------------------------------- Outputs --------------------------------
%
% - targets:        Image of target points (matrix of SLM xy dimensions 
%                   with targets set to 255 and 0's everywhere else) with 
%                   necessary translations applied.
%
% - translation:    Compensatory translations that need to be applied
%                   globally to all points (e.g. by galvo mirrors) to
%                   ensure all points are directed to desired position in
%                   sample plane.
%
% -------------------------------------------------------------------------

output_type = 1;

if ~isempty(varargin)
    
    if strncmpi(varargin{1},'tif',3) || strncmpi(varargin{1},'im',2)
        
        output_type = 1;
        
    elseif strcmpi(varargin{1},'points')
        
        output_type = 2;
        
    end
    
end

hotpix = 255;

if size(input,2) > 2
    
    targ_im = input;
    
    [targ_subs(:,1),targ_subs(:,2)] = find(targ_im);
    
    targ_idcs = find(targ_im);
    
else
    
    targ_subs = input;
    
    targ_idcs = sub2ind(dimensions,targ_subs(:,1),targ_subs(:,2));
    
    targ_im = zeros(dimensions(1),dimensions(2));
    
    targ_im(targ_idcs) = hotpix;
    
end

zo_width = round(zo_width / 2);

[zo_x,zo_y] = ...
    meshgrid(zo_cntr(1)-(zo_width-1):zo_cntr(1)+zo_width,zo_cntr(2)-(zo_width-1):zo_cntr(2)+zo_width);

blank_im = zeros(dimensions(1),dimensions(2));

if translate

    targ_cntr = round(mean(targ_subs,1));
    
    translation = targ_cntr - zo_cntr;
    
    zo_x_trans = zo_x + translation(2);
    
    zo_y_trans = zo_y + translation(1);
    
    in_im = zo_x_trans > 0 & zo_y_trans > 0 & zo_x_trans <= dimensions(2) & zo_y_trans <= dimensions(1);
    
    zo_idcs_trans = sub2ind(dimensions,zo_y_trans(in_im),zo_x_trans(in_im));
        
    zo_block = blank_im;
        
    zo_block(zo_idcs_trans) = hotpix;
    
    blocked = targ_im & zo_block;
    blocked = 1;
    
    if max(blocked(:))
        dtarg_im = double(targ_im);
        
        distfromspots = bwdist(dtarg_im);
        
        trans_centre = zo_cntr + translation;
        
        centralpix = blank_im;
        
        centralpix(trans_centre(1),trans_centre(2)) = hotpix;
        
        distfromcent = bwdist(centralpix);
        
        farcents = find(distfromspots>=zo_width*1.5);
        
        [~,minidx] = min(distfromcent(farcents));
        
        [avoided_y,avoided_x] = ind2sub(dimensions,farcents(minidx));
        

        % make sure the translated targets are not outside of slm space (max coord is 256)
        trans_x = targ_subs(:,2) - avoided_x;
        trans_y = targ_subs(:,1) - avoided_y;
        max_dist = max([abs(trans_x); abs(trans_y)]);
%         keyboard
        if max_dist > 255
            disp('Translated target(s) outside of SLM space, repositioning zero order')
            maxXYoffset = [];
            for i = 1:numel(farcents)
                [y,x] = ind2sub(dimensions,farcents(i));
                trans_x = targ_subs(:,2) - x;
                trans_y = targ_subs(:,1) - y;
                maxXYoffset(i) = max([abs(trans_x); abs(trans_y)]);
%                 maxdists(i) = max(abs(pairwiseDistance([x y], [targ_subs(:,2) targ_subs(:,1)])));
            end
            farcents(maxXYoffset>256) = [];
            img = nan(512, 512);
            img(farcents) = distfromcent(farcents);
            goodindices = find(~isnan(img));
            if isempty(goodindices)
                disp('Not possible :(')
            end
            gooddists = distfromcent(goodindices);
            [~,mindist] = min(gooddists);
            minidx = goodindices(mindist);
            [avoided_y,avoided_x] = ind2sub(dimensions,minidx);
            
            if isempty(goodindices) % failed to fix
                farcents = find(distfromspots>=zo_width*1.5);
                [~,minidx] = min(distfromcent(farcents));
                [avoided_y,avoided_x] = ind2sub(dimensions,farcents(minidx));
            end
        end
        

        
        avoid_shift = trans_centre - [avoided_y avoided_x];
        targ_cntr = [avoided_y avoided_x];
        translation = translation - avoid_shift;
%        keyboard
    end
    
    targ_subs = targ_subs - repmat(translation,size(targ_subs,1),1); 
    targ_subs(targ_subs==0) = 1;
    cntr = targ_cntr;

else
    
    zo_idcs = sub2ind(dimensions,zo_y,zo_x);
    
    zo_block = blank_im;
    
    zo_block(zo_idcs) = hotpix;
    
    blocked = targ_im & zo_block;
    
    targ_cntr = zo_cntr;
    
    if max(blocked(:))
        
        dtarg_im = double(targ_im);
        
        distfromspots = bwdist(dtarg_im);
        
        trans_centre = zo_cntr;
        
        centralpix = blank_im;
        
        centralpix(trans_centre(1),trans_centre(2)) = hotpix;
        
        distfromcent = bwdist(centralpix);
        
        farcents = find(distfromspots>=zo_width*1.5);
        
        [~,minidx] = min(distfromcent(farcents));
        
        [avoided_y,avoided_x] = ind2sub(dimensions,farcents(minidx));
        
        avoid_shift = trans_centre - [avoided_y avoided_x];
        
        targ_cntr = [avoided_y avoided_x];
        
        translation = -avoid_shift;
        
        targ_subs = targ_subs - repmat(translation,size(targ_subs,1),1);
        
    else
        
        translation = [0 0];
        
    end
    
    cntr = targ_cntr;
    
end

if output_type == 1
    
    targ_idcs_trans = sub2ind(dimensions,targ_subs(:,1),targ_subs(:,2));
        
    targets = blank_im;
        
    targets(targ_idcs_trans) = hotpix;
    
elseif output_type == 2
    
    targets = targ_subs;
    
end

end

