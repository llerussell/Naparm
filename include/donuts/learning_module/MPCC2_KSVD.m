%% this section loads the data

poolobj = gcp('nocreate'); % If no pool, do not create new one.
if isempty(poolobj)
    n_workers = 0;
    poolobj = gcp;
else
    n_workers = poolobj.NumWorkers;
end


cd(ops.data_path)

load('CorrImgs_4Planes', 'y')
y = double(y);
y_bk = y;

% figure
% numCols = ceil(sqrt(size(y,3)));
% for i = 1:size(y,3)
%     subplot(numCols, numCols, i)
%     imagesc(y(:,:,i))
%     axis square
%     axis off
% end

sig1 = ops.cell_diam / 4;
sig2 = ops.cell_diam * 4;

cd(ops.code_location)
clear Y
for i = 1:size(y,3)
    I        = y(:,:,i);
    Y(:,:,i) = I;
    y(:,:,i) = normal_img(I, sig1, sig2);
end

% figure
% idx = 1;
% subplot(1,2,1)
% imagesc(y_bk(:,:,idx))
% axis square
% axis off
% subplot(1,2,2)
% imagesc(y(:,:,idx))
% axis square
% axis off


% figure
% numCols = ceil(sqrt(size(y,3)));
% for i = 1:size(y,3)
%     subplot(numCols, numCols, i)
%     imagesc(y(:,:,i))
%     axis square
%     axis off
% end

data_loaded = 1;


%% this section initializes the model parameters
if ~exist('initialized')
    Ndata = size(y,3);
    Nbatch = Ndata;
    
    NSS = ops.NSS;
    KS  = ops.KS;
    
    subs = cell(1,NSS);
    for i = 1:NSS
        subs{i} = (i-1)*KS+1:i*KS;
    end
    
    dimSS = cellfun(@(x) length(x), subs);
    Nmaps = sum(dimSS);
    
    isfirst = zeros(1,Nmaps);
    for i = 1:NSS
        isfirst(subs{i}(1)) =  1;
    end
    
    lx  = 2*ops.cell_diam + 1;
    dx = ops.cell_diam;
    L = size(y,1);
    Ndata = size(y,3);
    
    W = .25 * randn(lx,lx, Nmaps);
    zx = ceil(lx/3);
    W(zx+1:zx+zx, zx+1:zx+zx,:) = randn(zx,zx, Nmaps);
    
    nW = sum(sum(W.^2, 1),2).^.5;
    W = W./repmat(nW, [lx lx 1]);
    
    for j = 1:NSS
        W(:,:,subs{j}(2:end)) = 0;
    end
    
    xs  = repmat(-dx:dx, lx, 1);
    ys  = xs';
    rs2 = (xs.^2+ys.^2);
    
    oW = zeros(size(W));
    
    tErr0 = 20.1;
    tErr = tErr0;
    
    ops.warmup  = 1;
    initialized = 1;
end
%%
cd(ops.code_location)
% close all

dtErr       = 5;

pos = zeros(Nmaps,1);
for j = 1:length(subs)
    pos(subs{j}(1)) = 0;
end
pos(1) = 1;

PrVar       = 1000;
Nmean       = KS * ops.cells_per_image;
Nmax        = KS * round(Nmean * 2/KS);

% initialize batch variables
dW = zeros(lx^2, Nmax, Nbatch);
H = zeros(Nmax, Nbatch);
X = zeros(Nmax, Nbatch);
Nact = zeros(Nbatch, 1);
Active = zeros(Nmaps, Nbatch);
Wy = zeros(L, L, Nmaps, Nbatch);
yres = zeros(L, L, Nbatch);


Bias = zeros(Nmaps,1);
nup = 2;
niter = 10000;
pW = 0.9;
WtW = zeros(2*lx-1, 2*lx-1, Nmaps, Nmaps);
Cost = zeros(niter,1);

Nused   = Nmean;

V       = Nmean/Nmaps * ones(Nmaps,1);

