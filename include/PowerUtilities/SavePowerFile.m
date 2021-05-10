function SavePowerFile(powers, varargin)
% paste two columns of data. first column: PV setting, second column: recorded mW
% varargin: second input can be order of polynomial


% parse inputs and calculate fit
power_file = [];
power_file.order = 9;
if ~isempty(varargin)
    power_file.order = varargin{1};
end
power_file.V     = powers(:,1);
power_file.mW    = powers(:,2);
power_file.p     = polyfit(power_file.mW, power_file.V, power_file.order);
power_file.x_fit = linspace(min(power_file.mW), max(power_file.mW), 100);
power_file.y_fit = polyval(power_file.p, power_file.x_fit);
power_file.date  = datestr(now());
power_file.old   = {};


% keep record of old powers
yaml = ReadYaml('settings.yml');
if exist(yaml.LaserPowerFile, 'file')
    loaded = load(yaml.LaserPowerFile);
    all_old = {};
    if isfield(loaded.power_file, 'old') 
        all_old = loaded.power_file.old;
        loaded.power_file = rmfield(loaded.power_file, 'old');  % remove 'old' from older files to stop file exponentially increasing in size
    end
    all_old{end+1} = loaded.power_file;
    power_file.old = all_old;
end


% plot the fit
figure('Color',[1 1 1])
axis square
hold on
plot(power_file.mW, power_file.V, 'k.--', 'markersize',20);
plot(power_file.x_fit, power_file.y_fit, 'r-')
ylabel('PV setting (au)')
xlabel('Measured power (mW)')


% save the fit to file
choice = questdlg('Are you happy with the fit?','Save results?','Yes','No', 'Yes');
if strcmpi(choice, 'Yes')
    save(['C:\Users\User\Dropbox\Bruker2\PowerUtilities\' yaml.LaserPowerFile], 'power_file')
    disp('Saved power file')
end
