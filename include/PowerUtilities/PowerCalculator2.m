% inputs
powers = [0	0
100	29
130	51
200	102
300	205
400	308
500	393
600	436];

order = 5;

% query
query_pv = [130 170];
query_mw = [];

% parse inputs and calculate fit
V     = powers(:,1);
mW    = powers(:,2);
p     = polyfit(mW, V, order);
p2    = polyfit(V, mW, order);
x_fit = linspace(min(mW), max(mW), 100);
y_fit = polyval(p, x_fit);

% plot the fit
figure('Color',[1 1 1])
axis square
hold on
plot(mW, V, 'k.--', 'markersize',20);
plot(x_fit, y_fit, 'r-')
ylabel('PV setting (au)')
xlabel('Measured power (mW)')


% do query
if any(query_pv)
    answer_mw = polyval(p2, query_pv);
end

if any(query_mw)
    answer_pv = polyval(p, query_mw);
end

