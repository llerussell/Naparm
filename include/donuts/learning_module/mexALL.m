% mex all C files
try
    fprintf('Attempting to compile all C files...\n')
    mex add_back_coefs.c
    mex pick_patches.c
    mex unpick_patches.c
    mex extract_coefs2_SBC.c
    fprintf('Successfull.\n')
catch
    fprintf('Something went wrong. Did you run mex -setup ?\n')
end