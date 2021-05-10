function [handles] = OutputConfigs(handles)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output wrapper function that converts all GUI data into config files that
% are saved out to be imported into microscope and SLM software. This is
% currently defaulted to outputs that work with PrairieView (Bruker
% Corporation) by using functions in:
% <yourPath>/Naparm3/include/output/Bruker.
%
% See below for some info on how to re-configure for your system, adding
% your functions to a new directory in the output directory:
% <yourPath>/Naparm3/include/output/<yourSystemName>

% Phase mask generation:
% ---------------------- 
% This should save out phasemask information in a format appropriate for
% your SLM/microscope software. For us this is a folder of phase mask .tif
% images (512x512 16-bit) in the order that they will be sequenced through,
% where each filename contains the number of targets in that phasemask (in
% the format phaseMaskName_100Targets.tif if there were 100 targets for the
% phase mask called phaseMaskName). Note that it is important to keep this
% naming convention so that laser powers, which are dependent on number of
% targets, can be worked out for each phasemask by downstream software.
% This is read by the Blink SLM software (Meadowlark) which interfaces
% directly with the SLM, which itself is triggered to change phasemasks by
% TTLs from the Prairieview microscope software.
% 
% Note that your phase mask generator function *must* also add two fields
% to the handles structure for Naparm3 to export without errors:
%
% (1) handles.PhaseMasks = cell array of numPatterns x 1 where each cell
% contains the phase mask (image) for each pattern in your sequence of
% patterns.
%
% (2) handles.TransformedSLMTargets = cell array of numPatterns x 1 where
% each cell contains a target image (image with 0s everywhere except
% for target co-ordinates which are 1) for each pattern in your sequence of
% patterns, where target co-ordinates have been transformed from imaging
% space to SLM space.
%
% These are required so that the preview animation can run following file
% export (ShowPreview function, referenced in the
% ExportAll_Pushbutton_Callback in the main Naparm3.m function). Note that
% if you do get errors about ShowPreview not running, the files themselves
% will have been exported, its just that the preview animation couldn't
% run.
%
% GPL/XML generation: 
% ------------------- 
% These follow the convention use by Bruker microscopes where the GPL is
% the galvo points list (the list of unique galvo centroid positions that
% correspond to the list of phasemasks) and the XML contains protocol
% sequence information (which galvo points in the GPL occur in what order
% and with what stimulus parameters; laser power, spiral duration,
% repetitions etc.).
%
% Our functions below (MakeMarkPointsGPL and MakeMarkPointsXML) save out
% external files that are imported into the microscope software. For
% different microscope setups your functions should do something similar,
% but with output files formatted to be read appropriately by your
% microscope software.
%
% Note that these functions do not need to append anything to the handles
% structure for Naparm3 to work.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

handles = MakePhaseMasks(handles,true);     % make/save list of phasemasks
MakeMarkPointsGPL(handles);                 % make/save list of galvo positions
MakeMarkPointsXML(handles);                 % make/save list of spirals (powers, galvo positions, timing parameters)

end

