function XML = MarkPoints_XMLMaker(varargin)
% Lloyd Russell 20151119
% can't use xmlread/write because Bruker are using some non-valid
% characters (xml parser throws errors). instead treat as a very long string.
% 20170402: added scale factor into script. will ultiamtely load this value
% from a computer specific settings file.

p = inputParser;

% for mark point series element
p.addOptional('ExptCat', 'Lloyd');
p.addOptional('ExptName', 'Test');
p.addOptional('Iterations', 1);
p.addOptional('IterationDelay', 0);
p.addOptional('AddDummy',0);

% for mark point element
p.addOptional('InternalIterations', 1);
p.addOptional('Repetitions', 5);
p.addOptional('UncagingLaser', 'Photostim');
p.addOptional('UncagingLaserPower', 100);
p.addOptional('TriggerFrequency', 'None');
p.addOptional('TriggerSelection', 'None');
p.addOptional('TriggerCount', 1);
p.addOptional('AsyncSyncFrequency', 'None');
p.addOptional('VoltageOutputCategoryName', 'Lloyd');
p.addOptional('VoltageOutputExperimentName', '1msPulseOut_6713AO0');
p.addOptional('VoltageRecCategoryName', 'None');
p.addOptional('parameterSet', 'CurrentSettings');

% for galvo point element
p.addOptional('InitialDelay', 0.01);
p.addOptional('InterPointDelay', 0.01);
p.addOptional('Duration', 10);
p.addOptional('Points', 'Point 1');
p.addOptional('Indices', 1);
p.addOptional('SpiralRevolutions', 3);

% general
p.addOptional('SaveName', '');
p.addOptional('NumRows', 1);


% parse inputs
p.parse(varargin{:})
NumRows = p.Results.NumRows;
if numel(p.Results.Repetitions) ~= NumRows; Repetitions = repmat(p.Results.Repetitions, NumRows, 1); else Repetitions = p.Results.Repetitions; end
if ~iscell(p.Results.UncagingLaser); UncagingLaser = repmat({p.Results.UncagingLaser}, NumRows, 1); else UncagingLaser = p.Results.UncagingLaser; end
if numel(p.Results.UncagingLaserPower) ~= NumRows; UncagingLaserPower = repmat(p.Results.UncagingLaserPower, NumRows, 1); else UncagingLaserPower = p.Results.UncagingLaserPower; end
if ~iscell(p.Results.TriggerFrequency); TriggerFrequency = repmat({p.Results.TriggerFrequency}, NumRows, 1); else TriggerFrequency = p.Results.TriggerFrequency; end
if ~iscell(p.Results.TriggerSelection); TriggerSelection = repmat({p.Results.TriggerSelection}, NumRows, 1); else TriggerSelection = p.Results.TriggerSelection; end
if numel(p.Results.TriggerCount) ~= NumRows; TriggerCount = repmat(p.Results.TriggerCount, NumRows, 1); else TriggerCount = p.Results.TriggerCount; end
if ~iscell(p.Results.AsyncSyncFrequency); AsyncSyncFrequency = repmat({p.Results.AsyncSyncFrequency}, NumRows, 1); else AsyncSyncFrequency = p.Results.AsyncSyncFrequency; end
if ~iscell(p.Results.VoltageOutputCategoryName); VoltageOutputCategoryName = repmat({p.Results.VoltageOutputCategoryName}, NumRows, 1); else VoltageOutputCategoryName = p.Results.VoltageOutputCategoryName; end
if ~iscell(p.Results.VoltageOutputExperimentName); VoltageOutputExperimentName = repmat({p.Results.VoltageOutputExperimentName}, NumRows, 1); else VoltageOutputExperimentName = p.Results.VoltageOutputExperimentName; end
if ~iscell(p.Results.VoltageRecCategoryName); VoltageRecCategoryName = repmat({p.Results.VoltageRecCategoryName}, NumRows, 1); else VoltageRecCategoryName = p.Results.VoltageRecCategoryName; end
if ~iscell(p.Results.parameterSet); parameterSet = repmat({p.Results.parameterSet}, NumRows, 1); else parameterSet = p.Results.parameterSet; end
if numel(p.Results.InitialDelay) ~= NumRows; InitialDelay = repmat(p.Results.InitialDelay, NumRows, 1); else InitialDelay = p.Results.InitialDelay; end
if numel(p.Results.InterPointDelay) ~= NumRows; InterPointDelay = repmat(p.Results.InterPointDelay, NumRows, 1); else InterPointDelay = p.Results.InterPointDelay; end
if numel(p.Results.Duration) ~= NumRows; Duration = repmat(p.Results.Duration, NumRows, 1); else Duration = p.Results.Duration; end
if ~iscell(p.Results.Points); Points = repmat({p.Results.Points}, NumRows, 1); else Points = p.Results.Points; end
if numel(p.Results.Indices) ~= NumRows; Indices = repmat(p.Results.Indices, NumRows, 1); else Indices = p.Results.Indices; end
if numel(p.Results.SpiralRevolutions) ~= NumRows; SpiralRevolutions = repmat(p.Results.SpiralRevolutions, NumRows, 1); else SpiralRevolutions = p.Results.SpiralRevolutions; end

