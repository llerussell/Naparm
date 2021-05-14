% Measure power in a grid
% numbers should go from top left to top right, then down rows

%% bruker 2 SLM
powers = [
    80
    77
    87
    93
    97
    92
    84
    
    83
    86
    87
    94
    95
    88
    79
    
    85
    93
    102
    106
    102
    91
    87
    
    84
    95
    106
    111 % 10spotstight cos zo is blocked...
    108
    97
    94
    
    82
    93
    102
    108
    102
    95
    94
    
    72
    85
    94
    96
    92
    86
    86
    
    82
    88
    93
    90
    84
    77
    82
    ];

%% bruker2 uncaging galvo, slm engaged with 10spotstight zo is blocked
powers = [
    113
    114
    115
    114
    112
    109
    102
    
    113
    115
    115
    114
    113
    110
    103
    
    113
    115
    115
    114
    113
    110
    103
    
    111
    114
    115
    116
    113
    110
    102
    
    111
    114
    114
    115
    113
    110
    101
    
    112
    115
    115
    114
    112
    108
    100
    
    111
    112
    113
    113
    111
    107
    99
    ];

%% PROCESS DATA
gridCols = sqrt(numel(powers));
powers = powers ./ max(powers(:)) *100;
minPowerNorm = min(powers);
powers = reshape(powers, gridCols,gridCols)';

powersFilt = imresize(powers, [512, 512], 'nearest');
powersFilt = imgaussfilt(powersFilt,512/gridCols/2);

%% PLOT
figure('position', [100 100 1000 500]);
subplot(1,2,1)
imagesc(powers)
for i = 1:numel(powers)
    [y,x] = ind2sub([gridCols,gridCols], i);
    text(x,y,num2str(powers(i), '%.0f'));
end
axis square
xlabel('X position')
ylabel('Y position')
cb = colorbar;
xlabel(cb, 'Normalised power (%)')
caxis([0 100])
title('Measurement locations')

subplot(1,2,2)
imagesc(powersFilt)
axis square
hold on
mag = 1/1.14;
width = 512 * mag;
spacing = (512 - width)/2;
rectangle('position',[spacing spacing width width])
text(spacing+5, spacing+20, '1.14x FOV')
xlabel('X position')
ylabel('Y position')
cb = colorbar;
xlabel(cb, 'Normalised power (%)')
caxis([0 100])
title('Interpolated')

suptitle('Bruker2 SLM path galvo position vignetting - 1X FOV')
