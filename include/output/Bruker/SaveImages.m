function SaveImages(handles)
NumImages = numel(handles.allImagesProcessed);
% for i = 1:NumImages
%     ImageName = handles.SelectImage_Popup.String{i};
%     ImageData = handles.allImagesProcessed{i};
%     imwrite(ImageData, [handles.data.NaparmDirectory filesep 'Images' filesep ImageName '.tif']);
% end

NumTargetImages = numel(handles.FOVTargetImages);
for i = 1:NumTargetImages
    ImageName = ['FOVTargets_' num2str(i,'%03d') '_' handles.data.ExperimentIdentifier];
    ImageData = handles.FOVTargetImages{i};
    imwrite(ImageData, [handles.data.NaparmDirectory filesep 'Targets' filesep ImageName '.tif']);
end
imwrite(max( cat(3,handles.FOVTargetImages{:}) ,[],3), [handles.data.NaparmDirectory filesep 'Targets' filesep 'AllFOVTargets' '_' handles.data.ExperimentIdentifier '.tif']);

planes = unique(handles.points.Z);
numPlanes = numel(planes);
for z = 1:numPlanes
    imwrite(max( cat(3,handles.FOVTargetImages_byPlane{:,z}) ,[],3), [handles.data.NaparmDirectory filesep 'Targets' filesep 'AllFOVTargets_Plane' num2str(z) '_' handles.data.ExperimentIdentifier '.tif']);

end

NumTargetImages = numel(handles.SLMTargetImages);
for i = 1:NumTargetImages
    ImageName = ['SLMTargets_' num2str(i,'%03d') '_' handles.data.ExperimentIdentifier];
    ImageData = handles.SLMTargetImages{i};
    imwrite(ImageData, [handles.data.NaparmDirectory filesep 'Targets' filesep ImageName '.tif']);
end

NumTargetImages = numel(handles.GalvoPositionImages);
for i = 1:NumTargetImages
    ImageName = ['GalvoPosition_' num2str(i,'%03d') '_' handles.data.ExperimentIdentifier];
    ImageData = handles.GalvoPositionImages{i};
    imwrite(ImageData, [handles.data.NaparmDirectory filesep 'Targets' filesep ImageName '.tif']);
end
imwrite(max( cat(3,handles.GalvoPositionImages{:}) ,[],3), [handles.data.NaparmDirectory filesep 'Targets' filesep 'AllGalvoPositions' '_' handles.data.ExperimentIdentifier '.tif']);

