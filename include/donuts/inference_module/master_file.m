% MAKE SURE you compile the .c files first by running mexAll.m. 

load mean20130303_H92_009.mat
% replace orig_Im with any mean image from a GCaMP6 - 2x experiment
orig_Im = I; 

% pre-learned model parameters. model.W contains the templates.
load model_GCaMP6_2x.mat 

% If ops.Nextract = 0, the model is calibrated to extract the number of cells it thinks are
% present in the image. If ops.Nextract>0, it extracts exactly that many
% elements from the image (both cell contours and dendrite fragments). 
% The calibrated default for model_GCaMP6_2x is about 600. 
ops.Nextract = 0;

% Returns elem with all identified template locations
% at elem.ix and elem.iy, and with the element types at elem.map. Also
% returns the normalized image that was used to run the inference
[elem, norm_Im] = run_inference(orig_Im, model, ops);

% for comparisons with other segmentations retain only the cell map in 
% elem_model
elem_model = elem;
valid = (elem.map==model.cell_map);
elem_model.ix(~valid) = [];
elem_model.iy(~valid) = [];
%% and here is one way to look at the results overlaid on an image

% selects which of the maps to look at. By default take the cell_map.
% change this to 1 (or 2) to see the locations for the dendrite fragments
which_map = model.cell_map;  

% select only elements from that map
valid = (elem.map==which_map);

% can replace with the mean image, orig_Im
Im = norm_Im;

figure('outerposition',[0 0 1000 1000])

sig = nanstd(Im(:)); mu = nanmean(Im(:)); M1= mu - 4*sig; M2= mu + 12*sig;
imagesc(Im, [M1 M2])
colormap('gray')
hold on
plot(elem.iy(valid), elem.ix(valid), 'or', 'Linewidth', 1, 'MarkerSize', 32)

axis off


