% plot power file
yaml = ReadYaml('settings.yml');
load(yaml.LaserPowerFile);

num_old_fits = numel(power_file.old);
cmap = cool(num_old_fits+1);

% prepare figure
figure
subplot(2,2,[1 3])
ylabel('PV setting (au)')
xlabel('Measured power (mW)')
axis square; box off; grid on
hold on

% prepare data arrays
all_dates = cell(num_old_fits+1,1);
mins = nan(num_old_fits+1,1);
maxes = nan(num_old_fits+1,1);
all_dates{end} = power_file.date;
mins(end) = min(power_file.x_fit);
maxes(end) = max(power_file.x_fit);

% plot old fits first
if num_old_fits > 0
    for i = 1:num_old_fits
        % plot this fit
        plot(power_file.old{i}.x_fit, power_file.old{i}.y_fit, 'color',cmap(i,:), 'linewidth',2)
        
        % get info from old fits
        if isfield(power_file.old{i}, 'date')
            all_dates{i} = power_file.old{i}.date;
        else
            all_dates{i} = '';
        end
        mins(i) = min(power_file.old{i}.x_fit);
        maxes(i) = max(power_file.old{i}.x_fit);
    end
end

% plot newest fit
plot(power_file.x_fit, power_file.y_fit, 'color',cmap(end,:), 'linewidth',2)

legend(all_dates, 'location','eastoutside')

subplot(2,2,2)
plot(1:numel(maxes), maxes, 'k:', 'linewidth',2)
hold on
scatter(1:numel(maxes), maxes,100,cmap,'filled')
numTicks = 10;
xticks(1:round(numel(maxes)/numTicks):numel(maxes))
xticklabels(all_dates(1:round(numel(maxes)/numTicks):numel(maxes)))
xtickangle(45)
axis square; box off; grid on
title('Maximum (mW)')

subplot(2,2,4)
plot(1:numel(mins), mins, 'k:', 'linewidth',2)
hold on
scatter(1:numel(mins), mins,100,cmap,'filled')
numTicks = 10;
xticks(1:round(numel(maxes)/numTicks):numel(maxes))
xticklabels(all_dates(1:round(numel(maxes)/numTicks):numel(maxes)))
xtickangle(45)
axis square; box off; grid on
title('Minimum (mW)')
