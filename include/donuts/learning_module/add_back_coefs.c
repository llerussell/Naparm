#include "mex.h" 
#include <math.h>
#define min(a,b) (((a)<(b))?(a):(b))
#define max(a,b) (((a)>(b))?(a):(b))

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, 
        const mxArray *prhs[])
{
    int i, j, counter, Nbatch, Nmax, ind, L, lx, dx;
    int ix, iy, iz, xr, yr, zr, iW, iW2;
    double *Params, *H,*dW, *yres, *yrec;
    double tErr, *X, *W, *imap, *Nact;
        
    Nbatch  = mxGetN(prhs[1]);
    /* Nbatch is the number of examples, N is the number of filters */
    
    yres      = mxGetPr(prhs[0]); /* N by Nbatch */
    H         = mxGetPr(prhs[1]); /* N by N */    
    Params         = mxGetPr(prhs[2]); /* N by N */    
    Nmax      = (int) Params[0];
    tErr      = Params[1];        
    L         = (int) Params[3];
    lx        = (int) Params[4];
    dx        = lx/2;    
    X         = mxGetPr(prhs[3]); /* N by N */
    W         = mxGetPr(prhs[4]); /* N by N */
    imap        = mxGetPr(prhs[5]);
    Nact        = mxGetPr(prhs[6]);

    for (i=0; i<Nbatch; i++)
        for (j=0;j<Nact[i];j++){
            ind = (int) H[Nmax*i+j];
            if (ind<0)
                break;
            
            iz = floor(ind/ (L*L)); ind = ind - L*L * iz; iy = floor(ind/L);
            ix = ind - L * iy;

            if (imap[iz]>0.5f)
                for (yr=max(0, iy-dx); yr<min(iy+dx+1, L); yr++)
                    for (xr=max(0, ix-dx); xr<min(ix+dx+1, L); xr++)
                    {            
                    iW2 = iz*lx*lx +(yr+dx-iy)*lx + xr+dx-ix;

                    yres[i*L*L + yr*L + xr] += X[Nmax*i+j] * W[iW2];

                    }
        }
    
}


