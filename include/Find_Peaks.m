function P = Find_Peaks( T, varargin )
% Finds Peaks or Valleys in an N-D matrix T.
% Requires the Image Processing Toolbox.
%
% Options
% 'neighborhood', an integer to design a cuboidal filter with edges of length ``r``
%        default: r = 5 
% 'valley', boolean value ``true`` and ``false`` find valleys and peaks respectively.
%        default: false; % Find Peaks
%
% Returns Boolean matrix with dimensions equal to T.  ``true`` entries indicate a peak or valley
%        depending upon the flag used to call this function.


% Finds the peaks or valleys in the spatial correlation functions.
param = setparam( varargin, numel(T),size(T) );

% Design the filter
F = ones( param.neighborhood);
F( ceil(numel(F)./2) ) = 0;


if ~param.valley
    P = T > imdilate( T, F );
else
    P = T < imerode( T, F );
end



function param = setparam( varargin, N, sz )
    if sz(2) == 1 & N == sz(1)
        r = 1;
    else
        r = numel( sz );
    end

    param = struct( 'neighborhood', 5*ones(1,r),...
        'valley', false);
    if numel( varargin ) > 0
        for ii = 1 : 2 :numel( varargin )
            param = setfield( param, varargin{ii}, varargin{ii+1});
        end
    end
end %setparam

end %Find_Peaks  