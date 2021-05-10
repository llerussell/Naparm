function GPL = MarkPoints_GPLMaker(Xpx, Ypx, IsSpiral, SpiralSizeUM, SpiralRevolutions, SaveName)
% Lloyd Russell 20151119
% Produces XML file of custom galvo positions to be loaded into Prairie View Mark Points

% Note:
% unclear why the X uncaging voltages are taken with reference to Galvo X,
% whereas the uncaging Y are taken with reference to Resonant Y...

% Inputs
% ------
% Xpx          - 1d array of desired X coordinates (in pixels)
% Ypx          - 1d array of desired Y coordinates (in pixels)
% IsSpiral     - string, 'True' for spiral, 'False' for single point
% SpiralSizeUM - size in microns of the sprial
% SaveName     - provide a save name to save out to file (otherwise returned by function)

% Note pixel coordinates start at 0,0 (0:511 for a 512 image)

% get values from settings file
yaml = ReadYaml('settings.yml');

% prairie numbers
ScanAmp_X           = yaml.ScanAmp_X;
ScanAmp_Y           = yaml.ScanAmp_Y;
FOVsize_OpticalZoom = yaml.FOVsize_OpticalZoom;
FOVsize_PX          = yaml.FOVsize_PX;
FOVsize_UM_1x       = yaml.FOVsize_UM_1x;

% convert full field into imaging FOV
ScanAmp_V_FOV_X = ((ScanAmp_X - mean(ScanAmp_X)) / FOVsize_OpticalZoom) + mean(ScanAmp_X);  % centre, scale, offset
ScanAmp_V_FOV_Y = ((ScanAmp_Y - mean(ScanAmp_Y)) / FOVsize_OpticalZoom) + mean(ScanAmp_Y);  % centre, scale, offset


% build LUT's
LUTx = linspace(ScanAmp_V_FOV_X(1), ScanAmp_V_FOV_X(2), FOVsize_PX);
LUTy = linspace(ScanAmp_V_FOV_Y(1), ScanAmp_V_FOV_Y(2), FOVsize_PX);

% convert pixel coordinates to voltages
Xv = LUTx(Xpx+1);
Yv = LUTy(Ypx+1);


% convert spiral size in microns to voltage
% SpiralSizeV = SpiralSizeUM * (2*ScanAmp_V_FOV_X / (FOVsize_UM_1x/FOVsize_OpticalZoom)); % 0.3V is 10um, 0.6V is 20um
SpiralSizeV = SpiralSizeUM * yaml.SpiralSizeMultiplier; % 0.3V is 10um, 0.6V is 20um

% build the GPL file
header = [...
    '<?xml version="1.0" encoding="utf-8"?>'...
    '<PVGalvoPointList>'...
    ];  
NumPoints = numel(Xpx);
for i = 1:NumPoints
	PointList{i} = [...
        '<PVGalvoPoint '...
        'X="' num2str(Xv(i)) '" '...
        'Y="' num2str(Yv(i)) '" '...
        'Name="Point ' num2str(i) '" '...
        'Index="' num2str(i-1) '" '...
        'ActivityType="MarkPoints" '...
        'UncagingLaser="Photostim" '...
        'UncagingLaserPower="0" '...
        'Duration="10" '...
        'IsSpiral="' IsSpiral '" '...
        'SpiralSize="' num2str(SpiralSizeV) '" '...
        'SpiralRevolutions="' num2str(SpiralRevolutions) '" '...
        '/>'...
    ];
end
footer = '</PVGalvoPointList>';
GPL = [header [PointList{:}] footer];

% save the GPL file
if ~strcmpi(SaveName, '')  % if save name provided, save to file
    fid = fopen([SaveName '.gpl'], 'w', 'l');
    fwrite(fid, GPL, 'char');
    fclose(fid);
end
