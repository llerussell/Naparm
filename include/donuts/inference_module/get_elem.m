function elem = get_elem(H, L, isfirst, KS)

Nbatch = size(H,2);
for n = 1:Nbatch
    elem(n).h0 = H(:,n);   
    elem(n).h0 = elem(n).h0(elem(n).h0>-.5);    
    
    indx = (elem(n).h0 + 1);
    iz = ceil(indx/L^2);    
        
    elem(n).h0 = elem(n).h0(isfirst(iz)>0);
    
    indx = (elem(n).h0 + 1);
    iz = ceil(indx/L^2);
    indx = indx - (iz-1)*L^2;
    iy = ceil(indx/L);
    ix = indx - (iy-1)*L;
    
    elem(n).ix = ix;
    elem(n).iy = iy;
    elem(n).iz = iz;    
    
    elem(n).map = ceil(iz/KS);           
end