FS = stoploop;
tic
for n = 1:niter
    %     tErr = 0;
    for i = 1:Nmaps
        W0 = W(:,:,i);
        for j = 1:Nmaps
            WtW(:,:,j,i) = filter2(W(:,:,j), W0, 'full');
        end
    end
    A = squeeze(WtW(lx, lx, :, :));
    Akki = zeros(size(A));
    
    for i =1:NSS
        Akki(subs{i}, subs{i}) = ...
            A(subs{i}, subs{i}) + 1/PrVar * eye(dimSS(i));
    end
    Akki = inv(Akki);
    
    Nbatch = Ndata;
    
    Params = [Nmax tErr PrVar L lx Nmaps];
    
    parfor j = 1:Nbatch
        for i = 1:Nmaps
            Wy(:,:,i, j) = filter2(W(:,:,i), y(:,:,j), 'same');
        end
    end
    
    Wy = reshape(Wy, L*L*Nmaps, Nbatch);
    yres = reshape(yres, L*L, Nbatch);
    
    parfor j = 1:Nbatch
        [H(:,j), X(:,j), yres(:,j), Nact(j), Active(:,j)] = ...
            extract_coefs2_SBC(Wy(:,j), WtW, Params, y(:,:,j), ...
            W, Bias, Akki, isfirst, pos);
    end
    Wy = reshape(Wy, L, L, Nmaps, Nbatch);
    yres = reshape(yres, L, L, Nbatch);
    Cost(n) = mean(yres(:).^2);
    
    type = ceil(H/(L*L));
    hist_type = hist(type(:), 1:1:Nmaps);
    if ops.learn && min(hist_type)>0
        for j = 1:NSS
            % add back the contribution from these maps
            imap = zeros(1, Nmaps);
            imap(subs{j}) = 1;
            add_back_coefs(yres, H, Params, X, W, imap, Nact);
            
            Params(7) = subs{j}(1);
            dW = pick_patches(yres, H, Params);
            %             dW2 = pick_patches(y, H, Params);
            
            COV      = dW * dW'/size(dW,2);
            [U, Sv]   = svd(COV);
            
            xr      = U' * dW;
            signs   = 2 * (mean(xr>0, 2)>0.5) - 1;
            U = U .* repmat(signs', [lx^2 1]);
            
            if ops.MP
                U(:,2:end) = 0;
            elseif ops.inc && ops.warmup
                k = ceil(n/ops.inc);
                U(:,1+k:end) = 0;
            end
            
            W(:, :, subs{j}) = reshape(U(:,1:dimSS(j)), lx, lx, dimSS(j));
            
            dWrec = U(:,1:dimSS(j)) * (U(:,1:dimSS(j))' * dW);
            
            unpick_patches(yres, H, Params, dWrec);
            
            absW = abs(W(:,:,subs{j}(1)));
            absW = absW/mean(absW(:));
            x0 =  mean(mean(absW .* xs));
            y0 =  mean(mean(absW .* ys));
            
            xform = [1 0 0; 0 1 0; -x0 -y0 1];
            tform_translate = maketform('affine',xform);
            
            for k = subs{j}
                W(:,:,k) = imtransform(W(:,:,k), tform_translate,...
                    'XData', [1 lx], 'YData',   [1 lx]);
            end
        end
    end
    
    Nused = mean(Nact(:));
    V = mean(Active,2);
    nW = 1e-10 + sum(sum(W.^2, 1),2).^.5;
    W = W./repmat(nW, [lx lx 1]);
    
    if Nused > Nmean*1.5
        tErr = tErr + dtErr;
    elseif Nused < Nmean/1.5
        tErr = tErr - dtErr;
    elseif Nused > Nmean*1.1
        tErr = tErr + dtErr/5;
    elseif Nused < Nmean/1.1
        tErr = tErr - dtErr/5;
    elseif Nused>Nmean*1.01
        tErr = tErr + dtErr/20;
    elseif Nused<Nmean/1.01
        tErr = tErr - dtErr/20;
    end
    
    if rem(n,10)==0
        fprintf('Iteration %d , elapsed time is %0.2f seconds\n', n, toc)
    end
    
    if (FS.Stop() || ops.fig) && rem(n,10)==0
        % which map is the cell map?
        S_area = zeros(NSS,1);
        S4_area = zeros(NSS,1);
        for i =1:NSS
            S_area(i) = sum(sum(rs2.*W(:,:,subs{i}(1)).^2)).^.5;
        end
        est_diam = 2*S_area+1;
        [~, cell_map] = min((est_diam - ops.cell_diam).^2);
        
        
        if cell_map>1
            V0 = V;
            V(subs{1})          = V0(subs{cell_map});
            V(subs{cell_map})   = V0(subs{1});
            W0 = W;
            W(:,:,subs{1})          = W0(:,:,subs{cell_map});
            W(:,:,subs{cell_map})   = W0(:,:,subs{1});
            
            cell_map = 1;
        end
        
        sign_center = -squeeze(sign(W(dx,dx,:)));
        sign_center(:) = 1;
        Wi = reshape(W, lx^2, Nmaps);
        nW = max(abs(Wi), [], 1);
        %             nW = sum(Wi.^2, 1).^.5;
        
        Wi = Wi./repmat(sign_center' .* nW, lx*lx,1);
        
        figure(1); visualSS(Wi, 4, KS, [-1 1]); colormap('parula')
        
        figure(3);colormap('parula')
        
        ex      = ops.ex;
        H0      = H(:,ex);
        elem    = get_elem(H0, L, isfirst, KS);
        valid   = elem.map==cell_map;
        
        elem.iy(~valid) = [];
        elem.ix(~valid) = [];
        
        Im = y(:,:,ex);
        sig = nanstd(Im(:)); mu = nanmean(Im(:)); M1= mu - 4*sig; M2= mu + 12*sig;
        imagesc(Im, [M1 M2])
        
        hold on
        axis image
        plot(elem.iy, elem.ix, 'or', 'Linewidth', 2, 'MarkerSize', 4, 'MarkerFaceColor', 'r')
        
        %             xlim([100 250])
        %             ylim([100 250])
        hold off
        
        drawnow
        if FS.Stop()
            ops.warmup = 0;
            break;
        end
    end
end


%% write model parameters into model structure
model.W         = W;
model.tErr      = tErr;
model.Bias      = Bias;
model.Params    = Params;
model.Nmaps     = Nmaps;
model.isfirst   = isfirst;
model.pos       = pos;
model.subs      = subs;
model.dimSS     = dimSS;
model.NSS       = NSS;
model.KS        = KS;
model.cell_map  = cell_map;
model.PrVar     = PrVar;
model.Nmax      = Nmax;
model.sig1      = sig1;
model.sig2      = sig2;

save('CorrImgs_4Planes_model','model')

