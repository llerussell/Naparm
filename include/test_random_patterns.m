% test random patterns

numCells = 50;
x = randi(512, 1, numCells);
y = randi(512, 1, numCells);
id = randi(2, 1, numCells);
% id = ones(1, numCells);

groupSize = 10;
numGroups = 100;
timeOut = 0;
stimEvery = 0;
radius = 300;

groupings = RandomSpotPatterns(x, y, id, groupSize, numGroups, timeOut, stimEvery, radius);

% plot
figure
xlim([0 512])
ylim([0 512])
axis square
hold on
scatter(x, y, 100, 'k')

cmap = parula(numGroups);
for i = 1:numGroups
    x_plot = x(groupings(i,:));
    y_plot = y(groupings(i,:));
    centroid_x = mean(x_plot);
    centroid_y = mean(y_plot);
    scatter(x_plot, y_plot, 50, ones(size(x_plot))*i, 'filled')
%     scatter(centroid_x, centroid_y, 100, i);
    for j = 1:numel(x_plot)
        plot([x_plot(j) centroid_x], [y_plot(j) centroid_y], 'color',cmap(i,:))
    end
end
