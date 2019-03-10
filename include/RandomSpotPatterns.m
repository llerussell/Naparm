function groupIDs = AssignRandomGroups(x, y, id, groupSize, numGroups, timeOut, stimEvery, radius)% random pattern generator test
% lloyd russell 2016

% specify parameters
numCells = numel(x);
diameter = radius*2;

% dist from other points
pwDists = pairwiseDistance([x;y]', [x;y]');
withinRadius = pwDists <= diameter;



completed = false;
groupIDs = zeros(numGroups, groupSize);
allGroups = [];
totalPossCombinations = 0;

withinRadius_copy = withinRadius;
goodSeeds = find(sum(withinRadius_copy, 2) >= groupSize);
% keyboard
tic
for i = 1:numel(goodSeeds)
    randomStarter = goodSeeds(randi(length(goodSeeds)));
    starter = goodSeeds(i);
    cellsWithinRadius = find(withinRadius_copy(starter, :));
    cellsWithinRadius = cellsWithinRadius(2:end);
    numPossibleCombinations = nchoosek(numel(cellsWithinRadius), groupSize-1);
    totalPossCombinations = totalPossCombinations + numPossibleCombinations;
%     theseCombinations = [repmat(i, numPossibleCombinations, 1) nchoosek(cellsWithinRadius, groupSize-1)];
%     keyboard
%     selectedCells = [starter datasample(cellsWithinRadius, groupSize-1, 'replace',false)];
    
    %     withinRadius_copy(:, selectedCells) = 0;
    
%     groupIDs(i,:) = selectedCells;
%     allGroups = [allGroups; theseCombinations];
end
toc
totalPossCombinations = totalPossCombinations/groupSize;
disp(['possible_groups=' num2str(totalPossCombinations)])
% keyboard


