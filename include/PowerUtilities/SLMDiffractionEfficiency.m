% SLM diffraction efficiency

% SLM phase mask          zero-order blocker           power
% full black field        out                          p1
% full black field        in                           p2
% 10spots                 out                          p3
% 10spots                 in                           p4

% 1-p2/p1 = the zero order block efficiency
% p4/p1   = diffraction efficiency (if zero order block efficiency is high)
% p3/p1   = ~1 (if not too much power in higher diffraction orders lost)
% 1-p3/p1 = power in higher diffraction orders

%% measurements
p1 = 121; % or 136 (slm off)
p2 = 30.8; % or 10.9(slm off)
p3 = 127;
p4 = 114;

%% results
ZOBlockEfficiency = 1-(p2/p1)
DiffractionEfficiency = p4/p1
Reflectance = p3/p1
PowerInHigherOrders = 1-(p3/p1)
