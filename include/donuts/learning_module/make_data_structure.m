% make datra structure for marius nference

% path to folder of tiffs
path = '/Users/lloyd/Dropbox/Bruker2/Naparm3/include/donuts/CorrImgs_4Planes';

files = glob([path filesep '*.tif']);

y = [];
for f = 1:numel(files)
    y(:,:,f) = TiffReader(files{f});
end

[basePath folderPath] = fileparts(path);
save([basePath filesep 'data' filesep folderPath '.mat'], 'y');
