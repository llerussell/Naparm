function varargout = Naparm3(varargin)
%             __        __         __
%  |\ |  /\  |__)  /\  |__)  |\/|   _)
%  | \| /--\ |    /--\ |  \  |  |  __)
%
% Description
% ===========--------------------------------------------------------------
% Blah blah
%
% Authors
% =======------------------------------------------------------------------
% Henry Dalgleish
% Lloyd Russell

% TO DO (3D):
% ===========--------------------------------------------------------------
% * process/filter single frame out of a stack (and save it back)
% * auto find cells plane by plane
% * only show points and groups in one plane (or allow to show all at once)
% * Group only within a plane


% Last Modified by GUIDE v2.5 27-Jul-2020 18:02:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Naparm3_OpeningFcn, ...
    'gui_OutputFcn',  @Naparm3_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT



% --- Executes just before Naparm3 is made visible.
function Naparm3_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

evalin('base', 'NaparmFig=gcf;');  % this is neccessary for drag n drop

% Add dependencies to path
current_mfile_path = fileparts(mfilename('fullpath'));
addpath(current_mfile_path)
addpath(genpath([current_mfile_path filesep 'include']));  % and subfolders

% set up paths for defaults and presets
handles.CodePath = current_mfile_path;
handles.PresetsPath = [handles.CodePath filesep 'Presets'];
if ~isdir(handles.PresetsPath)
    mkdir(handles.PresetsPath);
end
DefaultsFile = [handles.CodePath filesep 'GUIdefaults.mat'];
if exist(DefaultsFile, 'file')
    LoadGUIState(DefaultsFile, handles)
end

% Drag and Drop functionality
dndcontrol.initJava();
dndObj = dndcontrol(hObject.JavaFrame.getAxisComponent);
dndObj.DropFileFcn = @DragNDropFcn;

% Choose default command line output for Naparm3
handles.output = hObject;

% store GUI size (used for later resizing)
figurePosition = get(hObject, 'Position');
figureWidth = figurePosition(3);
figureHeight = figurePosition(4);
handles.AspectRatioGUI = figureWidth/figureHeight;

% configure image axes
hold(handles.ImageAx, 'on')
handles.ImageAx.Clipping = 'off';

% add image plot
handles.fovSize = [512 512]; % HWPD, NB this is YX (i.e. rows,columns)
handles.fovCntr = handles.fovSize/2;
handles.imageDisplay = imshow(zeros(handles.fovSize(1),handles.fovSize(2)), [0 1], 'Parent',handles.ImageAx);
handles.imageDisplay.XData = [0 handles.fovSize(1)-1];
handles.imageDisplay.YData = [0 handles.fovSize(2)-1];
handles.ImageAx.XLim = [0 handles.fovSize(1)] - 0.5;
handles.ImageAx.YLim = [0 handles.fovSize(2)] - 0.5;

% add border around image plot
XLim = handles.ImageAx.XLim;
YLim = handles.ImageAx.YLim;
handles.ImageRect = rectangle(handles.ImageAx, 'position',[XLim(1) YLim(1) XLim(2)-XLim(1) YLim(2)-YLim(1)],...
    'edgecolor',[.5 .5 .5],'LineWidth',0.5);


% add timing plots
% Patterns
handles.TimingPlotPatterns = imagesc(ones(1,100),  'Parent',handles.TimingPlotPatternsAx);
handles.TimingPlotPatternsAx.Visible = 'off';
colormap(handles.TimingPlotPatternsAx, 'gray')

% Triggers
handles.TimingPlotAx.YLim = [0,3];
handles.TimingPlotAx.Visible = 'off';
hold(handles.TimingPlotAx, 'on')
handles.TimingPlotAx.Clipping = 'off';
handles.TimingPlotSpirals = plot(0,0, 'color',[.6 .6 .6], 'Parent',handles.TimingPlotAx);
handles.TimingPlotSLMTriggers = plot(0,0, 'k', 'Parent',handles.TimingPlotAx);
handles.TimingPlotSpiralTriggers = plot(0,0, 'k', 'Parent',handles.TimingPlotAx);


% All trials
handles.AllTrialsTimingPlotAx.Visible = 'off';
handles.AllTrialsTimingPlotAx.YLim = [0,2];
handles.AllTrialsTimingPlotAx.Visible = 'off';
hold(handles.AllTrialsTimingPlotAx, 'on')
handles.AllTrialsTimingPlotAx.Clipping = 'off';
handles.AllTrialsTimingPlotSLMTriggers = plot(0,0, 'k', 'Parent',handles.AllTrialsTimingPlotAx);
handles.AllTrialsTimingPlotSpiralTriggers = plot(0,0, 'k', 'Parent',handles.AllTrialsTimingPlotAx);


% configure preview axes
im = imshow(ones(handles.fovSize(1),handles.fovSize(2)), 'Parent',handles.PreviewFOVTargets_Ax);
im.AlphaData = nan(handles.fovSize(1),handles.fovSize(2));
hold(handles.PreviewFOVTargets_Ax, 'on')
handles.PreviewFOVTargetsALL_Scatter = scatter3(nan,nan,nan, 10, 'filled', 'Parent',handles.PreviewFOVTargets_Ax);
handles.PreviewFOVTargets_Scatter = plot3(nan,nan,nan, 'k.', 'markersize',20, 'Parent',handles.PreviewFOVTargets_Ax);
handles.PreviewFOVTargetsALL_Scatter.MarkerFaceColor = [.8 .8 .8];
handles.PreviewFOVTargetsALL_Scatter.MarkerFaceAlpha  = 0.5;
uistack(handles.PreviewFOVTargetsALL_Scatter,'bottom');
uistack(handles.PreviewFOVTargets_Scatter,'top');
handles.PreviewFOVTargets_Ax.XLim = [0,handles.fovSize(2)-1];
handles.PreviewFOVTargets_Ax.YLim = [0,handles.fovSize(1)-1];
handles.PreviewFOVTargets_Ax.Visible = 'on';
handles.PreviewFOVTargets_Ax.XTick = [];
handles.PreviewFOVTargets_Ax.YTick = [];
handles.PreviewFOVTargets_Ax.ZTick = [];
handles.PreviewFOVTargets_Ax.Title.String = 'FOV';
handles.PreviewFOVTargets_Ax.Title.FontSize = 10;


im = imshow(ones(handles.fovSize(1),handles.fovSize(2)), 'Parent',handles.PreviewFOVGalvo_Ax);
im.AlphaData = nan(handles.fovSize(1),handles.fovSize(2));
hold(handles.PreviewFOVGalvo_Ax, 'on')
handles.PreviewFOVGalvoALL_Scatter = plot(nan,nan, 's', 'color',[.7 .7 .7], 'Parent',handles.PreviewFOVGalvo_Ax);
handles.PreviewFOVGalvo_Scatter = plot(nan,nan, 'ks', 'Parent',handles.PreviewFOVGalvo_Ax);
handles.PreviewFOVGalvo_Ax.XLim = [0,handles.fovSize(2)-1];
handles.PreviewFOVGalvo_Ax.YLim = [0,handles.fovSize(1)-1];
handles.PreviewFOVGalvo_Ax.Visible = 'on';
handles.PreviewFOVGalvo_Ax.XTick = [];
handles.PreviewFOVGalvo_Ax.YTick = [];
handles.PreviewFOVGalvo_Ax.ZTick = [];
handles.PreviewFOVGalvo_Ax.Title.String = 'Galvo offset';
handles.PreviewFOVGalvo_Ax.Title.FontSize = 10;

handles.PreviewSLMTargets_Ax.Color = [0 0 0];
im = imshow(ones(handles.fovSize(1),handles.fovSize(2)), 'Parent',handles.PreviewSLMTargets_Ax);
im.AlphaData = nan(handles.fovSize(1),handles.fovSize(2));
hold(handles.PreviewSLMTargets_Ax, 'on')
handles.PreviewSLMZO_Scatter = plot3(handles.fovCntr(2),handles.fovCntr(1),0, 'w+', 'color',[.5 .5 .5], 'markersize',12, 'Parent',handles.PreviewSLMTargets_Ax);
handles.PreviewSLMTargets_Scatter = plot3(nan,nan,0, 'w.', 'markersize',10, 'Parent',handles.PreviewSLMTargets_Ax);
handles.PreviewSLMTargets_Ax.XLim = [0,handles.fovSize(2)-1];
handles.PreviewSLMTargets_Ax.YLim = [0,handles.fovSize(1)-1];
handles.PreviewSLMTargets_Ax.Visible = 'on';
handles.PreviewSLMTargets_Ax.XTick = [];
handles.PreviewSLMTargets_Ax.YTick = [];
handles.PreviewSLMTargets_Ax.ZTick = [];
handles.PreviewSLMTargets_Ax.Title.String = 'SLM targets';
handles.PreviewSLMTargets_Ax.Title.FontSize = 10;

handles.PreviewPhaseMask_Im = imshow(zeros(handles.fovSize(1),handles.fovSize(2)), 'Parent',handles.PreviewPhaseMask_Ax);
colormap(handles.PreviewPhaseMask_Ax, 'gray')
handles.PreviewPhaseMask_Ax.Visible = 'on';
handles.PreviewPhaseMask_Ax.XTick = [];
handles.PreviewPhaseMask_Ax.YTick = [];
handles.PreviewPhaseMask_Ax.Title.String = 'Phase mask';
handles.PreviewPhaseMask_Ax.Title.FontSize = 10;

% configure uitable
jscrollpane = findjobj(handles.PointsTable);
% jscrollpane
% jtable = jscrollpane.getViewport.getView;
% jtable.setSortable(true);		% or: set(jtable,'Sortable','on');
% jtable.setAutoResort(true);
% jtable.setMultiColumnSortable(true);
% jtable.setPreserveSelectionsAfterSorting(true);


% add parameters to handles structure
handles.allImagesRaw = {};
handles.allImagesProcessed = {};
handles.allImageShapes = {};
handles.selectedImageIndex = [];

handles.data = ResetOutput();
handles.points = [];
handles.points.h = scatter(handles.ImageAx, [], [], 200, [1,1,1], 'linewidth',1, 'HitTest','on', 'ButtonDownFcn',@MouseClickPoint);
handles.points = ResetPoints(handles.points);
handles.ClusterLines = [];
handles.ClusterCentroids = [];
handles.hSelection = scatter(handles.ImageAx, [], [], 300, 'markeredgecolor','y', 'linewidth',2,'markerfacecolor','y','markerfacealpha',0.4);

% new 3d stuff
handles.CurrentZPlane = 1;
handles.ZPlane_slider.Min = 1;
handles.ZPlane_slider.Max = 1;
handles.ZPlane_slider.Value = 1;
handles.ZPlane_slider.SliderStep = [0 1];
CurrentZPlane_edit_Callback()

% add main point plot
% allow cursor to change when hover over the point
fig = handles.output;
iptPointerManager(fig);
pointerBehaviour.enterFcn = @(fig, CurrentPoint) set(fig, 'Pointer', 'hand');
pointerBehaviour.exitFcn = [];
pointerBehaviour.traverseFcn = [];
% pointerBehaviour.traverseFcn = @(fig, currentPoint) {set(h, 'markeredgecolor',[1,0.5,0.5])};
iptSetPointerBehavior(handles.points.h, pointerBehaviour);


% Update handles structure
guidata(hObject, handles);

% handles.imageDisplay.HitTest = 'off';
handles.imageDisplay.ButtonDownFcn = @MouseClickAxes;

% make cursor change to crosshair over axes only
iptPointerManager(hObject);
enterFcn = @(hObject, currentPoint) set(hObject, 'Pointer', 'crosshair');
iptSetPointerBehavior(handles.ImageAx, enterFcn);

% keyboard
hObject.WindowButtonMotionFcn = @MouseMove;

% chnage color of slm preview plot
handles.PreviewSLMTargets_Ax.Color = [0 0 0];
handles.PreviewSLMTargets_Ax.XColor = [.5 .5 .5];
handles.PreviewSLMTargets_Ax.YColor = [.5 .5 .5];
handles.PreviewSLMTargets_Ax.ZColor = [.5 .5 .5];

