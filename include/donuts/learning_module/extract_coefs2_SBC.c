#include "mex.h"
#include <math.h>
#define min(a,b) (((a)<(b))?(a):(b))
#define max(a,b) (((a)>(b))?(a):(b))

void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
        const mxArray *prhs[])
{
    int i, j, j0, k, ik, l, N, Nbatch, Nfree, Nmax, ind, L, lx, dx, Nmaps;
    int ix, iy, iz, ix2, iy2, xr, yr, zr, iW, iWtW, kl1, kl2;
    double *Wy, *W2, *WtW, *Params, *H, *X, *W, *y, *yres, B0;
    double lam, lmin, ValMin, *Vall, AbsMin, tErr, *Nact, *Active, *Bias, PrVar;
    double *Akki, *isfirst, *xk, wy0, *pos, *dLL;
    bool *Mask;
            
    N       = mxGetM(prhs[0]);
    Nbatch  = mxGetN(prhs[0]);
    /* Nbatch is the number of examples, N is the number of filters */
    
    Wy      = mxGetPr(prhs[0]); /* N by Nbatch */
    WtW     = mxGetPr(prhs[1]); /* N by N */
    Params  = mxGetPr(prhs[2]); /* 1 by 1 */
    Nmax   = (int) Params[0];
    tErr    = Params[1];
    PrVar   = Params[2];
    L       = (int) Params[3];
    lx       = (int) Params[4];
    dx      = lx/2;
    Nmaps       = (int) Params[5];
    y       = mxGetPr(prhs[3]);
    W       = mxGetPr(prhs[4]);
    Bias    = mxGetPr(prhs[5]);
    Akki    = mxGetPr(prhs[6]); /* Nmaps by Nmaps */
    isfirst    = mxGetPr(prhs[7]); /* N by 1 */
    pos    = mxGetPr(prhs[8]); /* N by 1 */
    
    plhs[0] = mxCreateDoubleMatrix(Nmax, Nbatch, mxREAL);
    H       = mxGetPr(plhs[0]);
    plhs[1] = mxCreateDoubleMatrix(Nmax, Nbatch, mxREAL);
    X       = mxGetPr(plhs[1]);    
    plhs[2] = mxCreateDoubleMatrix(L*L, Nbatch, mxREAL);
    yres    = mxGetPr(plhs[2]);
    plhs[3] = mxCreateDoubleMatrix(1, Nbatch, mxREAL);
    Nact    = mxGetPr(plhs[3]);
    plhs[4] = mxCreateDoubleMatrix(Nmaps, 1,mxREAL);
    Active  = mxGetPr(plhs[4]);
    plhs[5] = mxCreateDoubleMatrix(Nmax, Nbatch,mxREAL);
    dLL  = mxGetPr(plhs[5]);
        
    xk      = (double*) calloc(Nmaps * L * L, sizeof(double));
    Vall    = (double*) calloc(Nmaps * L * L, sizeof(double));
    Mask    = (bool*) calloc(L * L, sizeof(bool));
    
    for(i=0;i<L*L*Nbatch;i++)
        yres[i] = y[i];
    
    for (i=0;i<Nmax*Nbatch;i++)
        H[i] = -1;
    
    for (i=0; i<Nbatch; i++){
        Nact[i] = Nmax;
        
        for (j=0;j<L*L;j++)
            Mask[j] = true;
        
        for (j=0; j<Nmax-10;j++){
            if (abs(H[Nmax*i + j]+1)<1e-20){
                /* update delta_log_likelihoods */                
                for (k=0; k < Nmaps; k++)
                    if ((int) isfirst[k] ==1){
                        B0 = Bias[k];
                        
                        for (ix2=0; ix2 < L; ix2++)
                            for (iy2=0; iy2 < L; iy2++)
                                if ((j==0) || (j>0 && abs(ix-ix2)<lx && abs(iy-iy2)<lx)){
                                    l       = ix2 + iy2*L;                                    
                                    
                                    kl2     = k;
                                    while (1){
                                        xk[kl2*L*L+l] = 0.0f;
                                        kl2++;
                                        if (kl2==Nmaps || (int) isfirst[kl2]==1)
                                            break;
                                    }                                    
                                    
                                    kl1     = k;
                                    kl2     = k;
                                    wy0             = Wy[i*N + kl1*L*L+l];

                                    while (1){
                                        xk[kl2*L*L+l] += Akki[kl1*Nmaps + kl2] * wy0;

                                        kl2++;
                                        if (kl2==Nmaps || (int) isfirst[kl2]==1){
                                            kl2 = k;
                                            kl1 ++;
                                            if (kl1==Nmaps || (int) isfirst[kl1]==1)
                                                break;
                                            wy0     = Wy[i*N + kl1*L*L+l];
                                        }
                                    }

                                    kl1     = k;
                                    ValMin  = - B0;
                                    while (1){
                                        if (pos[kl1]>0)
                                            xk[kl1*L*L+l]  = max(0.0f, xk[kl1*L*L+l]);
                                        
                                        ValMin += -xk[kl1*L*L+l] * Wy[i*N + kl1*L*L+l];
                                        kl1 ++;
                                        if (kl1==Nmaps || (int) isfirst[kl1]==1)
                                            break;
                                    }
                                    Vall[k*L*L+l] = ValMin;
                                }
                    }

                /* find max */
                AbsMin = 10000000.0f;
                lam = 0;
                ind = -1;
                for (k=0; k < Nmaps; k++)
                    if ((int) isfirst[k] ==1)
                        for(l=0;l<L*L;l++)
                            if (Vall[k*L*L+l] < AbsMin && Mask[l]) 
                                {ind = k*L*L+l; AbsMin = Vall[k*L*L+l];}                                
                        
                    
                /* quit if likelihood is not increased */
                if (AbsMin > -tErr){
                    Nact[i] = j;
                    j = Nmax-1;
                    continue;
                }
                
                j0 = j;
                while (1){
                    H[Nmax*i + j0]  = ind;
                    X[Nmax*i + j0]  = xk[ind];
                    dLL[Nmax*i + j0] = AbsMin;
                    ind += L*L;
                    j0++;
                    iz = (int) floor(ind/(L*L));
                    if (iz==Nmaps || (int) isfirst[iz]==1 )
                        break;
                }
            }
            
            ind     = H[Nmax*i + j];
            lam     = X[Nmax*i + j];
            
            /* update the dot products and structure penalties*/
            iz = floor(ind/ (L*L)); ind = ind - L*L * iz; iy = floor(ind/L);
            ix = ind - L * iy;
            Active[iz] += 1;            
            
            
            for (yr=max(0, iy-4+1); yr<min(iy+4, L); yr++)
                    for (xr=max(0, ix-4+1); xr<min(ix+4, L); xr++)
                        Mask[yr*L + xr] = false;

            for (zr=0;zr<Nmaps;zr++)
                for (yr=max(0, iy-lx+1); yr<min(iy+lx, L); yr++)
                    for (xr=max(0, ix-lx+1); xr<min(ix+lx, L); xr++)
                    {
                iWtW = iz*(2*lx-1)*(2*lx-1)*Nmaps +
                        zr*(2*lx-1)*(2*lx-1) +
                        (yr+lx-iy-1)*(2*lx-1) + xr+lx-ix-1;
                Wy[zr*L*L + yr*L + xr] -= lam * WtW[iWtW];
                    }
            
            /*  update the residual image  */
            for (yr=max(0, iy-dx); yr<min(iy+dx+1, L); yr++)
                for (xr=max(0, ix-dx); xr<min(ix+dx+1, L); xr++){
                    iW = iz*lx*lx +(yr+dx-iy)*lx + xr+dx-ix;
                    yres[yr*L + xr] -= lam * W[iW];
                }

        }        
         
    }
    
    free(xk);
    free(Vall);
    return;
}