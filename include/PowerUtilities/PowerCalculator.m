% PV pockels setting to mw calculator
% LR 2017

%% paste measurements (pv mw columns)
% bruker 2 satsuma 2017-0526, mod=55%
data = [
0	0.6
25	4.7
50	17.5
75	36
100	64
125	98
150	138
175	178
200	224
225	272
250	320
275	361
300	403
325	442
350	475
];


%% Plot and calculate fit
PockelsSetting = data(:,1);
RecordedPower = data(:,2);

% fit
p = polyfit(RecordedPower, PockelsSetting, 8);  %choose order that works well
fit_x = linspace(min(RecordedPower),max(RecordedPower), 1000);
fit_y = polyval(p, fit_x); 

% plot
figure('name','Pockels-Power calculator');
hold on
scatter(RecordedPower, PockelsSetting)
plot(fit_x, fit_y)
xlabel('mW')
ylabel('Pockels Setting')
title('Pockels-Power calculator')
xlim([0 max(RecordedPower)])
ylim([0 max(PockelsSetting)])

%% Calculator
% PowerRanges_mW = [10 20 30 40 50 60 100];
PowerRanges_mW = [100 150 200 250 300 350];
% PowerRanges_mW = [250 300 350 400 450 500];
PowerRanges_mW = [1 2 3 4 5 6]*10;
PowerRanges_mW = [3 6 9 12 15 18]*10;
PowerRanges_mW = 3*30;
ValuesRequired_PV = [];

for i = 1:numel(PowerRanges_mW)
    Desired_mW = PowerRanges_mW(i);
    if Desired_mW <= max(RecordedPower)
        Required_PV = polyval(p,Desired_mW);
        ValuesRequired_PV(i) = Required_PV;
        disp([num2str(Desired_mW) ' mW  =  PV' num2str(round(Required_PV))])
        plot([Desired_mW Desired_mW], [0 Required_PV], 'k:')
        plot([0 Desired_mW], [Required_PV Required_PV], 'k:')
        % plot(0, Required_PV, 'r.')
        text(0, Required_PV, num2str(round(Required_PV)), 'Color','r')
    else
        warning('Requested power out of range')
    end
    
end

%% Calculator (single value)
Desired_mW = 50*6;
    
if Desired_mW <= max(RecordedPower)
    Required_PV = polyval(p,Desired_mW);
    disp([num2str(Desired_mW) ' mW --> PV ' num2str(round(Required_PV))])
else
    warning('Requested power out of range')
end
