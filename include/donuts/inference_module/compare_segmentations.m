% elem_model should be obtained by running the master file
elem(1).who = 'Model'; 
elem(1).ix = elem_model.ix;
elem(1).iy = elem_model.iy;

load centroids_mp.mat
elem(2).ix = centroids(:,2);
elem(2).iy = centroids(:,1);
elem(2).who = 'Marius';

load centroids_np.mat
elem(3).ix = centroids_np(:,2);
elem(3).iy = centroids_np(:,1);
elem(3).who = 'Noah';

load centroids_hwp.mat
elem(4).ix = centroids_hwdp(:,2);
elem(4).iy = centroids_hwdp(:,1);
elem(4).who = 'Henry';

%%
k_base      = 2;
base_elem   = elem(k_base);

for j = [1:k_base-1 k_base+1:length(elem)]    
    Nelem = length(elem(j).ix);
    
    elem(j).ROC = zeros(Nelem,2);    
    for i = 1:Nelem        
        compare_elem.ix = elem(j).ix(1:i);
        compare_elem.iy = elem(j).iy(1:i);        
        
        [hits, misses] = hits_and_misses(compare_elem, base_elem);
        
        elem(j).ROC(i,1) = sum(hits{1});
        elem(j).ROC(i,2) = sum(misses{1});
    end
end
%%
figure('outerposition',[0 0 400 800])
set(gca, 'Fontsize', 18)
txt_legend = {};

for j = [1:k_base-1 k_base+1:length(elem)]
    plot(elem(j).ROC(:, 2), elem(j).ROC(:, 1), 'Linewidth', 3)
    hold all    
    
    txt_legend{end+1} = elem(j).who;
end
Nall = length(elem(k_base).ix);
plot([0 50], [Nall Nall], 'k', 'Linewidth', 3)
txt_legend{end+1} = 'Oracle';

legend(txt_legend, 'Location', 'SouthEast')
title(sprintf('Compare against %s', elem(k_base).who))
xlabel('Misses')
ylabel('Hits')

xlim([0 50])
ylim([0 Nall+10])