handles.PreviewFOVTargets_Ax.XColor = [.5 .5 .5];
handles.PreviewFOVTargets_Ax.YColor = [.5 .5 .5];
handles.PreviewFOVTargets_Ax.ZColor = [.5 .5 .5];

handles.PreviewFOVGalvo_Ax.XColor = [.5 .5 .5];
handles.PreviewFOVGalvo_Ax.YColor = [.5 .5 .5];

handles.PreviewPhaseMask_Ax.XColor = [.5 .5 .5];
handles.PreviewPhaseMask_Ax.YColor = [.5 .5 .5];



function points = ResetPoints(points)
points.X = [];
points.Y = [];
points.Z = [];
points.Zum = [];
points.OffsetX = [];
points.OffsetY = [];
points.Idx = [];
points.Img = [];
points.Group = [];

points.GroupCentroidX = [];
points.GroupCentroidY = [];
points.Counter = 0;
points.Weight = [];
points.Selected = [];

points.h.XData = [];
points.h.YData = [];
points.h.CData = [1,1,1];


function output = ResetOutput()
output = [];
output.Path = [];
output.Name = [];
output.ExptNum = 1;
output.FOVtargets = [];
output.SLMtargets = [];
output.PhaseMasks = [];
output.Points = [];
output.GalvoPositions = [];
output.Parameters = [];


% --- Outputs from this function are returned to the command line.
function varargout = Naparm3_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in LoadImages_Button.
function LoadImages_Button_Callback(hObject, eventdata, handles)
% hObject    handle to LoadImages_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% setappdata(hObject, 'Images', 'random..')
[FileName,PathName] = uigetfile('*.tif','Select the image(s)', 'MultiSelect','On');

if iscell(FileName) | (FileName ~= 0 & ~iscell(FileName))
    if ~iscell(FileName)
        % make cell array of filenames, even if only 1 filename
        FileName = {FileName};
    end
    
    % turn tiff warnings off
    w = warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning');
    warning('off', 'MATLAB:imagesci:tifftagsread:expectedTagDataFormat');
    
    % load all images
    NumFiles = numel(FileName);
    % group all images with Plane in name
    if ~all(contains(FileName,'_Plane'))
        for i = 1:NumFiles
            FullPath = [PathName filesep FileName{i}];
            handles = loadImage(handles, FullPath);
        end
    else
        for i = 1:NumFiles
            FullPaths{i} = [PathName filesep FileName{i}];
        end
        handles = loadImage(handles, FullPaths);
    end
    
    % change directory
    cd(PathName);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % turn tiff warnings back on
    warning(w);
end


function handles = loadImage(handles, FullPath)
% load tiff image
% tsStack = TIFFStack(FullPath);
% img = tsStack(:,:);
img = [];
if iscell(FullPath)
    for i = 1:numel(FullPath)
        try
            tmp = TiffReader(FullPath{i});
        catch
            tmp = imread(FullPath{i});
        end
        img(:,:,i,:) = tmp;
    end
    FullPath = FullPath{1};
else
    img = TiffReader(FullPath);
end

% convert to double
img = double(img);

% normalise image
img = normalise(img);

% deal with imported images of different size
if any(size(img(:,:,1)) ~= handles.fovSize)
    % if first image, take this image size as default
    if isempty(handles.allImageShapes)
        handles.fovSize = size(img(:,:,1));
        handles.fovCntr = handles.fovSize/2;
        handles = resetAllImageSizes(handles);
    % if different to previously imported images, resize this image
    else
        warning('Images are different sizes, image resized to match previous images')
        img = imresize(img,handles.fovSize);
    end
end

% get image dimensions
handles.allImageShapes{end+1} = size(img);

% update zlider max to number of frames/slices
currentSliderMax = handles.ZPlane_slider.Max;
handles.ZPlane_slider.Max = max([currentSliderMax size(img,3)]);
numSlices = handles.ZPlane_slider.Max;
handles.ZPlane_slider.SliderStep = [0 1/(numSlices-1)];
handles.CurrentPlane_text.String = ['Plane ' num2str(handles.CurrentZPlane) ' of ' num2str(numSlices)];

% save raw image
handles.allImagesRaw{end+1} = img;

% save processed image
handles.allImagesProcessed{end+1} = img;

% get image name
[ImgPath, ImgName, ~] = fileparts(FullPath);

% add image name to list
popupItems = handles.SelectImage_Popup.String;
popupItems{end+1} = ImgName;
handles.SelectImage_Popup.String = popupItems;

% change selected popup item
handles.SelectImage_Popup.Value = numel(popupItems);
SelectImage_Popup_Callback([],[],handles);

% change ExperimentName value if first file
if isempty(handles.data.Name)
    name = strsplit(ImgName, '_');
    if numel(name) > 1
        handles.data.Name = strjoin(name(1:2) ,'_');
    else
        handles.data.Name = name{1};
    end
    handles.ExperimentName_Edit.String = [handles.data.Name '_NAPARM'];
end

if isempty(handles.data.Path)
    handles.data.Path = ImgPath;
end

% auto increment expt number
contents = dir([handles.data.Path filesep handles.data.Name '_NAPARM*']);
iter = 1;
if ~isempty(contents)
    names = {contents.name};
    for i = 1:numel(names)
        ExptID = str2double(names{i}(end-2:end));
        if ExptID >= iter
            iter = ExptID + 1;
        end
    end
end
handles.ExperimentNum_Edit.String = num2str(iter);



% --- Executes on selection change in SelectImage_Popup.
function handles = SelectImage_Popup_Callback(hObject, eventdata, handles)
% hObject    handle to SelectImage_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SelectImage_Popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SelectImage_Popup

% get index of selected item
index = handles.SelectImage_Popup.Value;

% get the selected images name
ImgName = handles.SelectImage_Popup.String{index};

% update the 'current image' text
% handles.CurrentImage_Text.String = ImgName;

% now change the image
changeImage(handles)


function changeImage(handles)
% get the image data
index = handles.SelectImage_Popup.Value;

img = handles.allImagesProcessed{index};
allImg = handles.allImagesProcessed{:};
allImg = allImg(:);

% take just one frame if multiple frames
if numel(handles.allImageShapes{index}) > 2
%     if handles.allImageShapes{index}(3)==3 % assume color image....
%         img = img;
%     else
    img = squeeze(img(:,:,handles.CurrentZPlane,:));
%     end
end

% update the data
handles.imageDisplay.CData = imadjust(img, stretchlim(img, [0.001 .999]));
% handles.imageDisplay.CData = img;

% adjust axes limits
% HWPD
handles.imageDisplay.XData = [0 handles.allImageShapes{index}(1)] -1;
handles.imageDisplay.YData = [0 handles.allImageShapes{index}(2)] -1;
handles.ImageAx.XLim = [0 handles.allImageShapes{index}(1)] -0.5;
handles.ImageAx.YLim = [0 handles.allImageShapes{index}(2)] -0.5;

% adjust image border
XLim = handles.ImageAx.XLim;
YLim = handles.ImageAx.YLim;
handles.ImageRect.Position = [XLim(1) YLim(1) XLim(2)-XLim(1) YLim(2)-XLim(1)];



