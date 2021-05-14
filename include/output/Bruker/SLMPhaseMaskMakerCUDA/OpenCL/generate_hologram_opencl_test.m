% test opencl generate hologram dll from bruker/meadowlark/bns
% lloyd russell 2019


% load dll
HologramLibraryName = 'Generate_hologram_opencl';
if ~libisloaded(HologramLibraryName)
    loadlibrary([HologramLibraryName '.dll'])
end
% libfunctionsview(HologramLibraryName);  % lists inputs and outputs of the fucntions in dll
    % int32 - Create_generator_cl - (uint32, uint32, uint32, uint32, int32)                                                                                                                                                                              }
    % int32 - Destroy_generator_cl                                                                                                                                                                                                                    }
    % [int32, singlePtr, singlePtr, singlePtr, singlePtr, int32Ptr, singlePtr, uint8Ptr, singlePtr, singlePtr] - Generate_hologram_cl - (uint32, singlePtr, singlePtr, singlePtr, singlePtr, uint32, int32Ptr, singlePtr, uint8Ptr, singlePtr, singlePtr)'}
    % cstring - Get_last_error_message                                                                                                                                                                                                      }
    % cstring - Get_version_info'   


% make random targets
rng(1);
numSpots   = 10;
imagingFOV = [50 50];  % x y
x          = randi([1,imagingFOV(1)], numSpots,1) - (imagingFOV(1)/2);
y          = randi([1,imagingFOV(2)], numSpots,1) - (imagingFOV(2)/2);
z          = randi([-10,10], numSpots,1);
I          = randi([1,1], numSpots,1);  %ones(size(x));


% parameters
SLMsize         = [2048 2048];  % x y. must be power of two.. has to be divisible by 256. 1920 does not work.
startingPhases  = zeros(SLMsize) + 0.5;  % the starting phase mask. start from 0, 0.5, 1 does it matter?
hologramImage   = nan(SLMsize);
xSpots          = x;  % ensure centre the coords
ySpots          = y;  % ensure centre the coords
zSpots          = z;
ISpots          = I; 
NSpots          = length(xSpots);
calcIntensities = 0;  % unused
calcTime        = 0;  % always 0
maxSpots        = 999;
method          = 1;  % only 1 is alllowed
N_iterations    = 100;
useGpu          = 1;


% make phase mask
err1 = calllib(HologramLibraryName, 'Create_generator_cl',...
    SLMsize(1), SLMsize(2), maxSpots, N_iterations, useGpu);

[err2, ~, ~, ~, ~, ~, ~, hologramImage, ~, ~] = calllib(HologramLibraryName,'Generate_hologram_cl',...
    NSpots, xSpots, ySpots, zSpots, ISpots, N_iterations, method, startingPhases, hologramImage, calcIntensities, calcTime);

err3 = calllib(HologramLibraryName, 'Destroy_generator_cl');
      
unloadlibrary(HologramLibraryName);  % tidy up, unload dll
     

% plot result
figure
subplot(1,2,1)
scatter3(xSpots, ySpots, zSpots, 'filled')
axis equal; axis tight; box off;
xlim([-imagingFOV(1) imagingFOV(1)])
ylim([-imagingFOV(2) imagingFOV(2)])
zlim([-10 10])
xlabel('X')
ylabel('Y')
zlabel('Z')
title('Targets')

subplot(1,2,2)
imagesc(hologramImage)
axis equal; axis tight; box off
title('Mask')
