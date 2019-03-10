function y = normal_img(I, sig1, sig2)
y = I;

Mask = ones(size(I));

lx = ceil(2*sig2);
dt = (-lx:lx)';

% keyboard;
if sig1<.25
    filter = zeros(length(dt));
    filter(lx:lx+2, lx:lx+2) = 1;
else
    sig = sig1;
    filter = exp(-dt.^2/(2*sig^2)) * exp(-dt'.^2/(2*sig.^2));
end

filter = filter/sum(filter(:));
Norms = filter2(filter, Mask, 'same');

A = filter2(filter, y, 'same');
A = A./Norms;

y = (y - A) ;

sig = sig2;
filter = exp(-dt.^2/(2*sig^2)) * exp(-dt'.^2/(2*sig.^2));
filter = filter/sum(filter(:));

B= filter2(filter, y.^2, 'same');
Norms = filter2(filter, Mask, 'same');
B = B./Norms;

y = y./B.^.5;



