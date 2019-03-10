function [hits, misses] = hits_and_misses(elem, gelem)

elem_sp = elem;

Ndata = length(elem);
for ex = 1:Ndata       
%     valid = elem(ex).map==cell_map;
    indx = 1:size(elem(ex).ix,1);
  
    ix = elem(ex).ix(indx);
    iy = elem(ex).iy(indx);    
    
    Nmean = length(ix);
    Dx = repmat(ix, [1 Nmean]) -  repmat(ix', [Nmean 1]);
    Dy = repmat(iy, [1 Nmean]) -  repmat(iy', [Nmean 1]);
    
    D       = (Dx.^2+Dy.^2).^.5;
    D       = triu(D, 1);
    
    D(D>=6)  = 0;    
    
    D(abs(D)>1e-10) = 1;   
    
    
    for j = 1:Nmean        
        if sum(D(1:j-1,j))>0
            elem_sp(ex).map(indx(j)) = -1;
            D(j,:) = 0;
        end
    end    
end
%%
proposal = elem_sp;
for ex = 1:Ndata
    Hits = zeros(length(gelem(ex).ix), 1);
    
%     valid = proposal(ex).map==cell_map;
    indx = 1:size(proposal(ex).ix, 1);
%     indx = find(valid);
    
    Misses = zeros(length(indx), 1);
    ix1 = proposal(ex).ix(indx);
    iy1 = proposal(ex).iy(indx);    
    
    ix2 = gelem(ex).ix;
    iy2 = gelem(ex).iy;        
    
    Dx = repmat(ix1, [1 length(ix2)]) -  repmat(ix2', [length(ix1) 1]);
    Dy = repmat(iy1, [1 length(ix2)]) -  repmat(iy2', [length(ix1) 1]);
    D       = (Dx.^2+Dy.^2).^.5;
    
    for j = 1:length(ix1)        
        [md, imin] = min(D(j,:));
        if (md<4) && Hits(imin)==0
            Hits(imin) = 1;
            D(:,imin) = Inf;
        else
            Misses(j) = 1;
        end
    end
    
    hits{ex} = Hits;
    misses{ex} = Misses;
end