function handles = resetAllImageSizes(handles)
% resets all image panes to have size of most recently imported image (if
% it is different size to default [512,512] or to previously imported
% images 

% reset size of main image axis
handles.imageDisplay.CData = zeros(handles.fovSize(1),handles.fovSize(2));
handles.imageDisplay.XData = [0 handles.fovSize(1)-1];
handles.imageDisplay.YData = [0 handles.fovSize(2)-1];
handles.ImageAx.XLim = [0 handles.fovSize(1)] - 0.5;
handles.ImageAx.YLim = [0 handles.fovSize(2)] - 0.5;

% reset size of border around main image axis
XLim = handles.ImageAx.XLim;
YLim = handles.ImageAx.YLim;
handles.ImageRect.Position = [XLim(1) YLim(1) XLim(2)-XLim(1) YLim(2)-YLim(1)];

% % reset size of all preview axes
% prevAxes = {'PreviewFOVTargets_Ax' 'PreviewFOVGalvo_Ax' ...
%             'PreviewSLMTargets_Ax' 'PreviewPhaseMask_Ax'}; 
% for a = 1:numel(prevAxes)
%     handles.(prevAxes{a}).XLim = [0,handles.fovSize(2)-1];
%     handles.(prevAxes{a}).YLim = [0,handles.fovSize(1)-1];
%     im = findobj(handles.PreviewFOVGalvo_Ax,'Type','Image');
%     im.CData = ones(handles.fovSize(1),handles.fovSize(2));
%     im.AlphaData = nan(handles.fovSize(1),handles.fovSize(2));
% end


function img = normalise(img)
% normalise image data to range [0 1]
img = img - min(img(:));
img = img / max(img(:));


% --- Executes during object creation, after setting all properties.
function SelectImage_Popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SelectImage_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Reset_Pushbutton.
function Reset_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Reset_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get current image index
index = handles.SelectImage_Popup.Value;

% reset the image
handles.allImagesProcessed{index} = handles.allImagesRaw{index};
guidata(handles.output, handles)

% update display
changeImage(handles)


% --- Executes on button press in Blur_Pushbutton.
function Blur_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Blur_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get current image
index = handles.SelectImage_Popup.Value;
img = handles.allImagesProcessed{index};
editedImg = img;

% apply filter
editedImg(:,:,handles.CurrentZPlane) = imgaussfilt(img(:,:,handles.CurrentZPlane), 1);
% editedImg = medfilt2(img);

% save the edited image
handles.allImagesProcessed{index} = editedImg;
guidata(handles.output, handles)

% update display
changeImage(handles)


% --- Executes on button press in Sharpen_Pushbutton.
function Sharpen_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Sharpen_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get current image
index = handles.SelectImage_Popup.Value;
img = handles.allImagesProcessed{index};
editedImg = img;

% apply filter
orig = img(:,:,handles.CurrentZPlane);
temp = imsharpen(orig, 'radius',3, 'amount',0.8, 'threshold',0.0);
editedImg(:,:,handles.CurrentZPlane) = temp;

% save the edited image
handles.allImagesProcessed{index} = editedImg;
guidata(handles.output, handles)

% update display
changeImage(handles)


% --- Executes on button press in Contrast_Pushbutton.
function Contrast_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Contrast_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get current image
index = handles.SelectImage_Popup.Value;
img = handles.allImagesProcessed{index};
editedImg = img;

% apply filter
editedImg(:,:,handles.CurrentZPlane) = double(localcontrast(single(img(:,:,handles.CurrentZPlane))));
% editedImg = adapthisteq(img);

% save the edited image
handles.allImagesProcessed{index} = editedImg;
guidata(handles.output, handles)

% update display
changeImage(handles)




% --- Executes on selection change in LUT_PopupMenu.
function LUT_PopupMenu_Callback(hObject, eventdata, handles)
% hObject    handle to LUT_PopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns LUT_PopupMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LUT_PopupMenu
ColormapIdx = handles.LUT_PopupMenu.Value;
ColormapName = handles.LUT_PopupMenu.String{ColormapIdx};
if strcmpi(ColormapName, 'Inverted')
    cmap = makeColormap([1 1 1; 0 0 0], 256);
    colormap(handles.ImageAx, cmap);
elseif strcmpi(ColormapName, 'rwb')
    cmap = makeColormap([0 0 1; 1 1 1; 1 0 0], 256);
    colormap(handles.ImageAx, cmap);
elseif strcmpi(ColormapName, 'red')
    cmap = makeColormap([0 0 0; 1 0 0], 256);
    colormap(handles.ImageAx, cmap);
elseif strcmpi(ColormapName, 'red_white')
    cmap = makeColormap([1 1 1; 1 0 0], 256);
    colormap(handles.ImageAx, cmap);
elseif strcmpi(ColormapName, 'blue')
    cmap = makeColormap([0 0 0; 0 0 1], 256);
    colormap(handles.ImageAx, cmap);
elseif strcmpi(ColormapName, 'blue_white')
    cmap = makeColormap([1 1 1; 0 0 1], 256);
    colormap(handles.ImageAx, cmap);
else
    colormap(handles.ImageAx, ColormapName);
end



% --------------------------------------------------------------------
function File_Callback(hObject, eventdata, handles)
% hObject    handle to File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ResetAll_Callback(hObject, eventdata, handles)
% hObject    handle to ResetAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% Drag-N-Drop callback function
function DragNDropFcn(~,evt)
% some clunky evalin base required to work.

handles = evalin('base', 'guidata(NaparmFig);');

FullPaths = sort(evt.Data);

% group all images with Plane in name
if ~all(contains(FullPaths,'_Plane'))
    for n = 1:numel(FullPaths)
        FullPath = FullPaths{n};
        %     disp([num2str(n) ' ' FullPath]);
        handles = loadImage(handles, FullPath);
    end
else
    handles = loadImage(handles, FullPaths);
end

% Update handles structure
guidata(handles.output, handles);


function MouseClickAxes(h, e)
handles = guidata(h);
if ~handles.Lasso_ToggleButton.Value
    switch get(handles.output, 'SelectionType')
        case 'normal' % Click left mouse button.
            AddPoint([],[], handles);
            %         CurrentPoint = handles.points.Counter;  % coutner and points aren;t updated until click is released.
            %         handles.output.WindowButtonMotionFcn = {@MouseDrag, h, CurrentPoint+1};
            %         handles.output.WindowButtonUpFcn = {@MouseRelease, h};
    end
end


function CurrentPoint = FindClosestPoint(handles)
[currentX,currentY] = getXY(handles);
currentCoord = [currentX,currentY];
allX = handles.points.X;
allY = handles.points.Y;
allCoords = [allX;allY]';
distances = sqrt(sum(bsxfun(@minus, allCoords, currentCoord).^2,2));
[~, CurrentPoint] = min(distances);


function MouseClickPoint(h, e)
handles = guidata(h);
fig = handles.output;

% find closest point to mouse click
CurrentPoint = FindClosestPoint(handles);

switch get(handles.output,'SelectionType')
    case 'normal'  % Left click
        handles.output.WindowButtonMotionFcn = {@MouseDrag, h, CurrentPoint};
        handles.output.WindowButtonUpFcn = {@MouseRelease, h};
        
    case 'alt'  % Right click
        pause(0.05)
        deletePoint(handles, CurrentPoint)
        
        % refresh handles
        handles = guidata(h);
        
        % replot
        if any(handles.points.Group)
            handles = ComputeGroupCentroids(handles, []);
            handles = PlotClusterLines(handles, []);
        end
        
        % save
        guidata(handles.output, handles);
end

function deletePoint(handles, CurrentPoint)

idx = find(handles.points.Idx == CurrentPoint);

% reset indices of points after the one to be deleted
if idx+1 <= numel(handles.points.X)
    handles.points.Idx(idx+1:end) = handles.points.Idx(idx+1:end)-1;
end

% remove all attributes of deleted point
handles.points.X(idx) = [];
handles.points.Y(idx) = [];
handles.points.Z(idx) = [];
handles.points.Zum(idx) = [];
handles.points.OffsetX(idx) = [];
handles.points.OffsetY(idx) = [];
handles.points.Idx(idx) = [];
handles.points.Img(idx) = [];
handles.points.Group(idx) = [];
handles.points.GroupCentroidX(idx) = [];
handles.points.GroupCentroidY(idx) = [];
handles.points.Weight(idx) = [];
handles.points.Selected(idx) = [];

% delete the graphics object
handles.points.h.XData(idx) = [];
handles.points.h.YData(idx) = [];
handles.points.h.CData(idx,:) = [];

% update counter
handles.points.Counter = numel(handles.points.X);
handles.PointsCounter_Text.String = [num2str(handles.points.Counter) ' (' num2str(sum(handles.points.Z==handles.CurrentZPlane)) ')'];

% update gui table
updatePointsTable(handles);

% update num groups and group size inputs
useGroupSize = handles.GroupSize_RadioButton.Value;
if useGroupSize
    AutoGroupSize_Edit_Callback([],[],handles);
else
    AutoNumGroups_Edit_Callback([],[],handles);
end

% save
guidata(handles.output, handles);


function MouseDrag(h,e,src, CurrentPoint)
% called when dragging mouse after clicking

handles = guidata(h);
[x,y] = getXY(handles);

if strcmpi((class(src)), 'matlab.graphics.chart.primitive.Scatter')
    % set new data
    src.XData(CurrentPoint) = x;
    src.YData(CurrentPoint) = y;
    
    % update values and table
    handles.points.X(CurrentPoint) = x;
    handles.points.Y(CurrentPoint) = y;
    updatePointsTable(handles);
    if ~isnan(handles.points.Group(CurrentPoint))
        handles = ComputeGroupCentroids(handles, CurrentPoint);
        handles = PlotClusterLines(handles, CurrentPoint);
    end
    guidata(handles.output, handles);
end


function MouseMove(h,e)
% Updates the cursor location text. Called whenever mouse is moving
handles = guidata(h);
[x,y] = getXY(handles);


function [x,y] = getXY(handles)
coords = get(handles.ImageAx,'currentpoint');
x = round(coords(1,1,1));
y = round(coords(1,2,1));

% set edge limit
if x < 0
    x = 0;
elseif x > handles.ImageAx.XLim(2)-0.5
    x = handles.ImageAx.XLim(2)-0.5;
end
if y < 0
    y = 0;
elseif y > handles.ImageAx.YLim(2)-0.5
    y = handles.ImageAx.YLim(2)-0.5;
end

handles.CursorLocation_Text.String = ['X:' num2str(x) ', Y:' num2str(y)];



function MouseRelease(fig,ev,src)
fig.WindowButtonMotionFcn = @MouseMove;
fig.WindowButtonUpFcn = '';


function AddPoint(x, y, handles)
% get mouse click coordinates in not provided
if isempty(x) || isempty(y)
    [x,y] = getXY(handles);
end

% new point index
CurrentPointIdx = [numel(handles.points.X)+1 : numel(handles.points.X)+numel(x)];

% get old data, add new point, set new plot data
oldXData = handles.points.h.XData;
oldYData = handles.points.h.YData;
oldCData = handles.points.h.CData;
if ~numel(oldXData) > 0
    oldCData = [];
end
newXData = [oldXData, x'];
newYData = [oldYData, y'];
newCData = [oldCData; ones(numel(x),3)];

handles.points.h.XData = newXData;
handles.points.h.YData = newYData;
handles.points.h.CData = newCData;

currentZPlane = handles.CurrentZPlane;
focalPlane = str2double(handles.FocalPlane_edit.String);
planeSpacing = str2double(handles.PlaneSpacing_edit.String);

% update points record
handles.points.Idx(CurrentPointIdx) = CurrentPointIdx;
handles.points.X(CurrentPointIdx) = x;
handles.points.Y(CurrentPointIdx) = y;
handles.points.Z(CurrentPointIdx) = currentZPlane;
handles.points.Zum(CurrentPointIdx) = (currentZPlane - focalPlane) * planeSpacing;
handles.points.OffsetX(CurrentPointIdx) = NaN;
handles.points.OffsetY(CurrentPointIdx) = NaN;
handles.points.Group(CurrentPointIdx) = NaN;
handles.points.GroupCentroidX(CurrentPointIdx) = NaN;
handles.points.GroupCentroidY(CurrentPointIdx) = NaN;
handles.points.Img(CurrentPointIdx) = handles.SelectImage_Popup.Value;
handles.points.Weight(CurrentPointIdx) = 1;
handles.points.Selected(CurrentPointIdx) = 0;

% update counter
handles.points.Counter = CurrentPointIdx(end);
handles.PointsCounter_Text.String = num2str(CurrentPointIdx(end));

% update gui table
updatePointsTable(handles);

% update num groups and group size inputs
useGroupSize = handles.GroupSize_RadioButton.Value;
if useGroupSize
    AutoGroupSize_Edit_Callback([],[],handles);
else
    AutoNumGroups_Edit_Callback([],[],handles);
end

% save
guidata(handles.output, handles);



function updatePointsTable(handles)
% columns: x,y,image,group,offsetx,offsety,groupx,groupy,weight

% make data array
p = handles.points;
data = [p.X; p.Y; p.Z; p.Zum; p.Group; p.Img; p.OffsetX; p.OffsetY; p.GroupCentroidX; p.GroupCentroidY; p.Weight]';

% set table data
handles.PointsTable.Data = data;

handles.PointsCounter_Text.String = [num2str(handles.points.Counter) ' (' num2str(sum(handles.points.Z==handles.CurrentZPlane)) ')'];


% save
guidata(handles.output, handles);


% --- Executes on button press in AutoGroup_Pushbutton.
function AutoGroup_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to AutoGroup_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('Grouping...')

onlyGroupWithinPlane = handles.OnlyGroupWithinPlane_checkbox.Value;


useGroupSize = handles.GroupSize_RadioButton.Value;
if useGroupSize
    GroupSize = str2double(handles.AutoGroupSize_Edit.String);
    NumGroups = handles.points.Counter / GroupSize;
else
    NumGroups = str2double(handles.AutoNumGroups_Edit.String);
    GroupSize = handles.points.Counter / NumGroups;
end

handles.AutoNumGroups_Edit.String = num2str(NumGroups);
handles.AutoGroupSize_Edit.String = num2str(GroupSize);
if ceil(NumGroups) ~= floor(NumGroups)  % test if integer
    handles.AutoNumGroups_Edit.BackgroundColor = [1 0.9 0.9];
    handles.AutoNumGroups_Edit.ForegroundColor = 'r';
else
    handles.AutoNumGroups_Edit.BackgroundColor = 'w';
    handles.AutoNumGroups_Edit.ForegroundColor = 'k';
end

if ceil(GroupSize) ~= floor(GroupSize)  % test if integer
    handles.AutoGroupSize_Edit.BackgroundColor = [1 0.9 0.9];
    handles.AutoGroupSize_Edit.ForegroundColor = 'r';
else
    handles.AutoGroupSize_Edit.BackgroundColor = 'w';
    handles.AutoGroupSize_Edit.ForegroundColor = 'k';
end


popup_value = handles.AutoGroupMethod_PopupMenu.Value;
method = handles.AutoGroupMethod_PopupMenu.String{popup_value};

switch method
    case 'ekmeans'
        if onlyGroupWithinPlane
            planes = unique(handles.points.Z);
            numPlanes = numel(planes);
        else
            planes = 1;
            numPlanes = 1;
        end
        prevNumGroups = 0;
        for i = 1:numPlanes
            if onlyGroupWithinPlane
                zIndices = handles.points.Z==planes(i);
                thisNumGroups = sum(zIndices) / GroupSize;
            else
                zIndices = 1:handles.points.Counter;
                thisNumGroups = NumGroups;
            end
            data = [handles.points.Y; handles.points.X]';
            num_iterations = 150;
            equal = 1;
            
            [assignments,centroids,varargout] = ekmeans(data(zIndices,:), ceil(thisNumGroups), num_iterations, equal);
            handles.points.Group(zIndices) = assignments' + prevNumGroups;
            %         handles.points.GroupCentroidX = centroids(assignments,2)';
            %         handles.points.GroupCentroidY = centroids(assignments,1)';
            prevNumGroups = prevNumGroups + numel(unique(assignments));
        end
        
    case 'Random'
        %         disp('Not yet implemented (should have spatial constraints)')
        
        if onlyGroupWithinPlane
            planes = unique(handles.points.Z);
            numPlanes = numel(planes);
        else
            planes = 1;
            numPlanes = 1;
        end
        prevNumGroups = 0;
        for i = 1:numPlanes
            if onlyGroupWithinPlane
                zIndices = handles.points.Z==planes(i);
            else
                zIndices = logical(ones(1, handles.points.Counter));
            end
            
            numTargets = sum(zIndices);
            targetIDs = find(zIndices);
            shuffledTargetIDs = targetIDs(randperm(numTargets));
            numGroups = numTargets / GroupSize;
            
            % in case number targets is not divisible by group size
            extraNeeded = abs(numTargets - ceil(numTargets/GroupSize)*GroupSize);
            shuffledTargetIDs = [shuffledTargetIDs, nan(1,extraNeeded)];
            
            % grouped
            groupedIDs = reshape(shuffledTargetIDs,GroupSize,[]);
            
            % find group index
            groups = [];
            for i = 1:numTargets
                [~,groups(i)] = find(groupedIDs==targetIDs(i));
            end
            handles.points.Group(zIndices) = groups + prevNumGroups;
            prevNumGroups = prevNumGroups + numel(unique(groups));
            
        end
        
        
        
    case 'By image'
        numImages = numel(handles.allImagesRaw);
        if numImages < 1
            disp('No images')
            numImages = 1;
        end
        handles.points.Group = handles.points.Img;
        
        
    case 'Order added'
        numTargets = handles.points.Counter;
        targetIDs = 1:numTargets;
        shuffledTargetIDs = targetIDs(randperm(numTargets));
        numGroups = handles.points.Counter / GroupSize;
        
        % in case number targets is not divisible by group size
        extraNeeded = abs(numTargets - ceil(numTargets/GroupSize)*GroupSize);
        targetIDs = [targetIDs, nan(1,extraNeeded)];
        
        % grouped
        groupedIDs = reshape(targetIDs,GroupSize,[]);
        
        % find group index
        groups = [];
        for i = 1:numTargets
            [~,groups(i)] = find(groupedIDs==i);
        end
        handles.points.Group = groups;
        
end

handles = ComputeGroupCentroids(handles, []);

handles = PlotClusterLines(handles, []);

% save
updatePointsTable(handles)
guidata(handles.output, handles)

UpdateTimingPlot(hObject, eventdata, handles, false);


function handles = ComputeGroupCentroids(handles, CurrentPoint)
% calculate group centroids and offset targets
if isempty(CurrentPoint)
    groups = unique(handles.points.Group);
else
    groups = handles.points.Group(CurrentPoint);
end
numGroups = numel(groups);

for i = 1:ceil(numGroups)
    groupIndices = find(handles.points.Group==groups(i));
    
    x = handles.points.X(groupIndices)';
    y = handles.points.Y(groupIndices)';
    Points = [x y];
    [OffsetPoints, GroupCentroid] = ZOBlockAvoider(Points);
    
    handles.points.OffsetX(groupIndices) = OffsetPoints(:,1);
    handles.points.OffsetY(groupIndices) = OffsetPoints(:,2);
    handles.points.GroupCentroidX(groupIndices) = GroupCentroid(1);
    handles.points.GroupCentroidY(groupIndices) = GroupCentroid(2);
end

% --- Executes on button press in ClearAll_Pushbutton.
function ClearAll_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ClearAll_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% delete point data entries
handles.points = ResetPoints(handles.points);

% set gui string to zero
handles.PointsCounter_Text.String = num2str(handles.points.Counter);

% update table
updatePointsTable(handles)

% remove cluster/group lines if exist
if isfield(handles, 'ClusterLines')
    delete(handles.ClusterLines)
end
if isfield(handles, 'ClusterCentroids')
    delete(handles.ClusterCentroids)
end
handles.ClusterLines = [];
handles.ClusterCentroids = [];

% update num groups and group size inputs
useGroupSize = handles.GroupSize_RadioButton.Value;
if useGroupSize
    AutoGroupSize_Edit_Callback([],[],handles);
else
    AutoNumGroups_Edit_Callback([],[],handles);
end

% save
guidata(handles.output, handles);


% --- Executes on selection change in AutoFindMethod_PopupMenu.
function AutoFindMethod_PopupMenu_Callback(hObject, eventdata, handles)
% hObject    handle to AutoFindMethod_PopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns AutoFindMethod_PopupMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from AutoFindMethod_PopupMenu


% --- Executes during object creation, after setting all properties.
function AutoFindMethod_PopupMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AutoFindMethod_PopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AutoFind_Pushbutton.
function AutoFind_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to AutoFind_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get current image
index = handles.SelectImage_Popup.Value;
img = handles.allImagesProcessed{index};
if numel(handles.allImageShapes{index}) > 2
    img = img(:,:,handles.CurrentZPlane);
end

popup_value = handles.AutoFindMethod_PopupMenu.Value;
method = handles.AutoFindMethod_PopupMenu.String{popup_value};

r = str2double(handles.autoFindRadius_edit.String);


switch method
    case 'Model'
%         [x,y,normImg] = MariusCellFinder(img, 'C1V1_1_34x_512_model');
        [x,y,normImg] = MariusCellFinder(img, 'CorrImgs_4Planes_model');
        
    case 'Local maxima'
        [x,y] = FindLocalMaxima(img, r);
        
    case 'Circles'
        [x,y,normImg] = MariusCellFinder(img, 'C1V1Kv21_135x_512_model');
        %         [x,y] = FindCircles(img, r);
end
handles = guidata(hObject);  % refresh updated handles structure
AddPoint(x, y, handles);


function [x,y] = FindLocalMaxima(img, r)

thresh = r;
editedImg = img;
imSizeYX = size(img);

editedImg = medfilt2(editedImg,[1 1]);
B = imregionalmax(editedImg,8);
allPeaks = find(B);
allVals = editedImg(allPeaks);
goodPeaks = allVals >= thresh;
[y,x] = ind2sub(imSizeYX,allPeaks(goodPeaks));
y = y-1;
x = x-1;


% remove edges
toRemove = (x==1 | x==max(imSizeYX(2)) | y==1 | y==max(imSizeYX(1)));
x(toRemove) = [];
y(toRemove) = [];




function [x,y] = FindCircles(img, r)
% img = img ./ max(max(img));

% img = medfilt2(img,[3,3]);
% se = strel('disk',3);
% img = imtophat(img, se);
% img = histeq(img);
% img = imadjust(img);
%
%
% img = imtophat(img, se);
% img(img< graythresh(img)*1) = 0;
% img = imadjust(img);
% img = imgaussfilt(img,1);

img = imbinarize(img, graythresh(img)*1.1);


LB = 50;
bigObjects = bwareaopen(~img, LB);
img = double(img);
img(bigObjects) = 1;
img = double(img);



[centers, radii, metric] = imfindcircles(img,[3 6], 'ObjectPolarity','dark','Sensitivity',0.999,'EdgeThreshold',0.6, 'Method','twostage');
x = round(centers(:,1));
y = round(centers(:,2));
figure;imshow(img)

% [x,y] = FindLocalMaxima(img, r);


% --- Executes on selection change in AutoGroupMethod_PopupMenu.
function AutoGroupMethod_PopupMenu_Callback(hObject, eventdata, handles)
% hObject    handle to AutoGroupMethod_PopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns AutoGroupMethod_PopupMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from AutoGroupMethod_PopupMenu


% --- Executes during object creation, after setting all properties.
function AutoGroupMethod_PopupMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AutoGroupMethod_PopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AutoGroupSize_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to AutoGroupSize_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AutoGroupSize_Edit as text
%        str2double(get(hObject,'String')) returns contents of AutoGroupSize_Edit as a double

handles.GroupSize_RadioButton.Value = 1;

useGroupSize = handles.GroupSize_RadioButton.Value;
if useGroupSize
    GroupSize = str2double(handles.AutoGroupSize_Edit.String);
    NumGroups = handles.points.Counter / GroupSize;
else
    NumGroups = str2double(handles.AutoNumGroups_Edit.String);
    GroupSize = handles.points.Counter / NumGroups;
end

handles.AutoNumGroups_Edit.String = num2str(NumGroups);
handles.AutoGroupSize_Edit.String = num2str(GroupSize);
if ceil(NumGroups) ~= floor(NumGroups)  % test if integer
    handles.AutoNumGroups_Edit.BackgroundColor = [1 0.9 0.9];
    handles.AutoNumGroups_Edit.ForegroundColor = 'r';
else
    handles.AutoNumGroups_Edit.BackgroundColor = 'w';
    handles.AutoNumGroups_Edit.ForegroundColor = 'k';
end

if ceil(GroupSize) ~= floor(GroupSize)  % test if integer
    handles.AutoGroupSize_Edit.BackgroundColor = [1 0.9 0.9];
    handles.AutoGroupSize_Edit.ForegroundColor = 'r';
else
    handles.AutoGroupSize_Edit.BackgroundColor = 'w';
    handles.AutoGroupSize_Edit.ForegroundColor = 'k';
end





% --- Executes during object creation, after setting all properties.
function AutoGroupSize_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AutoGroupSize_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in RemoveBackground_Pushbutton.
function RemoveBackground_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to RemoveBackground_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get current image
index = handles.SelectImage_Popup.Value;
img = handles.allImagesProcessed{index};
editedImg = img;

% apply filter
orig = img(:,:,handles.CurrentZPlane);
se = strel('disk',21);
temp = imtophat(orig, se);
% temp = imgaussfilt(orig, [5 5]);
% temp = orig ./ temp;
% temp = orig .* temp;

editedImg(:,:,handles.CurrentZPlane) = temp;

% save the edited image
handles.allImagesProcessed{index} = editedImg;
guidata(handles.output, handles)

% update display
changeImage(handles)


% --- Executes on button press in Denoise_Pushbutton.
function Denoise_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Denoise_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get current image
index = handles.SelectImage_Popup.Value;
img = handles.allImagesProcessed{index};
editedImg = img;



if numel(size(img))>3  % means colour img
    for c = 1:3
    % apply filterlocal
% editedImg = wiener2(img, [5 5]);
orig = img(:,:,handles.CurrentZPlane,c);
temp = medfilt2(orig,[3,3]);
temp = orig - temp;
temp = orig - temp;
% temp = temp .* orig;

editedImg(:,:,handles.CurrentZPlane,c) = temp;
    end
else
% apply filterlocal
% editedImg = wiener2(img, [5 5]);
orig = img(:,:,handles.CurrentZPlane);
temp = medfilt2(orig,[3,3]);
temp = orig - temp;
temp = orig - temp;
% temp = temp .* orig;

editedImg(:,:,handles.CurrentZPlane) = temp;
end
% save the edited image
handles.allImagesProcessed{index} = editedImg;
guidata(handles.output, handles)

% update display
changeImage(handles)



function AutoNumGroups_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to AutoNumGroups_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AutoNumGroups_Edit as text
%        str2double(get(hObject,'String')) returns contents of AutoNumGroups_Edit as a double

handles.NumberGroups_RadioButton.Value = 1;

useGroupSize = handles.GroupSize_RadioButton.Value;
if useGroupSize
    GroupSize = str2double(handles.AutoGroupSize_Edit.String);
    NumGroups = handles.points.Counter / GroupSize;
else
    NumGroups = str2double(handles.AutoNumGroups_Edit.String);
    GroupSize = handles.points.Counter / NumGroups;
end

handles.AutoNumGroups_Edit.String = num2str(NumGroups);
handles.AutoGroupSize_Edit.String = num2str(GroupSize);
if ceil(NumGroups) ~= floor(NumGroups)  % test if integer
    handles.AutoNumGroups_Edit.BackgroundColor = [1 0.9 0.9];
    handles.AutoNumGroups_Edit.ForegroundColor = 'r';
else
    handles.AutoNumGroups_Edit.BackgroundColor = 'w';
    handles.AutoNumGroups_Edit.ForegroundColor = 'k';
end

if ceil(GroupSize) ~= floor(GroupSize)  % test if integer
    handles.AutoGroupSize_Edit.BackgroundColor = [1 0.9 0.9];
    handles.AutoGroupSize_Edit.ForegroundColor = 'r';
else
    handles.AutoGroupSize_Edit.BackgroundColor = 'w';
    handles.AutoGroupSize_Edit.ForegroundColor = 'k';
end




% --- Executes during object creation, after setting all properties.
function AutoNumGroups_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AutoNumGroups_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ClearPointsImage.
function ClearPointsImage_Callback(hObject, eventdata, handles)
% hObject    handle to ClearPointsImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

currentImage = handles.SelectImage_Popup.Value;
groupIndices = find(handles.points.Img==currentImage);
for i = fliplr(groupIndices)  % flip so delete last one first
    handles = guidata(hObject);  % get updated guidata
    deletePoint(handles, i)
end


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox2


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% fig = hObject;
% FigurePosition = get(fig, 'Position');
% currentWidth = round(FigurePosition(3));
% % currentHeight = FigurePosition(4);
%
% targetHeight = round(currentWidth / handles.AspectRatioGUI);
% % targetWidth = currentWidth / handles.AspectRatioGUI;
%
%     set(fig, 'Position', [FigurePosition(1), FigurePosition(2), currentWidth, targetHeight]);
%     drawnow();


% --- Executes on selection change in GroupOrderingMethod.
function GroupOrderingMethod_Callback(hObject, eventdata, handles)
% hObject    handle to GroupOrderingMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GroupOrderingMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GroupOrderingMethod






% --- Executes during object creation, after setting all properties.
function GroupOrderingMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GroupOrderingMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SaveCurrentImage.
function SaveCurrentImage_Callback(hObject, eventdata, handles)
% hObject    handle to SaveCurrentImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get current image
index = handles.SelectImage_Popup.Value;
img = handles.allImagesProcessed{index};
name = handles.SelectImage_Popup.String{index};
%imwrite(img, [name '_EDITED.tif']); % HWPD 20200724
TiffWriter(int16(img),[name '_EDITED.tif'],16); % HWPD 20200724


% --- Executes on button press in CleanUpPoints_Pushbutton.
function CleanUpPoints_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to CleanUpPoints_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% points within 'thresh' of another point will be removed.
% priority to remain and not be deleted is given to the earlier

thresh = 4;

showAllPoints = handles.ShowAllPoints_checkbox.Value;
if ~showAllPoints
    zIndices = find(handles.points.Z == handles.CurrentZPlane);
else
    zIndices = 1:handles.points.Counter;
end



x = handles.points.X(zIndices);
y = handles.points.Y(zIndices);
data = [x;y]';

% calculate pairwise distances of all points
pairwiseDistances = sqrt(bsxfun(@minus,data(:,1),data(:,1)').^2 +...
    bsxfun(@minus,data(:,2),data(:,2)').^2);

% keep only lower trianguilar part of matrix (giving priority to early points)
N = numel(x);
for n = 1:N
    % keep lower triagle (to allow prioritising of early/late points)
    pairwiseDistances(n,n:N) = NaN;
end

% find those within threshold distance
pairwiseDistances = pairwiseDistances<thresh;

% get the indices
anyDimension = 2;  % this determines early or late point priority 1=late,
indices = find(any(pairwiseDistances, anyDimension))';
indices = fliplr(indices);  % flip so that last point is removed first for array indexing reasoning
indices = zIndices(indices);

% go through and delete all points
for idx = indices
    handles = guidata(hObject);  % update handles
    %     set(handles.points.h(idx), 'MarkerEdgeColor', 'c');
    deletePoint(handles, idx)
end



function handles = PlotClusterLines(handles, CurrentPoint)
% show all points/lines or just those in plane?

cellsWithGroup = ~isnan(handles.points.Group);
numGroups = numel(unique(handles.points.Group(cellsWithGroup)));
numCellsWithGroup = sum(cellsWithGroup);

% get group lut
groupLUTindex = handles.GroupLUT_PopupMenu.Value;
selectedCmap = handles.GroupLUT_PopupMenu.String{groupLUTindex};
colours = eval([lower(selectedCmap) '(numGroups)']);

% pointColours = ones(handles.points.Counter,3);
NewPointColour = lower(handles.NewPointColour_Edit.String);
NewPointColour = strrep(NewPointColour,'[','');
NewPointColour = strrep(NewPointColour,']','');
NewPointColour = strsplit(NewPointColour, ',');
NewPointColour = str2double(NewPointColour);

pointColours = repmat(NewPointColour, handles.points.Counter,1);

showAllPoints = handles.ShowAllPoints_checkbox.Value;
if ~showAllPoints
    zIndices = handles.points.Z == handles.CurrentZPlane;
else
    zIndices = 1:handles.points.Counter;
end
pointColours(~zIndices,:) = nan;

% init
if isempty(CurrentPoint)
    if isfield(handles, 'ClusterLines')
        delete(handles.ClusterLines)
    end
    handles.ClusterLines = [];
end

% get plot style
index = handles.GroupPlotStyle_PopupMenu.Value;
plotStyle = handles.GroupPlotStyle_PopupMenu.String{index};

switch plotStyle
    case 'Stars'
        for i = 1:numGroups
            colour = colours(i,:);
            groupIndices = find(handles.points.Group==i & zIndices);
            pointColours(groupIndices,:) = repmat(colour,numel(groupIndices),1);
            if isempty(CurrentPoint) || any(groupIndices==CurrentPoint)
                x = handles.points.X(groupIndices);
                y = handles.points.Y(groupIndices);
                groupX = handles.points.GroupCentroidX(groupIndices);
                groupY = handles.points.GroupCentroidY(groupIndices);
                if CurrentPoint
                    if isfield(handles, 'ClusterLines')
                        delete(handles.ClusterLines(i))
                    end
                end
                if ~isempty(x)
                    handles.ClusterLines(i) = plot(handles.ImageAx,...
                        reshape([x;groupX], 1, []),...
                        reshape([y;groupY], 1, []),...
                        'color',colour, 'linewidth',1, 'linestyle', '-');
                end
            end
        end
        
    case 'Boundaries'
        for i = 1:numGroups
            colour = colours(i,:);
            groupIndices = find(handles.points.Group==i & zIndices);
            groupIndices2 = find(handles.points.Group==i);
            pointColours(groupIndices,:) = repmat(colour,numel(groupIndices),1);
            if isempty(CurrentPoint) || any(groupIndices==CurrentPoint)
                x = handles.points.X(groupIndices);
                x2 = handles.points.X(groupIndices2);
                y = handles.points.Y(groupIndices2);
                if ~isempty(x)
                    k = boundary(x2',y',0.25);
                    if CurrentPoint
                        if isfield(handles, 'ClusterLines')
                            delete(handles.ClusterLines(i))
                        end
                    end
                    handles.ClusterLines(i) = fill(handles.ImageAx, x2(k), y(k), colour, 'edgecolor',colour, 'linewidth',1, 'linestyle',':', 'facealpha',0.2);
                end
            end
        end
        
    case 'Coloured'
        for i = 1:numGroups
            colour = colours(i,:);
            groupIndices = find(handles.points.Group==i & zIndices);
            pointColours(groupIndices,:) = repmat(colour,numel(groupIndices),1);
        end
end

handles.points.h.CData = pointColours;

% plot centroids
if isfield(handles, 'ClusterCentroids')
    delete(handles.ClusterCentroids)
end
handles.ClusterCentroids = [];
for i = 1:numGroups
    colour = colours(i,:);
    idx = find(handles.points.Group==i & zIndices, 1);
    x = handles.points.GroupCentroidX(idx);
    y = handles.points.GroupCentroidY(idx);
    if ~isempty(x)
        handles.ClusterCentroids(i) = text(handles.ImageAx, x, y, num2str(i),...
            'Color','k','FontSize',12, 'fontweight','bold', 'backgroundcolor',colour, 'horizontalalignment','center');
    end
    %     'marker','s', 'markersize',10
end

% % bring points back to top of plot - SLOW!
% for i = 1:handles.points.Counter
%     uistack(handles.points.h, 'top')
% end

% save
guidata(handles.output, handles);



% --- Executes on button press in GroupOrder_Pushbutton.
function GroupOrder_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to GroupOrder_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

popup_value = handles.GroupOrderingMethod.Value;
method = handles.GroupOrderingMethod.String{popup_value};

groups = unique(handles.points.Group);
numGroups = numel(groups);
for i = groups
    idx = find(handles.points.Group==i, 1);
    groupXs(i) = mean(handles.points.X(idx));
    groupYs(i) = mean(handles.points.Y(idx));
end
combinedXY = [groupXs; groupYs]';

switch method
    case 'Default'
        disp('doing nothing')
    case 'Random'
        sortedGroupIndex = randperm(numGroups);
        
        % do the sorting
        for i = 1:handles.points.Counter
            oldGroup = handles.points.Group(i);
            newGroup = find(sortedGroupIndex==handles.points.Group(i));
            handles.points.Group(i) = newGroup;
        end
        
    case 'Top-bottom'
        [~,sortedGroupIndex] = sortrows(combinedXY, [2 1]);
        
        % do the sorting
        for i = 1:handles.points.Counter
            oldGroup = handles.points.Group(i);
            newGroup = find(sortedGroupIndex==handles.points.Group(i));
            handles.points.Group(i) = newGroup;
        end
        
    case 'Left-right'
        [~,sortedGroupIndex] = sortrows(combinedXY, [1 2]);
        
        % do the sorting
        for i = 1:handles.points.Counter
            oldGroup = handles.points.Group(i);
            newGroup = find(sortedGroupIndex==handles.points.Group(i));
            handles.points.Group(i) = newGroup;
        end
        
    case 'Custom'
        groupNum = inputdlg('Custom group order:', 'Input', 1, {''});
        sortedGroupIndex = str2num(groupNum{1});
        for i = 1:handles.points.Counter
            oldGroup = handles.points.Group(i);
            newGroup = find(sortedGroupIndex==handles.points.Group(i));
            handles.points.Group(i) = newGroup;
        end
end

% replot
handles = PlotClusterLines(handles, []);

% update gui table
updatePointsTable(handles);

% save
guidata(handles.output, handles);


% --- Executes on button press in ExportPoints_pushbutton.
function ExportPoints_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ExportPoints_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SavePointsFile(handles)


% --- Executes during object creation, after setting all properties.
function GroupOrder_Pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GroupOrder_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on selection change in GroupPlotStyle_PopupMenu.
function GroupPlotStyle_PopupMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GroupPlotStyle_PopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GroupPlotStyle_PopupMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GroupPlotStyle_PopupMenu

% replot
handles = PlotClusterLines(handles, []);

% save
guidata(handles.output, handles);



% --- Executes during object creation, after setting all properties.
function GroupPlotStyle_PopupMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GroupPlotStyle_PopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ResetAll_Menu_Callback(hObject, eventdata, handles)
% hObject    handle to ResetAll_Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(gcf)
Naparm3()

% --------------------------------------------------------------------
function Untitled_4_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in GroupLUT_PopupMenu.
function GroupLUT_PopupMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GroupLUT_PopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GroupLUT_PopupMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GroupLUT_PopupMenu

% replot
handles = PlotClusterLines(handles, []);
UpdateTimingPlot(hObject, eventdata, handles, false);

% save
guidata(handles.output, handles);


% --- Executes during object creation, after setting all properties.
function GroupLUT_PopupMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GroupLUT_PopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Preview_Pushbutton.
function Preview_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Preview_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('Preview: Making images...')
handles = MakeTargets(handles, false);
handles = MakePhaseMasks(handles, false);

% save
guidata(handles.output, handles);

disp('Preview: Playing...')
ShowPreview(handles)


function ShowPreview(handles)

NumSequenceReps = str2double(handles.SequenceRepetitions_Edit.String);
NumGroups = numel(unique(handles.points.Group));

% update all targets plot
handles.PreviewFOVTargetsALL_Scatter.XData = handles.points.X;
handles.PreviewFOVTargetsALL_Scatter.YData = handles.points.Y;
handles.PreviewFOVTargetsALL_Scatter.ZData = handles.points.Zum;
if numel(unique(handles.points.Zum)) > 1
    view(handles.PreviewFOVTargets_Ax, 45,45)
    view(handles.PreviewSLMTargets_Ax, 45,45)
    view(handles.PreviewFOVGalvo_Ax, 45,45)
    handles.PreviewSLMTargets_Ax.ZLim = [min([handles.points.Zum 0]) max([handles.points.Zum 0])];
else
    view(handles.PreviewFOVTargets_Ax, 0,90)    
    view(handles.PreviewSLMTargets_Ax, 0,90)  
    view(handles.PreviewFOVGalvo_Ax, 0,90)
end

% update all galvo positions plot
handles.PreviewFOVGalvoALL_Scatter.XData = handles.GalvoPositions(:,1);
handles.PreviewFOVGalvoALL_Scatter.YData = handles.GalvoPositions(:,2);


% get colormap
groupLUTindex = handles.GroupLUT_PopupMenu.Value;
selectedCmap = handles.GroupLUT_PopupMenu.String{groupLUTindex};
colours = eval([lower(selectedCmap) '(NumGroups)']);

for i = 1:NumSequenceReps
    for j = 1:NumGroups
        % Get images
        FOVtargets = handles.FOVtargets{j};
        GalvoPositions = handles.GalvoPositions(j,:);
        SLMtargets = handles.SLMtargets{j};
        PhaseMask = double(handles.PhaseMasks{j});
        
        % plot
        handles.PreviewFOVTargets_Scatter.XData = FOVtargets(:,1);
        handles.PreviewFOVTargets_Scatter.YData = FOVtargets(:,2);
        handles.PreviewFOVTargets_Scatter.ZData = FOVtargets(:,3);
        handles.PreviewFOVTargets_Scatter.Color = colours(j,:);
        handles.PreviewFOVGalvo_Scatter.XData = GalvoPositions(1);
        handles.PreviewFOVGalvo_Scatter.YData = GalvoPositions(2);
        handles.PreviewSLMTargets_Scatter.XData = SLMtargets(:,1);
        handles.PreviewSLMTargets_Scatter.YData = SLMtargets(:,2);
        handles.PreviewSLMTargets_Scatter.ZData = SLMtargets(:,3);
        handles.PreviewPhaseMask_Im.CData = PhaseMask / max(PhaseMask(:));
        
        if NumSequenceReps > 1
            handles.PreviewPatternNumber_Text.String = ['Pattern ' num2str(j) ' of ' num2str(NumGroups) '. Repeat ' num2str(i) ' of ' num2str(NumSequenceReps)];
        else
            handles.PreviewPatternNumber_Text.String = ['Pattern ' num2str(j) ' of ' num2str(NumGroups)];
        end
        
        pause(0.075)
    end
end


% --- Executes on button press in ExportAll_Pushbutton.
function ExportAll_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ExportAll_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Set up directories
% auto increment expt number
contents = dir([handles.data.Path filesep handles.ExperimentName_Edit.String '*']);
Iter = str2double(handles.ExperimentNum_Edit.String);
if ~isempty(contents)
    names = {contents.name};
    for i = 1:numel(names)
        ExptID = str2double(names{i}(end-2:end));
        if ExptID >= Iter
            Iter = ExptID + 1;
        end
    end
end
handles.ExperimentNum_Edit.String = num2str(Iter);
handles.data.ExperimentIdentifier = [handles.ExperimentName_Edit.String '_' num2str(Iter, '%03d')];
NaparmDirectory = [handles.data.Path filesep handles.data.ExperimentIdentifier];
handles.data.NaparmDirectory = NaparmDirectory;

disp(['Saving to: ' NaparmDirectory ' ...'])

mkdir([NaparmDirectory filesep 'Images'])
mkdir([NaparmDirectory filesep 'Targets'])
mkdir([NaparmDirectory filesep 'PhaseMasks'])
mkdir([NaparmDirectory filesep 'PhaseMasks' filesep 'InputTargets'])
mkdir([NaparmDirectory filesep 'PhaseMasks' filesep 'TransformedTargets'])

handles = MakeTargets(handles, true);
SaveImages(handles);
handles = OutputConfigs(handles); % HWPD allows users to add their own outputs
UpdateTimingPlot(hObject, eventdata, handles, true);
SaveParameterFile(handles);
SavePointsFile(handles)

disp(['Saved to: ' NaparmDirectory])

ShowPreview(handles)

handles.ExperimentNum_Edit.String = num2str(Iter+1);



function handles = MakeTargets(handles, SaveResult)

handles.points.Weight(isnan(handles.points.Weight)) = 1;
blankImg = zeros(handles.fovSize(1),handles.fovSize(2));
numGroups = numel(unique(handles.points.Group));
planes = unique(handles.points.Z);
numPlanes = numel(planes);


FOVtargets = cell(numGroups,1);
SLMtargets = cell(numGroups,1);
GalvoPositions = zeros(numGroups, 2);

FOVTargetImages = cell(numGroups,1);
SLMTargetImages = cell(numGroups,1);
GalvoPositionImages = cell(numGroups,1);
FOVTargetImages_byPlane = cell(numGroups,numPlanes);


for i = 1:ceil(numGroups)
    groupIndices = find(handles.points.Group==i);
    
    % FOV targets
    x = handles.points.X(groupIndices);
    y = handles.points.Y(groupIndices);
    z = handles.points.Zum(groupIndices);
    z2 = handles.points.Z(groupIndices);
    weights = handles.points.Weight(groupIndices);
    FOVtargets{i} = [x;y;z;weights]';
    xyIndices = sub2ind(size(blankImg), round(y), round(x));
    FOVTargetImages{i} = blankImg;
    FOVTargetImages{i}(xyIndices) = weights;
    
    for p = 1:numPlanes
        thesePoints = z2==p;
        FOVTargetImages_byPlane{i,p} = blankImg;
        xyIndices = sub2ind(size(blankImg), round(y(thesePoints)), round(x(thesePoints)));
        FOVTargetImages_byPlane{i,p}(xyIndices) = weights(thesePoints);
    end
    
    % SLM targets
    if handles.OffsetGalvos_Checkbox.Value
        x = handles.points.OffsetX(groupIndices);
        y = handles.points.OffsetY(groupIndices);
    else
        x = handles.points.X(groupIndices);
        y = handles.points.Y(groupIndices);
    end
    z = handles.points.Zum(groupIndices);
    weights = handles.points.Weight(groupIndices);
    SLMtargets{i} = [x;y;z;weights]';
    
    xyIndices = sub2ind(size(blankImg), round(y), round(x));
    SLMTargetImages{i} = blankImg;
    SLMTargetImages{i}(xyIndices) = weights;
    
    % Galvo positions
    if handles.OffsetGalvos_Checkbox.Value
        x = handles.points.GroupCentroidX(groupIndices(1));
        y = handles.points.GroupCentroidY(groupIndices(1));
    else
        x = round(handles.fovCntr(2));
        y = round(handles.fovCntr(1));
    end
    GalvoPositions(i,:) = [x,y];
    GalvoPositionImages{i} = blankImg;
    GalvoPositionImages{i}(y,x) = 1;
end

handles.FOVtargets = FOVtargets;
handles.FOVTargetImages = FOVTargetImages;
handles.SLMtargets = SLMtargets;
handles.SLMTargetImages = SLMTargetImages;
handles.GalvoPositions = GalvoPositions;
handles.GalvoPositionImages = GalvoPositionImages;
handles.FOVTargetImages_byPlane = FOVTargetImages_byPlane;

% Update handles structure
guidata(handles.output, handles);

if SaveResult
    % save images out...
end



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


% --- Executes on button press in OffsetGalvos_Checkbox.
function OffsetGalvos_Checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to OffsetGalvos_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OffsetGalvos_Checkbox



% --- Executes on button press in ComputePhaseMasks_Checkbox.
function ComputePhaseMasks_Checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to ComputePhaseMasks_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ComputePhaseMasks_Checkbox



% --- Executes on button press in SetSaveDirectory_Pushbutton.
function SetSaveDirectory_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to SetSaveDirectory_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

PathName = uigetdir('Select the save directory');
handles.data.Path = PathName;

% change directory
cd(PathName);

% Update handles structure
guidata(hObject, handles);



function ExperimentName_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to ExperimentName_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ExperimentName_Edit as text
%        str2double(get(hObject,'String')) returns contents of ExperimentName_Edit as a double



% --- Executes during object creation, after setting all properties.
function ExperimentName_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExperimentName_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function UpdateTimingPlot(hObject, eventdata, handles, varargin)
NumPatterns = numel(unique(handles.points.Group));

InitialDelay = str2double(handles.InitialDelay_Edit.String);
SpiralDuration = str2double(handles.SpiralDuration_Edit.String);
ChangePatternEvery = str2double(handles.ChangePatternEvery_Edit.String);
ShotsPerPattern = str2double(handles.ShotsPerPattern_Edit.String);
InterPatternShotInterval = str2double(handles.InterPatternShotInterval_Edit.String);
SequenceRepetitions = str2double(handles.SequenceRepetitions_Edit.String);
SequenceRepetitionInterval = str2double(handles.SequenceRepetitionInterval_Edit.String);
NumberOfTrials = str2double(handles.NumberOfTrials_Edit.String);
TrialInterval = str2double(handles.TrialInterval_Edit.String);
% IntervalStartsAtEnd = handles.FromStimStartStop_ToggleButton.Value;
SampleRateHz = str2double(handles.OutputHz_Edit.String);
TrigOnEvery = handles.TriggerEach_ToggleButton.Value;
SpontPre = str2double(handles.SpontPre_Edit.String);
SpontPost = str2double(handles.SpontPost_Edit.String);

AllSpirals = TriggerBuilder(...
    'name_prefix',        '',...
    'total_num_triggers', NumPatterns * SequenceRepetitions,...
    'trigger_every_ms',   ChangePatternEvery,...
    'trigger_dur_ms',     SpiralDuration,...
    'train_num_reps',     ShotsPerPattern,...
    'train_rep_every_ms', InterPatternShotInterval,...
    'shift_by_ms',        InitialDelay,...
    'tail_to_add_ms',     0,...
    'jitter',             0,...
    'trigger_amp_v',      5,...
    'sample_rate_hz',     SampleRateHz,...
    'to_blank',           [],...
    'to_blank_train',     [],...
    'plot_result',        false,...
    'save_result',        false...
    );

[SLMTriggers, SLMTrigName] = TriggerBuilder(...
    'name_prefix',        '',...
    'total_num_triggers', NumPatterns * SequenceRepetitions,...
    'trigger_every_ms',   ChangePatternEvery,...
    'trigger_dur_ms',     5,...
    'train_num_reps',     1,...
    'train_rep_every_ms', 0,...
    'shift_by_ms',        0,...
    'tail_to_add_ms',     0,...
    'jitter',             0,...
    'trigger_amp_v',      5,...
    'sample_rate_hz',     SampleRateHz,...
    'to_blank',           [],...
    'to_blank_train',     [],...
    'plot_result',        false,...
    'save_result',        false...
    );

if TrigOnEvery == true
    SpiralTriggers = SLMTriggers;
    SpiralTrigName = SLMTrigName;
else
    [SpiralTriggers,SpiralTrigName] = TriggerBuilder(...
        'name_prefix',        '',...
        'total_num_triggers', 1,...
        'trigger_every_ms',   ChangePatternEvery * NumPatterns * SequenceRepetitions,...
        'trigger_dur_ms',     5,...
        'train_num_reps',     1,...
        'train_rep_every_ms', 0,...
        'shift_by_ms',        0,...
        'tail_to_add_ms',     0,...
        'jitter',             0,...
        'trigger_amp_v',      5,...
        'sample_rate_hz',     SampleRateHz,...
        'to_blank',           [],...
        'to_blank_train',     [],...
        'plot_result',        false,...
        'save_result',        false...
        );
end

% update pattern order plot
Patterns = repmat([1:NumPatterns]',SequenceRepetitions,1);

im = handles.TimingPlotPatterns;
ax = handles.TimingPlotPatternsAx;
data = Patterns;
im.XData = [0 size(data,1)-1];
im.YData = [0 1];
ax.XLim = [0 size(data,1)] - 0.5;
ax.YLim = [0 1];
im.CData = data';

groupLUTindex = handles.GroupLUT_PopupMenu.Value;
selectedCmap = handles.GroupLUT_PopupMenu.String{groupLUTindex};
colours = eval([lower(selectedCmap) '(NumPatterns)']);
colormap(ax, colours);


% Update trigger plots
xdata = (1:numel(AllSpirals));
handles.TimingPlotSpirals.YData = (AllSpirals/max(AllSpirals))*0.8+2;
handles.TimingPlotSpirals.XData = xdata;
handles.TimingPlotSLMTriggers.YData = (SLMTriggers/max(SLMTriggers))*0.8+1;
handles.TimingPlotSLMTriggers.XData = xdata;
handles.TimingPlotSpiralTriggers.YData = (SpiralTriggers/max(SpiralTriggers))*0.8;
handles.TimingPlotSpiralTriggers.XData = xdata;
handles.TimingPlotAx.XLim = [0 max(xdata)];


% update all trials plot
SingleTrial = zeros(TrialInterval*SampleRateHz, 1);
SingleTrialSLM = SingleTrial;
SingleTrialSLM(1:numel(SLMTriggers)) = SLMTriggers;
SingleTrialSpirals = SingleTrial;
SingleTrialSpirals(1:numel(SpiralTriggers)) = SpiralTriggers;
AllTrialsSLMTriggers = [zeros(SpontPre*SampleRateHz,1); repmat(SingleTrialSLM, NumberOfTrials, 1);  zeros(SpontPost*SampleRateHz,1)];
AllTrialsSpiralTriggers = [zeros(SpontPre*SampleRateHz,1); repmat(SingleTrialSpirals, NumberOfTrials, 1);  zeros(SpontPost*SampleRateHz,1)];


% Update trigger plots
xdata = (1:numel(AllTrialsSLMTriggers));
handles.AllTrialsTimingPlotSLMTriggers.YData = (AllTrialsSLMTriggers/max(AllTrialsSLMTriggers))*0.8+1;
handles.AllTrialsTimingPlotSLMTriggers.XData = xdata;
handles.AllTrialsTimingPlotSpiralTriggers.YData = (AllTrialsSpiralTriggers/max(AllTrialsSpiralTriggers))*0.8;
handles.AllTrialsTimingPlotSpiralTriggers.XData = xdata;
handles.AllTrialsTimingPlotAx.XLim = [0 max(xdata)];


% update duration text strings
SingleTrialDuration = round(numel(SpiralTriggers) / SampleRateHz);
AllTrialsDuration = round(numel(AllTrialsSLMTriggers) / SampleRateHz);
if str2double(handles.TrialInterval_Edit.String) < SingleTrialDuration
    handles.TrialInterval_Edit.String = num2str(SingleTrialDuration, '%d');
end
handles.SingleTrialOutputDuration_Text.String = [num2str(SingleTrialDuration, '%d') ' (s)'];
handles.OutputDuration_Text.String = [num2str(AllTrialsDuration, '%d') ' (s)'];


% Save files out?
if numel(varargin) > 0
    Save = varargin{1};
    if ~isempty(Save) && Save==1
        % test if save single trial, or all trials
        fid = fopen([handles.data.NaparmDirectory filesep 'ToSLM_AllTrials' SLMTrigName '.dat'], 'w', 'l');
        fwrite(fid, AllTrialsSLMTriggers, 'double');
        fclose(fid);
        
        fid = fopen([handles.data.NaparmDirectory filesep 'ToPV_AllTrials' SpiralTrigName '.dat'], 'w', 'l');
        fwrite(fid, AllTrialsSpiralTriggers, 'double');
        fclose(fid);
    end
end



function SaveParameterFile(handles)
SaveName = [handles.data.NaparmDirectory filesep handles.data.ExperimentIdentifier '_Config'];
parameters = handles.data;
save(SaveName, 'parameters')



function SavePointsFile(handles)
if isfield(handles.data, 'NaparmDirectory')
    SaveName = [handles.data.NaparmDirectory filesep handles.data.ExperimentIdentifier '_Points'];
else
    [FileName, PathName] = uiputfile('*.mat', 'Save points file', 'points');
    SaveName = [PathName filesep FileName];
end
points = handles.points;
points.h = [];
save(SaveName, 'points')



% --- Executes on button press in togglebutton3.
function togglebutton3_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton3



% --- Executes on button press in AddDummy_Checkbox.
function AddDummy_Checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to AddDummy_Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AddDummy_Checkbox



function SaveGUIState(filename, handles)
exclude = {'ExperimentName_Edit', 'PointsCounter_Text', 'SelectImage_Popup'};

ObjectNames = fieldnames(handles);

ExcludeIdx = ismember(ObjectNames, exclude);
valid = structfun(@(F) length(F) == 1 && ishandle(F) && strcmpi(get(F,'type'), 'uicontrol'), handles);
valid = valid & ~ExcludeIdx;

ObjectNames = ObjectNames(valid);

Objects     = struct2cell(handles);
Objects     = Objects(valid);

State = [ObjectNames, get([Objects{:}],'String'), get([Objects{:}],'Value')];

save(filename, 'State')



function LoadGUIState(filename, handles)

State = load(filename);
State = State.State;

ObjectNames = State(:,1);
Strings = State(:,2);
Values = State(:,3);

IsValid = cellfun(@(F) isfield(handles, F) && ishandle(handles.(F)), ObjectNames);
ValidIdx = find(IsValid);

for i = 1:length(ValidIdx)
    idx = ValidIdx(i);
    set(handles.(ObjectNames{idx}), 'String', [Strings{idx}], 'Value', [Values{idx}]);
end



% --------------------------------------------------------------------
function About_Menu_Callback(hObject, eventdata, handles)
% hObject    handle to About_Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox('Naparm3. 2016/17. Henry and Lloyd. Hausser lab.', 'About')



% --------------------------------------------------------------------
function LoadPreset_Menu_Callback(hObject, eventdata, handles)
% hObject    handle to LoadPreset_Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName, PathName] = uigetfile([handles.CodePath filesep 'Presets' filesep '*.mat']);
LoadName = [PathName filesep FileName];
LoadGUIState(LoadName, handles)
handles.LoadedPreset_Text.String = strrep(FileName,'.mat','');
UpdateTimingPlot([], [], handles, false);



% --------------------------------------------------------------------
function SavePreset_Menu_Callback(hObject, eventdata, handles)
% hObject    handle to SavePreset_Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName, PathName] = uiputfile([handles.CodePath filesep 'Presets' filesep '*.mat']);
SaveName = [PathName filesep FileName];
SaveGUIState(SaveName, handles);



% --------------------------------------------------------------------
function SetDefaults_Menu_Callback(hObject, eventdata, handles)
% hObject    handle to SetDefaults_Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SaveName = [handles.CodePath filesep 'GUIdefaults.mat'];
SaveGUIState(SaveName, handles);



function edit47_Callback(hObject, eventdata, handles)
% hObject    handle to edit47 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit47 as text
%        str2double(get(hObject,'String')) returns contents of edit47 as a double



% --- Executes during object creation, after setting all properties.
function edit47_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit47 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NewPointStyle_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to NewPointStyle_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NewPointStyle_Edit as text
%        str2double(get(hObject,'String')) returns contents of NewPointStyle_Edit as a double

NewPointStyle = lower(handles.NewPointStyle_Edit.String);

handles.points.h.Marker = NewPointStyle;



% --- Executes during object creation, after setting all properties.
function NewPointStyle_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NewPointStyle_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NewPointColour_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to NewPointColour_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NewPointColour_Edit as text
%        str2double(get(hObject,'String')) returns contents of NewPointColour_Edit as a double
NewPointColour = lower(handles.NewPointColour_Edit.String);
NewPointColour = strrep(NewPointColour,'[','');
NewPointColour = strrep(NewPointColour,']','');
NewPointColour = strsplit(NewPointColour, ',');
NewPointColour = str2double(NewPointColour);


pointColours = repmat(NewPointColour, handles.points.Counter,1);
showAllPoints = handles.ShowAllPoints_checkbox.Value;
if ~showAllPoints
    zIndices = handles.points.Z == handles.CurrentZPlane;
else
    zIndices = 1:handles.points.Counter;
end
pointColours(~zIndices,:) = nan;

handles.points.h.CData = pointColours;




% --- Executes during object creation, after setting all properties.
function NewPointColour_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NewPointColour_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in LoadPreset_PushButton.
function LoadPreset_PushButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadPreset_PushButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName, PathName] = uigetfile([handles.CodePath filesep 'Presets' filesep '*.mat']);
LoadName = [PathName filesep FileName];
LoadGUIState(LoadName, handles)
handles.LoadedPreset_Text.String = strrep(FileName,'.mat','');
UpdateTimingPlot([], [], handles, false);



% --- Executes on button press in SavePreset_Pushbutton.
function SavePreset_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to SavePreset_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName, PathName] = uiputfile([handles.CodePath filesep 'Presets' filesep '*.mat']);
SaveName = [PathName filesep FileName];
SaveGUIState(SaveName, handles);



% --- Executes on button press in SetDefaults_Pushbutton.
function SetDefaults_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to SetDefaults_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SaveName = [handles.CodePath filesep 'GUIdefaults.mat'];
SaveGUIState(SaveName, handles);



function ExperimentNum_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to ExperimentNum_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ExperimentNum_Edit as text
%        str2double(get(hObject,'String')) returns contents of ExperimentNum_Edit as a double



function SpiralRevolutions_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to spiralrevolutions_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of spiralrevolutions_edit as text
%        str2double(get(hObject,'String')) returns contents of spiralrevolutions_edit as a double



function LaserPowerMW_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to laserpowermw_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of laserpowermw_edit as text
%        str2double(get(hObject,'String')) returns contents of laserpowermw_edit as a double

LaserPowerMW    = str2double(handles.LaserPowerMW_Edit.String);
LaserPowerPV    = mw2pv(LaserPowerMW);
handles.LaserPowerPV_Edit.String = num2str(LaserPowerPV);



% --- Executes on button press in Lasso_ToggleButton.
function Lasso_ToggleButton_Callback(hObject, eventdata, handles)
% hObject    handle to Lasso_ToggleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% selectdata

handles = guidata(hObject);

% draw a lasso
[lassoX,lassoY] = lassoDraw(handles.ImageAx);

showAllPoints = handles.ShowAllPoints_checkbox.Value;
if ~showAllPoints
    zIndices = find(handles.points.Z == handles.CurrentZPlane);
else
    zIndices = 1:handles.points.Counter;
end

% Which points from the data fall in the selection polygon?
AllPointsX = handles.points.X(zIndices);
AllPointsY = handles.points.Y(zIndices);
selectedPoints = inpolygon(AllPointsX, AllPointsY, lassoX, lassoY);
handles.points.Selected(zIndices) = selectedPoints;

% update plot
selectedIdx = find(handles.points.Selected);
handles.hSelection.XData = handles.points.X(selectedIdx);
handles.hSelection.YData = handles.points.Y(selectedIdx);

handles.Lasso_ToggleButton.Value = false;

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in InvertSelection_Pushbutton.
function InvertSelection_Pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to InvertSelection_Pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.points.Selected = ~handles.points.Selected;

selectedIdx = find(handles.points.Selected);
handles.hSelection.XData = handles.points.X(selectedIdx);
handles.hSelection.YData = handles.points.Y(selectedIdx);

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in GroupSelection_pushbutton.
function GroupSelection_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to GroupSelection_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if any(handles.points.Selected)
    % manually enter a group number and assign it
    selectedIdx = find(handles.points.Selected);
    groupNum = str2double(inputdlg('Group number:', 'Input', 1, {num2str(max(handles.points.Group)+1)}));
    handles.points.Group(selectedIdx) = groupNum;
    
    % replot
%     handles = ComputeGroupCentroids(handles ,[]);
    handles = PlotClusterLines(handles, []);
    
    % deselect
    handles.points.Selected = [];
    handles.hSelection.XData = [];
    handles.hSelection.YData = [];
    
    % update table
    updatePointsTable(handles)
    
    % Update handles structure
    guidata(hObject, handles);
    
    UpdateTimingPlot([], [], handles, false);
end



% --- Executes on button press in DeleteSelection_pushbutton.
function DeleteSelection_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to DeleteSelection_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

for i = fliplr(find(handles.points.Selected))
    handles = guidata(hObject);
    deletePoint(handles, i)
end

% refresh handles structure
handles = guidata(hObject);

% replot
if any(handles.points.Group)
    handles = ComputeGroupCentroids(handles, []);
    handles = PlotClusterLines(handles, []);
end

% clear selction
handles.hSelection.XData = [];
handles.hSelection.YData = [];

% save handles
guidata(hObject, handles);



function autoFindRadius_edit_Callback(hObject, eventdata, handles)
% hObject    handle to autoFindRadius_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of autoFindRadius_edit as text
%        str2double(get(hObject,'String')) returns contents of autoFindRadius_edit as a double



% --- Executes during object creation, after setting all properties.
function autoFindRadius_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to autoFindRadius_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in LoadPoints_pushbutton.
function LoadPoints_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadPoints_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[FileName, PathName] = uigetfile('*.mat');
FilePath = [PathName filesep FileName];
Loaded = load(FilePath);

CurrentNumPoints = handles.points.Counter;

if isfield(Loaded, 'software')
    if strcmpi(Loaded.software, 'cellpose')
        % process the cellpose masks here...
        nplanes = size(Loaded.masks,1);
        
        Loaded.points.X = [];
        Loaded.points.Y = [];
        Loaded.points.Z = [];
        Loaded.points.Zum = [];
        Loaded.points.Idx = [];
        Loaded.points.Img = [];
        Loaded.points.Group = [];
        Loaded.points.GroupCentroidX = [];
        Loaded.points.GroupCentroidY = [];
        Loaded.points.Weight = [];
        Loaded.points.OffsetX = [];
        Loaded.points.OffsetY = [];

        for p = 1:nplanes
            masks_p = double(squeeze(Loaded.masks(p,:,:)));
            numFound = max(masks_p(:));
            for m = 1:numFound
                tempInd = find(masks_p==m);
                [tempIndY, tempIndX] = ind2sub(size(masks_p), tempInd);
                Loaded.points.X = [Loaded.points.X median(tempIndX)];
                Loaded.points.Y = [Loaded.points.Y median(tempIndY)];
                Loaded.points.Z = [Loaded.points.Z p];
            end
        end
        Loaded.points.Zum = nan(size(Loaded.points.Z));
        Loaded.points.Idx = 1:numel(Loaded.points.Z);
        Loaded.points.Img = Loaded.points.Z;
        Loaded.points.Group = nan(size(Loaded.points.Z));
        Loaded.points.GroupCentroidX = nan(size(Loaded.points.Z));
        Loaded.points.GroupCentroidY = nan(size(Loaded.points.Z));
        Loaded.points.Weight = nan(size(Loaded.points.Z));
        Loaded.points.OffsetX = nan(size(Loaded.points.Z));
        Loaded.points.OffsetY = nan(size(Loaded.points.Z));
        
        
    else
        disp('Unknown!')
    end
end

AddPoint(Loaded.points.X', Loaded.points.Y', handles)

% refresh handles
handles = guidata(hObject);

handles.points.OffsetX(CurrentNumPoints+1:end) = Loaded.points.OffsetX;
handles.points.OffsetY(CurrentNumPoints+1:end) = Loaded.points.OffsetY;
handles.points.Z(CurrentNumPoints+1:end) = Loaded.points.Z;
handles.points.Zum(CurrentNumPoints+1:end) = Loaded.points.Zum;
handles.points.Idx(CurrentNumPoints+1:end) = CurrentNumPoints + Loaded.points.Idx;
handles.points.Img(CurrentNumPoints+1:end) = Loaded.points.Img;
handles.points.Group(CurrentNumPoints+1:end) = Loaded.points.Group;
handles.points.GroupCentroidX(CurrentNumPoints+1:end) = Loaded.points.GroupCentroidX;
handles.points.GroupCentroidY(CurrentNumPoints+1:end) = Loaded.points.GroupCentroidY;
handles.points.Weight(CurrentNumPoints+1:end) = Loaded.points.Weight;

updatePointsTable(handles);
if any(handles.points.Group)
    handles = ComputeGroupCentroids(handles, []);
    handles = PlotClusterLines(handles, []);
end
guidata(handles.output, handles);



% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



% --- Executes during object creation, after setting all properties.
function LUT_PopupMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



% --- Executes on button press in DiscardThreshold_pushbutton.
function DiscardThreshold_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to DiscardThreshold_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get intensity of rois
points = handles.points;
img = handles.imageDisplay.CData;
roiRadius = 5;
intensities = GetROIIntensities(points, img, roiRadius);

% delete
thresh = str2double(handles.DiscardThreshold_edit.String);
toDelete = intensities < thresh;
toDeleteIdx = fliplr(find(toDelete));  % delete newest point first to maintain indexing
if sum(toDelete) < numel(points.X)  % probably dont want to delete everything...
    for idx = toDeleteIdx
        handles = guidata(hObject);  % update handles
        %     set(handles.points.h(idx), 'MarkerEdgeColor', 'c');
        deletePoint(handles, idx)
    end
else
    disp('Not deleting anything because threshold probably too high')
end



function intensities = GetROIIntensities(points, img, radius)
% dilate ROIs
rois = dilateROIs(points.X, points.Y, 'roi_radius',radius);

% get values
for r = 1:numel(rois)
    intensities(r) = mean(img(rois{r}));
end



% --- Executes on button press in KeepBrightest_pushbutton.
function KeepBrightest_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to KeepBrightest_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get intensity of rois
points = handles.points;
img = handles.imageDisplay.CData;
roiRadius = 5;
intensities = GetROIIntensities(points, img, roiRadius);

% delete
[sortedVals, sortedIdx] = sort(intensities, 'descend');
numToKeep = str2double(handles.KeepBrightest_edit.String);
if numToKeep < numel(points.X)
    toDeleteIdx = sort(sortedIdx(numToKeep+1:end), 'descend');  % delete newest point first to maintain indexing
    for idx = toDeleteIdx
        handles = guidata(hObject);  % update handles
        %     set(handles.points.h(idx), 'MarkerEdgeColor', 'c');
        deletePoint(handles, idx)
    end
else
    disp('Not deleting anything because not enough rois')
end



function DiscardThreshold_edit_Callback(hObject, eventdata, handles)
% hObject    handle to DiscardThreshold_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DiscardThreshold_edit as text
%        str2double(get(hObject,'String')) returns contents of DiscardThreshold_edit as a double



% --- Executes during object creation, after setting all properties.
function DiscardThreshold_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DiscardThreshold_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function KeepBrightest_edit_Callback(hObject, eventdata, handles)
% hObject    handle to KeepBrightest_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KeepBrightest_edit as text
%        str2double(get(hObject,'String')) returns contents of KeepBrightest_edit as a double



% --- Executes during object creation, after setting all properties.
function KeepBrightest_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KeepBrightest_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LaserPowerPV_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to LaserPowerPV_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LaserPowerPV_Edit as text
%        str2double(get(hObject,'String')) returns contents of LaserPowerPV_Edit as a double



% --- Executes during object creation, after setting all properties.
function LaserPowerPV_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LaserPowerPV_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in Normalise_pushbutton.
function Normalise_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Normalise_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get current image
index = handles.SelectImage_Popup.Value;
img = handles.allImagesProcessed{index};
editedImg = img;

% apply filter
% keyboard
editedImg(:,:,handles.CurrentZPlane) = normaliseImage(img(:,:,handles.CurrentZPlane));

% save the edited image
handles.allImagesProcessed{index} = editedImg;
guidata(handles.output, handles)

% update display
changeImage(handles)



function img = normaliseImage(img)
img = localnormalize(img, 2, 10);



% --- Executes on button press in Invert_pushbutton.
function Invert_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Invert_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get current image
index = handles.SelectImage_Popup.Value;
img = handles.allImagesProcessed{index};
editedImg = img;

% apply filter
% keyboard
editedImg(:,:,handles.CurrentZPlane) = invertImg(img(:,:,handles.CurrentZPlane));

% save the edited image
handles.allImagesProcessed{index} = editedImg;
guidata(handles.output, handles)

% update display
changeImage(handles)



function img = invertImg(img)
img = imcomplement(img);



function CurrentZPlane_edit_Callback(hObject, eventdata, handles)
% hObject    handle to CurrentZPlane_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CurrentZPlane_edit as text
%        str2double(get(hObject,'String')) returns contents of CurrentZPlane_edit as a double



% --- Executes during object creation, after setting all properties.
function CurrentZPlane_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CurrentZPlane_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FocalPlane_edit_Callback(hObject, eventdata, handles)
% hObject    handle to FocalPlane_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FocalPlane_edit as text
%        str2double(get(hObject,'String')) returns contents of FocalPlane_edit as a double

focalPlane = str2double(handles.FocalPlane_edit.String);
planeSpacing = str2double(handles.PlaneSpacing_edit.String);
handles.points.Zum = (handles.points.Z - focalPlane) * planeSpacing;

updatePointsTable(handles)



% --- Executes during object creation, after setting all properties.
function FocalPlane_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FocalPlane_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PlaneSpacing_edit_Callback(hObject, eventdata, handles)
% hObject    handle to PlaneSpacing_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PlaneSpacing_edit as text
%        str2double(get(hObject,'String')) returns contents of PlaneSpacing_edit as a double
focalPlane = str2double(handles.FocalPlane_edit.String);
planeSpacing = str2double(handles.PlaneSpacing_edit.String);
handles.points.Zum = (handles.points.Z - focalPlane) * planeSpacing;

updatePointsTable(handles)



% --- Executes during object creation, after setting all properties.
function PlaneSpacing_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PlaneSpacing_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in AddZPlane_pushbutton.
function AddZPlane_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to AddZPlane_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% only add a new plane if no images loaded
if isempty(handles.allImageShapes)
    handles.ZPlane_slider.Max = handles.ZPlane_slider.Max + 1;
    numSlices = handles.ZPlane_slider.Max;
    handles.ZPlane_slider.SliderStep = [1/(numSlices-1) 1/(numSlices-1)];
    handles.ZPlane_slider.Value = handles.ZPlane_slider.Max;
    ZPlane_slider_Callback(hObject, eventdata, handles);
end



% --- Executes on button press in ShowAllPoints_checkbox.
function ShowAllPoints_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to ShowAllPoints_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ShowAllPoints_checkbox

handles = PlotClusterLines(handles, []);



% --- Executes on slider movement.
function ZPlane_slider_Callback(hObject, eventdata, handles)
% hObject    handle to ZPlane_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

if handles.ZPlane_slider.Value < 1
    handles.ZPlane_slider.Value = 1;
end
if handles.ZPlane_slider.Value > handles.ZPlane_slider.Max
    handles.ZPlane_slider.Value = handles.ZPlane_slider.Max;
end
handles.ZPlane_slider.Value = round(handles.ZPlane_slider.Value);
numPlanes = handles.ZPlane_slider.Max;
currentPlane = round(handles.ZPlane_slider.Value);
handles.CurrentZPlane = currentPlane;
handles.CurrentPlane_text.String = ['Plane ' num2str(currentPlane) ' of ' num2str(numPlanes)];

% if image loaded, update frame
if ~isempty(handles.allImageShapes)
    changeImage(handles)
end
updatePointsTable(handles)

handles = PlotClusterLines(handles, []);



% --- Executes during object creation, after setting all properties.
function ZPlane_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ZPlane_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes on button press in OnlyGroupWithinPlane_checkbox.
function OnlyGroupWithinPlane_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to OnlyGroupWithinPlane_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OnlyGroupWithinPlane_checkbox



% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
keyPressed = eventdata.Key;
if strcmpi(keyPressed,'comma')
    handles.ZPlane_slider.Value = handles.ZPlane_slider.Value - 1;
    ZPlane_slider_Callback(hObject, eventdata, handles);
elseif strcmpi(keyPressed,'period')
    handles.ZPlane_slider.Value = handles.ZPlane_slider.Value + 1;
    ZPlane_slider_Callback(hObject, eventdata, handles);
end


% --- Executes when entered data in editable cell(s) in PointsTable.
function PointsTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to PointsTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% data = [p.X; p.Y; p.Z; p.Zum; p.Group; p.Img; p.OffsetX; p.OffsetY; p.GroupCentroidX; p.GroupCentroidY; p.Weight]';

% get table data
data = handles.PointsTable.Data;

p = handles.points;
handles.points = p;
handles.points.Z = data(:,3)';
handles.points.Zum = data(:,4)';

% save
guidata(handles.output, handles);
