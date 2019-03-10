function [x,y,normImg] = MariusCellFinder(orig_Im)
% LR 2016
% Modified HD's CellFinder_3D
% Uses Marius Pachitariu's static cell-detection algorithm

% pre-learned model parameters. model.W contains the templates.
x = load('C1V1_1_34x_512_model');

% If ops.Nextract = 0, the model is calibrated to extract the number of cells it thinks are
% present in the image. If ops.Nextract>0, it extracts exactly that many
% elements from the image (both cell contours and dendrite fragments).
% The calibrated default for model_GCaMP6_2x is about 600.
ops.Nextract = 0;

% Returns elem with all identified template locations
% at elem.ix and elem.iy, and with the element types at elem.map. Also
% returns the normalized image that was used to run the inference
[elem, norm_Im] = run_inference(orig_Im, x.model, ops);

% for comparisons with other segmentations retain only the cell map in
% elem_model
elem_model = elem;
valid = (elem.map==x.model.cell_map);
elem_model.ix(~valid) = [];
elem_model.iy(~valid) = [];

% output
% note x and y are messed up... it plots correctly this way!
x = elem_model.iy;
y = elem_model.ix;
normImg = norm_Im;
