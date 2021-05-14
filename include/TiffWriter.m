function TiffWriter(image,fname,bitspersamp,bigtiff)

if bigtiff
    t = Tiff(fname,'w8');
else
    t = Tiff(fname,'w');
end
tagstruct.ImageLength = size(image,1);
tagstruct.ImageWidth = size(image,2);
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
if bitspersamp==16
    tagstruct.BitsPerSample = 16;
end
if bitspersamp==32
    tagstruct.BitsPerSample = 32;
end
tagstruct.SamplesPerPixel = 1;
tagstruct.RowsPerStrip = 256;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software = 'MATLAB';
t.setTag(tagstruct);
t.write(image(:,:,1));
numframes = size(image,3);
divider = 10^(floor(log10(numframes))-1);
tic
for i=2:numframes
    t.writeDirectory();
    t.setTag(tagstruct);
    t.write(image(:,:,i));
    if (round(i/divider)==i/divider)
        fprintf('Frame %d written in %.0f seconds, %2d percent complete, time left=%.0f seconds \n', ...
            i, toc, i/numframes*100, (numframes - i)/(i/toc));
    end
end
t.close();