% scale desired laser powers
% get values from settings file
yaml = ReadYaml('settings.yml');
LaserPowerScaleFactor = yaml.LaserPowerScaleFactor;
UncagingLaserPower = UncagingLaserPower / (1000/LaserPowerScaleFactor);

% BUILD EXPERIMENT
header = ['<PVSavedMarkPointSeriesElements '...
    'Category="' p.Results.ExptCat '" ' ...
    'Name="' p.Results.ExptName '" '...    
    'Iterations="' num2str(p.Results.Iterations) '" '...
    'IterationDelay="' num2str(p.Results.IterationDelay) '"'...
    ' >'];

if p.Results.AddDummy 
   dummy = [...
        '<PVMarkPointElement ' ... 
        'Repetitions="' num2str(1) '" '...
        'UncagingLaser="' UncagingLaser{1} '" '...
        'UncagingLaserPower="' num2str(0) '" '...
        'TriggerFrequency="' 'None' '" '...
        'TriggerSelection="' 'None' '" '...
        'TriggerCount="' num2str(1) '" '...
        'AsyncSyncFrequency="' 'None' '" '...
        'VoltageOutputCategoryName="None" '...
        'VoltageRecCategoryName="None" '...
        'parameterSet="' parameterSet{1} '" '...
        '>'...
        '<PVGalvoPointElement '...
        'InitialDelay="0" '...
        'InterPointDelay="0" '...
        'Duration="1" '...
        'SpiralRevolutions="1" '... 
        'Points="' Points{1} '" '...
        'Indices="' num2str(Indices(1)) '" '...
        '/>'...
        '</PVMarkPointElement>'...
        ];  
else    
    dummy = []; 
end

elements = cell(p.Results.NumRows * p.Results.InternalIterations,1);
for i = 1:p.Results.NumRows
        elements{i} = [...
            '<PVMarkPointElement ' ...
            'Repetitions="' num2str(Repetitions(i)) '" '...
            'UncagingLaser="' UncagingLaser{i} '" '...
            'UncagingLaserPower="' num2str(UncagingLaserPower(i)) '" '...
            'TriggerFrequency="' TriggerFrequency{i} '" '...
            'TriggerSelection="' TriggerSelection{i} '" '...
            'TriggerCount="' num2str(TriggerCount(i)) '" '...
            'AsyncSyncFrequency="' AsyncSyncFrequency{i} '" '...
            'VoltageOutputCategoryName="' VoltageOutputCategoryName{i} '" '...
            'VoltageOutputExperimentName="' VoltageOutputExperimentName{i} '" '...
            'VoltageRecCategoryName="' VoltageRecCategoryName{i} '" '...
            'parameterSet="' parameterSet{i} '" '...
            '>'...
            '<PVGalvoPointElement '...
            'InitialDelay="' num2str(InitialDelay(i)) '" '...
            'InterPointDelay="' num2str(InterPointDelay(i)) '" '...
            'Duration="' num2str(Duration(i)) '" '...
            'SpiralRevolutions="' num2str(SpiralRevolutions(i)) '" '...
            'Points="' Points{i} '" '...
            'Indices="' num2str(Indices(i)) '" '...
            '/>'...
            '</PVMarkPointElement>'...
            ];
end

footer = '</PVSavedMarkPointSeriesElements>';

XML = [header dummy [elements{:}] footer];

% save out separate experiment file (may be used in the future?)
if ~isempty(p.Results.SaveName)
    fid = fopen([p.Results.SaveName '.xml'], 'w', 'l');
    fwrite(fid, XML, 'char');
    fclose(fid);
end


% % ADD TO ENVIRONMENT FILE
% % load environment file
% EnvFilePath = p.Results.EnvFilePath;
% EnvFile = fileread([EnvFilePath '.env']);
% 
% % find the end of mark points sections
% k = strfind(EnvFile, '</PVMarkPoints>');
% 
% % split file, add new MPE to end of MP section
% TopChunk = EnvFile(1:k-1);
% BottomChunk = EnvFile(k:end);
% NewEnvFile = [TopChunk expt BottomChunk];
% 
% % save out environment file
% if p.Results.Overwrite
%     fid = fopen([EnvFilePath '.env'], 'w', 'l');
% else
%     fid = fopen([EnvFilePath '_' datestr(now, 'YYYYmmDD-HHMM') '.env'], 'w', 'l');
% end
% fwrite(fid, NewEnvFile, 'char');
% fclose(fid);
