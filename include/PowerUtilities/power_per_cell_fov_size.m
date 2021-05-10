power_on_sample = 50;
fov_um = 600;
fov_px = 512;
cell_radius_um = 5;
um_per_px = fov_px / fov_um;
cell_radius_px = cell_radius_um * um_per_px;

px_per_cell = 3.14*(cell_radius_px*cell_radius_px);
px_per_fov = fov_px*fov_px;
ms_per_pixel = (1000/30) / px_per_fov;
ms_per_cell = ms_per_pixel * px_per_cell;

duty_cycle_on_cell = (px_per_cell / px_per_fov) *100;

energy_per_cell = ms_per_cell * power_on_sample;

% disp(['fov um: ' num2str(fov_um) '. ms per cell: ' num2str(ms_per_cell, '%.4f')])
disp(['FOV: ' num2str(fov_um) ' um. Energy per cell: ' num2str(energy_per_cell, '%.4f') ' uJ'])
