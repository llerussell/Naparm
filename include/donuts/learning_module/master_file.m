% remember to run mexALL the first time you use this code

clear all; close all

% estimate of the cell diameter. This is used for a variety of parameters,
% so make sure it's within 50% of the true answer. Rather than changing
% this number, it's best to rescale the images such that the average
% cell diameter is about 7. If this number is too big it results in
% unnecessary computational overhead.
ops.cell_diam   = 7; 

% what example image to display during training
ops.ex          = 30;

% a rough estimate of the average number of cells per image
ops.cells_per_image = 400;

% the number of different objects to use. Use NSS>1 if you think there are
% other objects in the image than cells.
ops.NSS     = 1;

% the number of subspaces to use per object. usually, the more data the
% more subspaces can be estiamted.
ops.KS      = 1;

% somewhat redundant: if set to 1 always uses one subspace per object
ops.MP      = 0;

% every ops.inc iterations estimate a new subspace
ops.inc     = 20;

% display figures during learning?
ops.fig     = 1;

% do learning?
ops.learn   = 1;

% where the data is
ops.data_path       = '/Users/lloyd/Dropbox/Bruker2/Naparm3/include/donuts/data';

% where this piece of code is
ops.code_location   = '/Users/lloyd/Dropbox/Bruker2/Naparm3/include/donuts/learning_module';

%%
MPCC2_KSVD;