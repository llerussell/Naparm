/*
    Hologram generating algorithms for CUDA Devices
    Copyright 2009, 2010, 2011, 2012 Martin Persson
    martin.persson@physics.gu.se
    Small edits by Lloyd Russell 2016

    This file is part of GenerateHologramCUDA.
    GenerateHologramCUDA is free software: you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    GenerateHologramCUDA is distributed in the hope that it will be
    useful, but WITHOUT ANY WARRANTY; without even the implied warranty
    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.
    You should have received a copy of the GNU Lesser General Public License
    along with GenerateHologramCUDA.  If not, see <http://www.gnu.org/licenses/>.


    The function "GenerateHologram" contains two different algorithms for
    hologram generation. The last parameter in the function call selects which
    one to use:
    0: Complex addition of "Lenses and Prisms", no optimization (3D)
    1: Weighted Gerchberg-Saxton algorithm using Fresnel propagation (3D)
    2: Weighted Gerchberg-Saxton algorithm using Fast Fourier Transforms (2D)
        (0) produces optimal holograms for 1 or 2 traps and is significantly faster.
        (0) is automatically selected if the number of spots is < 3.

    Fresnel propagation based algorithm (1) described in:
    Roberto Di Leonardo, Francesca Ianni, and Giancarlo Ruocco
    "Computer generation of optimal holograms for optical trap arrays"
    Opt. Express 15, 1913-1922 (2007)
    The original algorithm has been modified to allow variable spot amplitudes

    Naming convention for variables:
    The prefix indicates where data is located
    In host functions:      h = host memory
                            d = device memory
                            c = constant memory
    In global functions:    g = global memory
                            s = shared memory
                            c = constant memory
                            no prefix = registers
    The suffix indicates the data type, no suffix usually indicates an integer

    Possible improvements:
    * Improve convergence of the GS algorithms for 2 spots.                         *done
    * Compensate spot intensities for distance from center of field.                *done
    * Put all arguments for device functions and trap positions in constant memory. *done
        (Requires all functions to be moved into the same file or the use of some
        workaround found on nVidia forum)
    * Put pSLMstart and aLaser in texture memory (may not improve performance on Fermi devices)
    * Use "zero-copy" to transfer pSLM to host.
    * Rename functions and variables for consistency and readability
    * Allow variable spot phases for Lenses and Prisms
*/

//#define M_CUDA_DEBUG			   //activates a number of custom debug macros//
float dt_milliseconds;
cudaEvent_t start, stop;

//Includes
#include <stdlib.h>
#include <stdio.h>
#include "stdint.h"
#include <string.h>
#include <math.h>
#include <cufft.h>

#ifndef M_PI
    #define M_PI 3.14159265358979323846f
#endif
#define MAX_SPOTS 1024	//decrease this if your GPU keeps running out of memory
#define BLOCK_SIZE 256	//should be a power of 2
#define SLM_SIZE 512
#if ((SLM_SIZE==16)||(SLM_SIZE==32)||(SLM_SIZE==64)||(SLM_SIZE==128)||(SLM_SIZE==256)||(SLM_SIZE==512)||(SLM_SIZE==1024)||(SLM_SIZE==2048))
    #define SLMPOW2			//Uses bitwize modulu operations if teh SLM size is a power of 2
#endif

// forward declarations
__global__ void ApplyCorrections(uint16_t *g_pSLM_uc, uint16_t *g_LUT, float *d_AberrationCorr_f, float *d_LUTPolCoeff_f);
__global__ void LensesAndPrisms(uint16_t *g_SLMuc, uint16_t *g_LUT, float *d_AberrationCorr_f, float *d_LUTPolCoeff_f);
__global__ void calculateIobtained(uint16_t *g_pSLM_uc, float *g_Iobtained);
__global__ void PropagateToSLM_Fresnel(float *g_spotRe_f, float *g_spotIm_f, float *g_pSLM2pi, float *g_weights, int iteration, float *g_pSLMstart, float *g_amps,
										bool getpSLM65535, uint16_t *g_pSLM65535_uc, uint16_t *g_LUT, float *g_AberrationCorr_f, float *g_LUTPolCoeff_f);
__global__ void PropagateToSLMDC_Fresnel(float *g_pSpot, float *g_wSpot, cufftComplex *g_cSLM_cc, float *g_pSLM_f, int iteration, float *g_pSLMstart, bool getpSLM65535,
										 uint16_t *g_pSLM65535_uc);
__global__ void setActiveRegionToZero(cufftComplex *g_Farfield);
__global__ void PropagateToSpotPositions_Fresnel(float *g_pSLM2pi, float *g_spotRe_f, float *g_spotIm_f);
__global__ void PropagateToSpotPositionsDC_Fresnel(float *g_pSLM_f, float *g_obtainedPhase, float *g_weights, float *g_Iobtained, int iteration);
__global__ void ReplaceAmpsSLM_FFT(float *g_aLaser, cufftComplex *g_cAmp, float *g_pSLMstart, bool getpSLM65535, uint16_t *g_pSLM65535_uc, uint16_t *g_LUT, float *g_AberrationCorr_f, float *g_LUTPolCoeff_f);
__global__ void ReplaceAmpsSpots_FFT(cufftComplex *g_cSpotAmp_cc, cufftComplex *g_cSpotAmpNew_cc, int iteration, float *g_Iobtained, float *g_weight, bool last_iteration);
__global__ void ReplaceAmpsSpotsDC_FFT(cufftComplex *g_cSpotAmp_cc, cufftComplex *g_cSpotAmpNew_cc, int iteration, float *g_Iobtained, float *g_weight, bool last_iteration);
__global__ void XYtoIndex();
__global__ void f2uc(uint16_t *uc, float *f, int N_pixels, uint16_t *g_LUT, int use_linLUT, int data_w);
__global__ void uc2f(float *f, uint16_t *uc, int N);
__global__ void p2c(cufftComplex *g_c, float *g_p, int M);
inline int computeAndCopySpotData(float *h_I, float *x, float *y, float *z, int N_spots, int method);

// Custom debug macros
#define M_CHECK_ERROR() mCheckError(__LINE__, __FILE__)
#define M_SAFE_CALL(errcode) mSafeCall(errcode, __LINE__, __FILE__)
#define M_CUFFT_SAFE_CALL(cuffterror) mCufftSafeCall(cuffterror, __LINE__, __FILE__)
#define M_DISPLAY_DATA_F(data, length) mDisplayDataF(data, length, __LINE__)
#define M_DISPLAY_DATA_UC(data, length) mDisplayDataUC(data, length, __LINE__)
#define M_DISPLAY_DATA_CC(data, length) mDisplayDataCC(data, length, __LINE__)
#define M_DISPLAY_DATA_I(data, length) mDisplayDataI(data, length, __LINE__)
inline void mSafeCall(cudaError_t status, int line, const char *file);
inline void mCufftSafeCall(cufftResult_t status, int line, const char *file);
inline void mCheckError(int line, const char *file);
inline void mDisplayDataF(float *d_data, int length, int line);
inline void mDisplayDataCC(cufftComplex *d_data, int length, int line);
inline void mDisplayDataUC(uint16_t *d_data, int length, int line);
inline void mDisplayDataI(int *d_data, int length, int line);

//Global declaration
float *d_x, *d_y, *d_z, *d_I;					//trap coordinates and intensity in GPU memory
float *d_pSLM_f;								//the optimized pSpot pattern, float [-pi, pi]
float *d_weights, *d_Iobtained, *d_desiredAmp;	//used h_weights and calculated amplitudes for each spot and each iteration
float *d_pSLMstart_f;							//Initial pSpot pattern [-pi, pi]
float *d_spotRe_f, *d_spotIm_f;
float *d_AberrationCorr_f = NULL;
float *d_LUTPolCoeff_f = NULL;
float SLMsizef = (float)SLM_SIZE;
int N_PolLUTCoeff = 0;
int n_blocks_Phi, memsize_SLM_f, memsize_SLMuc, memsize_spotsf, data_w, N_pixels, N_iterations_last;
float h_desiredAmp[MAX_SPOTS];
int h_spotIndex[MAX_SPOTS];
uint16_t *d_pSLM_uc;						//The optimized pSpot pattern, uint16_t, the one sent to the SLM [0, 65535]
uint16_t *h_LUT_uc;
uint16_t *d_LUT_uc = NULL;
int maxThreads_device;
bool ApplyLUT_b = false, EnableSLM_b = false, UseAberrationCorr_b = false, UsePolLUT_b = false, saveI_b = false, useRPC_b = false, useDC_b = false;
float alphaRPC_f = 10;
char CUDAmessage[100];
cudaError_t status;
float *d_aLaserFFT, *d_LUT_coeff;
cufftHandle plan;
cufftComplex *d_FFTo_cc, *d_FFTd_cc, *d_SLM_cc;
int *d_spot_index, memsize_SLMcc;
int borderWidthDC_i;
float *d_obtainedPhase;

//Constant memory declarations
__device__ __constant__ int c_data_w[1];
__device__ __constant__ float c_data_w_f[1];
__device__ __constant__ int c_half_w[1];
__device__ __constant__ float c_half_w_f[1];
__device__ __constant__ int c_N_pixels[1];
__device__ __constant__ float c_N_pixels_f[1];
__device__ __constant__ float c_SLMpitch_f[1];
__device__ __constant__ bool c_useDC_b[1];
__device__ __constant__ int c_DCborderWidth[1];
__device__ __constant__ bool c_useRPC_b[1];
__device__ __constant__ float c_alphaRPC_f[1];
__device__ __constant__ bool c_saveI_b[1];
__device__ __constant__ int c_log2data_w[1];
__device__ __constant__ float c_x[MAX_SPOTS];
__device__ __constant__ float c_y[MAX_SPOTS];
__device__ __constant__ float c_z[MAX_SPOTS];
__device__ __constant__ float c_desiredAmp[MAX_SPOTS];
__device__ __constant__ int c_spotIndex[MAX_SPOTS];
__device__ __constant__ int c_N_spots[1];

//Public dll functions
//Generate a hologram
extern "C" __declspec(dllexport)  int GenerateHologram(float *h_checkData, uint16_t *h_pSLM_uc, float *x_spots, float *y_spots, float *z_spots, float *I_spots, int N_spots, int N_iterations, float *h_Iobtained, int method)//, float* gpuTime)
{
	//*gpuTime = 0;
	//float deltaTime = 0;
	if (N_spots > MAX_SPOTS)
		N_spots = MAX_SPOTS;
	else if (N_spots < 1)
		method = 100;
	else if (N_spots < 3)
		method = 0;
	memsize_spotsf = N_spots*sizeof(float);
	method = computeAndCopySpotData(I_spots, x_spots, y_spots, z_spots, N_spots, method); //sets method to -1 if N_spots == 0.
	switch (method)	{
		case 0:
			//////
			//Generate the hologram using "Lenses and Prisms"
			//////
			LensesAndPrisms<<< n_blocks_Phi, BLOCK_SIZE >>>(d_pSLM_uc, d_LUT_uc, d_AberrationCorr_f, d_LUTPolCoeff_f);
			M_CHECK_ERROR();
			cudaDeviceSynchronize();
			M_CHECK_ERROR();
			if (saveI_b)
			{
				calculateIobtained<<< N_spots, SLM_SIZE>>>(d_pSLM_uc, d_Iobtained);
				M_CHECK_ERROR();
				cudaDeviceSynchronize();
				M_SAFE_CALL(cudaMemcpy(h_Iobtained, d_Iobtained, N_spots*sizeof(float), cudaMemcpyDeviceToHost));
			}
			M_SAFE_CALL(cudaMemcpy(h_pSLM_uc, d_pSLM_uc, memsize_SLMuc, cudaMemcpyDeviceToHost));
			break;
		case 1:
			//Generate holgram using fresnel propagation
			//Uncomment this to start with pre-calculated hologram:
			//cudaMemcpy(d_pSLM_uc, h_pSLM_uc, memsize_SLMuc, cudaMemcpyHostToDevice);
			//cudaDeviceSynchronize();
			//uc2f<<< n_blocks_Phi, BLOCK_SIZE >>>(d_pSLM_f, d_pSLM_uc, N_pixels);
			/*cudaEventCreate(&start);
			cudaEventCreate(&stop);
			cudaEventRecord(start, 0);
			cudaEventSynchronize(start);*/
			for (int l=0; l<N_iterations; l++)
			{
				//Propagate to the spot positions
				if (useDC_b)
				{
					M_CUFFT_SAFE_CALL(cufftExecC2C(plan, d_SLM_cc, d_FFTo_cc, CUFFT_FORWARD));
					M_CHECK_ERROR();
					PropagateToSpotPositionsDC_Fresnel<<< N_spots, SLM_SIZE>>>(d_pSLM_f, d_obtainedPhase, d_weights, d_Iobtained, l);  //this function is very slow
					M_CHECK_ERROR();
					setActiveRegionToZero<<< SLM_SIZE, SLM_SIZE >>>(d_FFTo_cc);
				}
				else
					PropagateToSpotPositions_Fresnel<<< N_spots, SLM_SIZE>>>(d_pSLM_f, d_spotRe_f, d_spotIm_f);
				M_CHECK_ERROR();
				cudaDeviceSynchronize();

				//Propagate to the SLM plane
				if (useDC_b)
				{
					M_CUFFT_SAFE_CALL(cufftExecC2C(plan, d_FFTo_cc, d_SLM_cc, CUFFT_INVERSE));
					cudaDeviceSynchronize();
					PropagateToSLMDC_Fresnel<<< n_blocks_Phi, BLOCK_SIZE >>>(d_obtainedPhase, d_weights, d_SLM_cc, d_pSLM_f, l, d_pSLMstart_f, (l==(N_iterations-1)), d_pSLM_uc);
				}
				else
				{
					PropagateToSLM_Fresnel<<< n_blocks_Phi, BLOCK_SIZE >>>(d_spotRe_f, d_spotIm_f, d_pSLM_f, d_weights, l, d_pSLMstart_f, d_Iobtained, (l==(N_iterations-1)), d_pSLM_uc, d_LUT_uc, d_AberrationCorr_f, d_LUTPolCoeff_f);
				}
				M_CHECK_ERROR();
				cudaDeviceSynchronize();
			}
			/*cudaEventRecord(stop, 0);
			cudaEventSynchronize(stop);
			cudaEventElapsedTime(&deltaTime, start, stop);
			*gpuTime = deltaTime;	*/
			if (saveI_b)
				M_SAFE_CALL(cudaMemcpy(h_Iobtained, d_Iobtained, N_spots*(N_iterations)*sizeof(float), cudaMemcpyDeviceToHost));
			else
				M_SAFE_CALL(cudaMemcpy(h_Iobtained, d_weights, N_spots*(N_iterations)*sizeof(float), cudaMemcpyDeviceToHost));
			M_SAFE_CALL(cudaMemcpy(h_pSLM_uc, d_pSLM_uc, memsize_SLMuc, cudaMemcpyDeviceToHost));
			break;
		case 2:
			//generate hologram using fast fourier transforms
			//Uncomment this to start with pre-calculated hologram:
			//cudaMemcpy(d_pSLM_uc, h_pSLM_uc, memsize_SLMuc, cudaMemcpyHostToDevice);
			//cudaDeviceSynchronize();
			//p_uc2c_cc_shift<<< n_blocks_Phi, BLOCK_SIZE >>>(d_SLM_cc, d_pSLM_uc, N_pixels, data_w);
			//M_DISPLAY_DATA_CC(d_SLM_cc, 100);
			M_SAFE_CALL(cudaMemcpy(d_desiredAmp, h_desiredAmp, memsize_spotsf, cudaMemcpyHostToDevice));
			M_SAFE_CALL(cudaMemset(d_FFTd_cc, 0, memsize_SLMcc));
			M_CHECK_ERROR();
			cudaDeviceSynchronize();
			for (int l=0; l<N_iterations; l++)
			{

				// Transform to trapping plane
				M_CUFFT_SAFE_CALL(cufftExecC2C(plan, d_SLM_cc, d_FFTo_cc, CUFFT_FORWARD));
				cudaDeviceSynchronize();

				// Copy phases for spot indices in d_FFTo_cc to d_FFTd_cc
				if (useDC_b)
					ReplaceAmpsSpotsDC_FFT <<< n_blocks_Phi, BLOCK_SIZE >>> (d_FFTo_cc, d_FFTd_cc, l, d_Iobtained, d_weights, (l==(N_iterations-1)));
				else
					ReplaceAmpsSpots_FFT <<< 1, N_spots >>> (d_FFTo_cc, d_FFTd_cc, l, d_Iobtained, d_weights, (l==(N_iterations-1)));
				M_CHECK_ERROR();
				cudaDeviceSynchronize();

				//Transform back to SLM plane
				M_CUFFT_SAFE_CALL(cufftExecC2C(plan, d_FFTd_cc, d_SLM_cc, CUFFT_INVERSE));
				cudaDeviceSynchronize();
				//M_DISPLAY_DATA_CC(d_SLM_cc, 100);

				// Set amplitudes in d_SLM to the laser amplitude profile
				ReplaceAmpsSLM_FFT <<< n_blocks_Phi, BLOCK_SIZE >>> (d_aLaserFFT, d_SLM_cc, d_pSLMstart_f, (l==(N_iterations-1)), d_pSLM_uc, d_LUT_uc, d_AberrationCorr_f, d_LUTPolCoeff_f);
				M_CHECK_ERROR();
				//M_DISPLAY_DATA_CC(d_SLM_cc, 100);
				cudaDeviceSynchronize();
			}
			if (saveI_b)
				M_SAFE_CALL(cudaMemcpy(h_Iobtained, d_Iobtained, N_spots*(N_iterations)*sizeof(float), cudaMemcpyDeviceToHost));
			else
				M_SAFE_CALL(cudaMemcpy(h_Iobtained, d_weights, N_spots*(N_iterations)*sizeof(float), cudaMemcpyDeviceToHost));
			M_SAFE_CALL(cudaMemcpy(h_pSLM_uc, d_pSLM_uc, memsize_SLMuc, cudaMemcpyDeviceToHost));
			break;
		default:
			break;
	}
	//Handle CUDA errors
	status = cudaGetLastError();
	return status;
}

//Allocate GPU memory
extern "C" __declspec(dllexport)  int startCUDA(float *h_pSLMstart, int deviceId)
{
	//Make sure GPU with desired deviceId exists, set deviceId to 0 if not
	int deviceCount=0;
	if (cudaGetDeviceCount(&deviceCount)!=0)
	if (deviceId>=deviceCount)
	{
		deviceId=0;
	}
	M_SAFE_CALL(cudaSetDevice(deviceId));
	cudaDeviceProp deviceProp;
    M_SAFE_CALL(cudaGetDeviceProperties(&deviceProp, deviceId));
    maxThreads_device = deviceProp.maxThreadsPerBlock;
	borderWidthDC_i = 0;
	int MaxIterations = 1000;
	data_w = SLM_SIZE;
	cudaMemcpyToSymbol(c_data_w, &data_w, sizeof(int), 0, cudaMemcpyHostToDevice);
	float data_w_f = (float)data_w;
	cudaMemcpyToSymbol(c_data_w_f, &data_w_f, sizeof(float), 0, cudaMemcpyHostToDevice);
	int half_w = (int)(data_w/2);
	cudaMemcpyToSymbol(c_half_w, &half_w, sizeof(int), 0, cudaMemcpyHostToDevice);
	float half_w_f = (float)data_w/2.0f;
	cudaMemcpyToSymbol(c_half_w_f, &half_w_f, sizeof(float), 0, cudaMemcpyHostToDevice);
	N_pixels = data_w * data_w;
	cudaMemcpyToSymbol(c_N_pixels, &N_pixels, sizeof(int), 0, cudaMemcpyHostToDevice);
	float N_pixels_f = (float)N_pixels;
	cudaMemcpyToSymbol(c_N_pixels_f, &N_pixels_f, sizeof(float), 0, cudaMemcpyHostToDevice);
	int logN = (int)(log2(data_w_f));
	cudaMemcpyToSymbol(c_log2data_w, &logN, sizeof(int), 0, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(c_useRPC_b, &useRPC_b, sizeof(bool), 0, cudaMemcpyHostToDevice);
	float SLMpitch_f = 1.0f/data_w_f;
	cudaMemcpyToSymbol(c_SLMpitch_f, &SLMpitch_f, sizeof(float), 0, cudaMemcpyHostToDevice);
	N_iterations_last = 10;
	memsize_spotsf = MAX_SPOTS * sizeof(float);
	memsize_SLM_f = N_pixels * sizeof(float);
    memsize_SLMuc = N_pixels * sizeof(uint16_t);
	memsize_SLMcc = N_pixels * sizeof(cufftComplex);
    n_blocks_Phi = (N_pixels/BLOCK_SIZE + (N_pixels%BLOCK_SIZE == 0 ? 0:1));

	//memory allocations for all methods
	M_SAFE_CALL(cudaMalloc((void**)&d_x, memsize_spotsf ));
	M_SAFE_CALL(cudaMalloc((void**)&d_y, memsize_spotsf ));
	M_SAFE_CALL(cudaMalloc((void**)&d_z, memsize_spotsf ));
	M_SAFE_CALL(cudaMalloc((void**)&d_I, memsize_spotsf ));
	M_SAFE_CALL(cudaMalloc((void**)&d_desiredAmp, memsize_spotsf ));
	M_SAFE_CALL(cudaMalloc((void**)&d_weights, MAX_SPOTS*(MaxIterations+1)*sizeof(float)));
	M_SAFE_CALL(cudaMalloc((void**)&d_Iobtained, MAX_SPOTS*MaxIterations*sizeof(float)));
	M_SAFE_CALL(cudaMalloc((void**)&d_obtainedPhase, memsize_spotsf ));
	M_SAFE_CALL(cudaMalloc((void**)&d_spotRe_f, memsize_spotsf ));
	M_SAFE_CALL(cudaMalloc((void**)&d_spotIm_f, memsize_spotsf ));
	int data_w_pow2 = pow(2, ceil(log((float)data_w)/log(2.0f)));
	M_SAFE_CALL(cudaMalloc((void**)&d_pSLM_f, data_w_pow2*data_w_pow2*sizeof(float)));//the size of d_pSLM_f must be a power of 2 for the summation algorithm to work
	M_SAFE_CALL(cudaMemset(d_pSLM_f, 0, data_w_pow2*data_w_pow2*sizeof(float)));
	M_SAFE_CALL(cudaMalloc((void**)&d_pSLMstart_f, memsize_SLM_f));
	M_SAFE_CALL(cudaMalloc((void**)&d_pSLM_uc, memsize_SLMuc));
	M_SAFE_CALL(cudaMemset(d_pSLMstart_f, 0, N_pixels*sizeof(float)));
	M_SAFE_CALL(cudaMemcpy(d_pSLM_f, h_pSLMstart, N_pixels*sizeof(float), cudaMemcpyHostToDevice));

	//memory allocations etc. for all FFT based Gerchberg-Saxton
	M_SAFE_CALL(cudaMalloc((void**)&d_spot_index, MAX_SPOTS * sizeof(int)));
	M_SAFE_CALL(cudaMalloc((void**)&d_FFTd_cc, memsize_SLMcc));
	M_SAFE_CALL(cudaMalloc((void**)&d_FFTo_cc, memsize_SLMcc));
	M_SAFE_CALL(cudaMalloc((void**)&d_SLM_cc, memsize_SLMcc));
	M_SAFE_CALL(cudaDeviceSynchronize());
	p2c <<< n_blocks_Phi, BLOCK_SIZE >>>(d_SLM_cc, d_pSLM_f, N_pixels);
	M_CHECK_ERROR();
	cudaDeviceSynchronize();
	M_CUFFT_SAFE_CALL(cufftPlan2d(&plan, data_w, data_w, CUFFT_C2C));
	float *h_aLaserFFT = (float *)malloc(memsize_SLM_f);

	status = cudaGetLastError();
	return status;
}

//Free GPU memory and shut down SLM
extern "C" __declspec(dllexport)  int stopCUDA()
{
	M_SAFE_CALL(cudaFree(d_x));
	M_SAFE_CALL(cudaFree(d_y));
	M_SAFE_CALL(cudaFree(d_z));
	M_SAFE_CALL(cudaFree(d_I));
	M_SAFE_CALL(cudaFree(d_weights));
	M_SAFE_CALL(cudaFree(d_Iobtained));
	M_SAFE_CALL(cudaFree(d_pSLM_f));
	M_SAFE_CALL(cudaFree(d_pSLMstart_f));
	M_SAFE_CALL(cudaFree(d_pSLM_uc));
	M_SAFE_CALL(cudaFree(d_FFTd_cc));
	M_SAFE_CALL(cudaFree(d_FFTo_cc));
	M_SAFE_CALL(cudaFree(d_SLM_cc));
	M_CUFFT_SAFE_CALL(cufftDestroy(plan));
	cudaDeviceReset();

	status = cudaGetLastError();
	return status;
}

//Device functions
__device__ float uc2phase(float uc)
{
	return (float)uc*2.0f*M_PI/65536.0f - M_PI;
}
__device__ uint16_t phase2uc(float phase2pi)
{
	return (uint16_t)floor((phase2pi + M_PI)*65536.0f / (2.0f * M_PI));
}
__device__ int phase2int32(float phase2pi)
{
	return (int)floor((phase2pi + M_PI)*65536.0f / (2.0f * M_PI));
}
__device__ float ApplyAberrationCorrection(float pSpot, float correction)
{
		pSpot = pSpot - correction;		//apply correction
		return (pSpot - (2.0f*M_PI) * floor((pSpot+M_PI) / (2.0f*M_PI))); //apply mod([-pi, pi], pSpot)
}
__device__ int getXint(int index)
{
#ifdef SLMPOW2
	int X_int = index&(c_data_w[0]-1);
#else
	float X_int= index%c_data_w[0];
#endif
	return X_int;
}
__device__ int getYint(int index, int X_int)
{
#ifdef SLMPOW2
 	int Y_int = (index-X_int)>>c_log2data_w[0];
#else
	int Y_int = (float)(floor((float)index/c_data_w_f[0]));
#endif
	return Y_int;
}
__device__ int fftshift(int idx, int X, int Y)
{
	if (X < c_half_w[0])
	{
		if (Y < c_half_w[0])
		{
			return idx + (c_data_w[0] * c_half_w[0]) + c_half_w[0];
		}
		else
		{
			return idx - (c_data_w[0] * c_half_w[0]) + c_half_w[0];
		}
	}
	else
	{
		if (Y < c_half_w[0])
		{
			return idx + (c_data_w[0] * c_half_w[0]) - c_half_w[0];
		}
		else
		{
			return idx - (c_data_w[0] * c_half_w[0]) - c_half_w[0];
		}
	}
}
__device__ void warpReduceC(volatile float *s_Vre, volatile float *s_Vim, int tid)
{
	s_Vre[tid] += s_Vre[tid + 32];
	s_Vim[tid] += s_Vim[tid + 32];
	s_Vre[tid] += s_Vre[tid + 16];
	s_Vim[tid] += s_Vim[tid + 16];
	s_Vre[tid] += s_Vre[tid + 8];
	s_Vim[tid] += s_Vim[tid + 8];
	s_Vre[tid] += s_Vre[tid + 4];
	s_Vim[tid] += s_Vim[tid + 4];
	s_Vre[tid] += s_Vre[tid + 2];
	s_Vim[tid] += s_Vim[tid + 2];
	s_Vre[tid] += s_Vre[tid + 1];
	s_Vim[tid] += s_Vim[tid + 1];
}
inline int computeAndCopySpotData(float *h_I, float *x, float *y, float *z, int N_spots, int method)
{
	//float Isum = 0.0f;
	//for (int i = 0; i<N_spots; i++)
	//	Isum += h_I[i];
	for (int j = 0; j<N_spots; j++)
	{
		float sincx_rec = (x[j]==0)? 1.0f:((M_PI*x[j]/SLMsizef)/sinf(M_PI*x[j]/SLMsizef));
		float sincy_rec = (y[j]==0)? 1.0f:((M_PI*y[j]/SLMsizef)/sinf(M_PI*y[j]/SLMsizef));
		h_desiredAmp[j] = (h_I[j] <= 0.0f) ? 1.0f:(sincx_rec * sincy_rec * sqrtf(h_I[j]/100)*SLMsizef*SLMsizef);
		if (method == 2)
			h_spotIndex[j] = ((int)(x[j])&(data_w-1))  + ((int)(y[j])&(data_w-1))* data_w;
	}
	cudaMemcpyToSymbol(c_x, x, N_spots*sizeof(float), 0, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(c_y, y, N_spots*sizeof(float), 0, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(c_z, z, N_spots*sizeof(float), 0, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(c_desiredAmp, h_desiredAmp, N_spots*sizeof(float), 0, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(c_N_spots, &N_spots, sizeof(int), 0, cudaMemcpyHostToDevice);
	if (method == 2)
		cudaMemcpyToSymbol(c_spotIndex, h_spotIndex, N_spots*sizeof(int), 0, cudaMemcpyHostToDevice);
	if (N_spots == 0)
		method = -1;
	return method;
}

//Apply corrections to precalculated hologram
__global__ void ApplyCorrections(uint16_t *g_pSLM_uc, uint16_t *g_LUT, float *g_AberrationCorr_f, float *g_LUTPolCoeff_f)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	float pSLM2pi_f = uc2phase(g_pSLM_uc[idx]);
	g_pSLM_uc[idx] = phase2uc(pSLM2pi_f);
}
//Calculate hologram using "Lenses and Prisms"
__global__ void LensesAndPrisms(uint16_t *g_SLMuc, uint16_t *g_LUT, float *d_AberrationCorr_f, float *d_LUTPolCoeff_f)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx < c_N_pixels[0])
	{
		//get pixel coordinates
		int X_int = getXint(idx);
		int Y_int = getYint(idx, X_int);
		float X = c_SLMpitch_f[0]*(X_int - c_half_w_f[0]);
		float Y = c_SLMpitch_f[0]*(Y_int - c_half_w_f[0]);
		float phase2pi;
		float SLMre = 0.0f;
		float SLMim = 0.0f;
		for (int ii=0; ii<c_N_spots[0]; ++ii)
		{
			//add variable phases to function call
			phase2pi = M_PI * c_z[ii] * (X*X + Y*Y) + 2.0f * M_PI * (X * (c_x[ii]) + Y * (c_y[ii]) );
			SLMre = SLMre + c_desiredAmp[ii] * cosf(phase2pi);
			SLMim = SLMim + c_desiredAmp[ii] * sinf(phase2pi);
		}
		phase2pi = atan2f(SLMim, SLMre);	// [-pi,pi]
		g_SLMuc[idx] = phase2uc(phase2pi);
	}
}
__global__ void calculateIobtained(uint16_t *g_pSLM_uc, float *g_Iobtained)
{
	int blockSize = c_data_w[0];
	int spot_number = blockIdx.x;
	int tid = threadIdx.x;
	int i = tid;
	__shared__ float s_Vre[SLM_SIZE];
	__shared__ float s_Vim[SLM_SIZE];
	s_Vre[tid] = 0.0f;
	s_Vim[tid] = 0.0f;
	float X = c_SLMpitch_f[0] * ((float)tid - c_half_w_f[0]);
	float Y = - c_SLMpitch_f[0] * c_half_w_f[0];
	float pSLM_1;
	float p;
	while (i < c_N_pixels[0])
	{
		pSLM_1 = 2.0f*M_PI*(float)g_pSLM_uc[i]/65535.0f - M_PI;
		p = pSLM_1 - M_PI * (c_z[spot_number] * (X*X + Y*Y) + 2 * (X * c_x[spot_number] + Y * c_y[spot_number]));
		s_Vre[tid] += cosf(p);
		s_Vim[tid] += sinf(p);
		i += blockSize;
		Y += c_SLMpitch_f[0];
	}
	/*__syncthreads();
	if (tid < 512)
	{
		s_Vre[tid] += s_Vre[tid + 512];
		s_Vim[tid] += s_Vim[tid + 512];
	} */
	__syncthreads();
	if ((tid < 256)&&(SLM_SIZE>256))
	{
		s_Vre[tid] += s_Vre[tid + 256];
		s_Vim[tid] += s_Vim[tid + 256];
	}
	__syncthreads();
	if (tid < 128)
	{
		s_Vre[tid] += s_Vre[tid + 128];
		s_Vim[tid] += s_Vim[tid + 128];
	}
	__syncthreads();
	if (tid < 64)
	{
		s_Vre[tid] += s_Vre[tid + 64];
		s_Vim[tid] += s_Vim[tid + 64];
	}
	__syncthreads();
	if (tid < 32)
		warpReduceC(s_Vre, s_Vim, tid);
	if (tid == 0)
	{
		float spotRe_f = s_Vre[0] / c_N_pixels_f[0];			//512!
		float spotIm_f = s_Vim[0] / c_N_pixels_f[0];
		float amp = hypotf(spotRe_f, spotIm_f);
		g_Iobtained[spot_number] = amp*amp;
	}
}
__global__ void calculateIandPhase(uint16_t *g_pSLM_uc, float *g_Iobtained, float *g_Pobtained)
{
	int blockSize = c_data_w[0];
	int spot_number = blockIdx.x;
	int tid = threadIdx.x;
	int i = tid;
	__shared__ float s_Vre[SLM_SIZE];
	__shared__ float s_Vim[SLM_SIZE];
	s_Vre[tid] = 0.0f;
	s_Vim[tid] = 0.0f;
	float X = c_SLMpitch_f[0] * ((float)tid - c_half_w_f[0]);
	float Y = - c_SLMpitch_f[0] * c_half_w_f[0];
	float pSLM_1;
	float p;
	while (i < c_N_pixels[0])
	{
		pSLM_1 = 2.0f*M_PI*(float)g_pSLM_uc[i]/65535.0f - M_PI;
		p = pSLM_1 - M_PI * (c_z[spot_number] * (X*X + Y*Y) + 2 * (X * c_x[spot_number] + Y * c_y[spot_number]));
		s_Vre[tid] += cosf(p+2*M_PI*c_z[spot_number]);
		s_Vim[tid] += sinf(p+2*M_PI*c_z[spot_number]);
		i += blockSize;
		Y += c_SLMpitch_f[0];
	}
	/*__syncthreads();
	if (tid < 512)
	{
		s_Vre[tid] += s_Vre[tid + 512];
		s_Vim[tid] += s_Vim[tid + 512];
	} */
	__syncthreads();
	if ((tid < 256)&&(SLM_SIZE>256))
	{
		s_Vre[tid] += s_Vre[tid + 256];
		s_Vim[tid] += s_Vim[tid + 256];
	}
	__syncthreads();
	if (tid < 128)
	{
		s_Vre[tid] += s_Vre[tid + 128];
		s_Vim[tid] += s_Vim[tid + 128];
	}
	__syncthreads();
	if (tid < 64)
	{
		s_Vre[tid] += s_Vre[tid + 64];
		s_Vim[tid] += s_Vim[tid + 64];
	}
	__syncthreads();
	if (tid < 32)
		warpReduceC(s_Vre, s_Vim, tid);
	if (tid == 0)
	{
		float spotRe_f = s_Vre[0] / c_N_pixels_f[0];			//512!
		float spotIm_f = s_Vim[0] / c_N_pixels_f[0];
		float amp = hypotf(spotRe_f, spotIm_f);
		g_Pobtained[spot_number] = atan2f(spotIm_f , spotRe_f);
		g_Iobtained[spot_number] = amp*amp;
	}
}

//Functions for GS with Fresnel propagation

//Propagate from the SLM to the spot positions using Fresnel summation
//works only for blocksize = SLMsize
__global__ void PropagateToSpotPositions_Fresnel(float *g_pSLM2pi, float *g_spotRe_f, float *g_spotIm_f)
{
	int spot_number = blockIdx.x;
	int tid = threadIdx.x;
	int i = tid;
	__shared__ float s_Vre[SLM_SIZE];
	__shared__ float s_Vim[SLM_SIZE];
	s_Vre[tid] = 0.0f;
	s_Vim[tid] = 0.0f;
	int blockSize = blockDim.x;
	float X = c_SLMpitch_f[0] * ((float)tid - c_half_w_f[0]);
	float Y = - c_SLMpitch_f[0] * c_half_w_f[0];
	float p;
	while (i < c_N_pixels[0])
	{
		p = g_pSLM2pi[i] - M_PI * (c_z[spot_number] * (X*X + Y*Y) + 2.0f * (X * c_x[spot_number] + Y * c_y[spot_number]));
		s_Vre[tid] += cosf(p);
		s_Vim[tid] += sinf(p);
		i += blockSize;
		Y += c_SLMpitch_f[0];
	}
	/*__syncthreads();
	if (tid < 512)
	{
		s_Vre[tid] += s_Vre[tid + 512];
		s_Vim[tid] += s_Vim[tid + 512];
	} */
	__syncthreads();
	if ((tid < 256)&&(SLM_SIZE>256))
	{
		s_Vre[tid] += s_Vre[tid + 256];
		s_Vim[tid] += s_Vim[tid + 256];
	}
	__syncthreads();
	if (tid < 128)
	{
		s_Vre[tid] += s_Vre[tid + 128];
		s_Vim[tid] += s_Vim[tid + 128];
	}
	__syncthreads();
	if (tid < 64)
	{
		s_Vre[tid] += s_Vre[tid + 64];
		s_Vim[tid] += s_Vim[tid + 64];
	}
	__syncthreads();
	if (tid < 32)
		warpReduceC(s_Vre, s_Vim, tid);
	if (tid == 0)
	{
		g_spotRe_f[spot_number] = s_Vre[0];// / c_N_pixels_f[0];
		g_spotIm_f[spot_number] = s_Vim[0];// / c_N_pixels_f[0];
	}
}
//Propagate from the SLM to the spot positions using Fresnel summation
//works only for blocksize = SLMsize
__global__ void PropagateToSpotPositionsDC_Fresnel(float *g_pSLM_f, float *g_obtainedPhase, float *g_weights, float *obtainedI, int iteration)
{
	int spot_number = blockIdx.x;
	int tid = threadIdx.x;
	int i = tid;
	__shared__ float s_Vre[SLM_SIZE];
	__shared__ float s_Vim[SLM_SIZE];
	float X, Y;
	float p;
	s_Vre[tid] = 0.0f;
	s_Vim[tid] = 0.0f;
	int X_int = getXint(i);
	X = c_SLMpitch_f[0]*(X_int - c_half_w_f[0]);
	Y = -0.5f;
	while (i < c_N_pixels[0])
	{
		p = g_pSLM_f[i] - M_PI * (c_z[spot_number] * (X*X + Y*Y) + 2.0f * (X * c_x[spot_number] + Y * c_y[spot_number]));
		s_Vre[tid] += cosf(p);
		s_Vim[tid] += sinf(p);
		Y += c_SLMpitch_f[0];
		i += SLM_SIZE;
	}
	__syncthreads();
	if ((tid < 256)&&(SLM_SIZE>256))
	{
		s_Vre[tid] += s_Vre[tid + 256];
		s_Vim[tid] += s_Vim[tid + 256];
	}
	__syncthreads();
	if (tid < 128)
	{
		s_Vre[tid] += s_Vre[tid + 128];
		s_Vim[tid] += s_Vim[tid + 128];
	}
	__syncthreads();
	if (tid < 64)
	{
		s_Vre[tid] += s_Vre[tid + 64];
		s_Vim[tid] += s_Vim[tid + 64];
	}
	__syncthreads();
	if (tid < 32)
		warpReduceC(s_Vre, s_Vim, tid);
	if (tid == 0)
	{
		g_obtainedPhase[spot_number] = atan2f(s_Vim[0], s_Vre[0]);
		float obtainedAmp = hypotf(s_Vre[0], s_Vim[0]);
		float desiredAmp = c_desiredAmp[spot_number];
		if (iteration != 0)
		{
			g_weights[spot_number + c_N_spots[0]*iteration] = g_weights[spot_number + c_N_spots[0]*(iteration-1)] * (desiredAmp / obtainedAmp);
		}
		else
		{
			//obtainedAmp = (obtainedAmp<0.5f) ? 0.5f : obtainedAmp;
			g_weights[spot_number] = desiredAmp/c_N_pixels_f[0];
		}
		if (c_saveI_b[0])
			obtainedI[spot_number + c_N_spots[0]*iteration] = obtainedAmp*obtainedAmp/(desiredAmp*desiredAmp);//(c_N_pixels_f[0]*c_N_pixels_f[0]);
	}
}
//Obtain phases in SLM plane
__global__ void PropagateToSLM_Fresnel(float *g_spotRe_f, float *g_spotIm_f, float *g_pSLM2pi, float *g_weights, int iteration, float *g_pSLMstart, float *g_Iobtained, bool getpSLM65535, uint16_t *g_pSLM65535_uc,
								uint16_t *g_LUT, float *g_AberrationCorr_f, float *g_LUTPolCoeff_f)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int tid = threadIdx.x;
	__shared__ float s_aSpot[MAX_SPOTS], s_aSpotsMean, s_weight[MAX_SPOTS], s_pSpot[MAX_SPOTS];
	float reSLM = 0.0f, imSLM = 0.0f, pSLM2pi_f = 0.0f;
	if (idx<c_N_pixels[0])
	{
		if (tid<c_N_spots[0])
		{
			float spotRe_f = g_spotRe_f[tid];
			float spotIm_f = g_spotIm_f[tid];
			s_pSpot[tid] = atan2f(spotIm_f, spotRe_f);
			s_aSpot[tid] = hypotf(spotRe_f, spotIm_f)/c_desiredAmp[tid];
			if (iteration != 0)
				s_weight[tid] = g_weights[tid + iteration*c_N_spots[0]];
			else
			{
				s_aSpot[tid] = (s_aSpot[tid]<0.5f) ? 0.5f : s_aSpot[tid];
				s_weight[tid] = c_desiredAmp[tid];
			}
		}
		__syncthreads();
		//compute weights
		if  (tid==0)
		{
			float s_aSpot_sum = 0.0f;
			for (int jj=0; jj<c_N_spots[0];jj++)
			{
				s_aSpot_sum += s_aSpot[jj];
			}
			s_aSpotsMean = s_aSpot_sum / (float)c_N_spots[0];
		}
		__syncthreads();
		if (tid<c_N_spots[0])
		{
			s_weight[tid] = s_weight[tid] * s_aSpotsMean / s_aSpot[tid];
			if (!getpSLM65535)											//Copy weights to use as initial value next run
				g_weights[tid + c_N_spots[0]*(iteration+1)] = s_weight[tid];
			//else
			//	g_weights[tid] = s_weight[tid];							//Transferring weights to next run may give diverging weights
			if (c_saveI_b[0])
				g_Iobtained[tid + c_N_spots[0]*iteration] = s_aSpot[tid]*s_aSpot[tid];			//may be excluded, used for monitoring only
		}
		__syncthreads();
		//get pixel coordinates
		int X_int = getXint(idx);
		int Y_int = getYint(idx, X_int);
		float X = c_SLMpitch_f[0]*(X_int - c_half_w_f[0]);
		float Y = c_SLMpitch_f[0]*(Y_int - c_half_w_f[0]);
		//compute SLM pSpot by summing contribution from all spots
		for (int k=0; k<c_N_spots[0]; k++)
		{
			float delta = M_PI * c_z[k] * (X*X + Y*Y) + 2.0f * M_PI * (X * c_x[k] + Y * c_y[k]);
			reSLM += s_weight[k] * cosf(s_pSpot[k] + delta);
			imSLM += s_weight[k] * sinf(s_pSpot[k] + delta);
		}
		pSLM2pi_f = atan2f(imSLM, reSLM);
		if (c_useRPC_b[0])			//Apply RPC (restricted Phase Change)
		{
			float pSLMstart = g_pSLMstart[idx];
			if (fabs(pSLM2pi_f - pSLMstart) > c_alphaRPC_f[0])
				pSLM2pi_f = pSLMstart;
			if (getpSLM65535)
				g_pSLMstart[idx] = pSLM2pi_f;
		}
		if (getpSLM65535)					//Compute final SLM phases and write to global memory...
			g_pSLM65535_uc[idx] = phase2uc(pSLM2pi_f);
		g_pSLM2pi[idx] = pSLM2pi_f;	//...or write intermediate pSpot to global memory
	}
}
//Obtain phases in SLM plane
__global__ void PropagateToSLMDC_Fresnel(float *g_pSpot, float *g_wSpot, cufftComplex *g_cSLM_cc, float *g_pSLM_f, int iteration, float *g_pSLMstart, bool getpSLM65535,
										 uint16_t *g_pSLM65535_uc)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int tid = threadIdx.x;
	__shared__ float s_weight[MAX_SPOTS], s_pSpot[MAX_SPOTS];
	float reSLM = 0.0f, imSLM = 0.0f, pSLM2pi_f = 0.0f;
	if (idx<c_N_pixels[0])
	{
		if (tid<c_N_spots[0])
		{
			s_pSpot[tid] = g_pSpot[tid];
			s_weight[tid] = g_wSpot[tid+c_N_spots[0]*iteration];
		}
		__syncthreads();
		//get pixel coordinates
		int X_int = getXint(idx);
		int Y_int = getYint(idx, X_int);
		int shiftedidx = fftshift(idx, X_int, Y_int);
		float X = c_SLMpitch_f[0]*(X_int - c_half_w_f[0]);
		float Y = c_SLMpitch_f[0]*(Y_int - c_half_w_f[0]);
		//compute SLM pSpot by summing contribution from all spots
		for (int k=0; k<c_N_spots[0]; k++)
		{
			float delta = M_PI * c_z[k] * (X*X + Y*Y) + 2.0f * M_PI * (X * c_x[k] + Y * c_y[k]);
			reSLM += s_weight[k] * cosf(s_pSpot[k] + delta);
			imSLM += s_weight[k] * sinf(s_pSpot[k] + delta);
		}
		cufftComplex cSLM_cc = g_cSLM_cc[shiftedidx];
		reSLM += cSLM_cc.x/c_N_pixels_f[0];
		imSLM += cSLM_cc.y/c_N_pixels_f[0];
		pSLM2pi_f = atan2f(imSLM, reSLM);
		if (c_useRPC_b[0])			//Apply RPC (restricted Phase Change)
		{
			float pSLMstart = g_pSLMstart[shiftedidx];
			if (fabs(pSLM2pi_f - pSLMstart) > c_alphaRPC_f[0])
				pSLM2pi_f = pSLMstart;
			if (getpSLM65535)
				g_pSLMstart[shiftedidx] = pSLM2pi_f;
		}
		g_pSLM_f[idx] = pSLM2pi_f;
		g_cSLM_cc[shiftedidx].x = cosf(pSLM2pi_f);
		g_cSLM_cc[shiftedidx].y = sinf(pSLM2pi_f);
		if (getpSLM65535)					//Compute final SLM phases and write to global memory...
			g_pSLM65535_uc[idx] = phase2uc(pSLM2pi_f);
	}
}
//Clear inside the DC frame
__global__ void setActiveRegionToZero(cufftComplex *g_Farfield_cc) //this only works if blocksize = nblocks = SLMsize = 512
{
	int tid = threadIdx.x;
	int bid = blockIdx.x;
	int idx = bid * blockDim.x + tid;
	if (((tid < (c_half_w[0] - c_DCborderWidth[0]))||(tid > ((c_half_w[0]-1) + c_DCborderWidth[0])))&&((bid < (c_half_w[0] - c_DCborderWidth[0]))||(bid > ((c_half_w[0]-1) + c_DCborderWidth[0]))))
	{
		g_Farfield_cc[idx].x = 0.0f;
		g_Farfield_cc[idx].y = 0.0f;
	}
}

//Functions for GS with FFT propagation

//Compute the phase in SLM pixels and set amplitude to unity or Laser amp
__global__ void ReplaceAmpsSLM_FFT(float *g_aLaser, cufftComplex *g_cAmp, float *g_pSLMstart, bool getpSLM65535, uint16_t *g_pSLM65535_uc,
								uint16_t *g_LUT, float *g_AberrationCorr_f, float *g_LUTPolCoeff_f)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx<c_N_pixels[0])
	{
		float aLaser = 1.0f;//g_aLaser[idx];
		cufftComplex cAmp = g_cAmp[idx];
 		float pSLM2pi_f = atan2f(cAmp.y, cAmp.x);
 		if (c_useRPC_b[0])
		{
			float pSLMstart = g_pSLMstart[idx];
			if (fabs(pSLM2pi_f - pSLMstart) > c_alphaRPC_f[0])
				pSLM2pi_f = pSLMstart;
		}
		if (getpSLM65535)
		{
			if (c_useRPC_b[0])
				g_pSLMstart[idx] = pSLM2pi_f;
			//float phase65535;
			int X_int = getXint(idx);
			int Y_int = getYint(idx, X_int);
			int shiftedidx = fftshift(idx, X_int, Y_int);
			g_pSLM65535_uc[shiftedidx] = phase2uc(pSLM2pi_f);
		}
		g_cAmp[idx].x = aLaser*cosf(pSLM2pi_f);
		g_cAmp[idx].y = aLaser*sinf(pSLM2pi_f);
	}
	__syncthreads();
}

//Adjust amplitudes in spot positions
__global__ void ReplaceAmpsSpots_FFT(cufftComplex *g_cSpotAmp_cc, cufftComplex *g_cSpotAmpNew_cc, int iteration, float *g_Iobtained, float *g_weight, bool last_iteration)
{
	int tid = threadIdx.x;
	int spotIndex;
	float pSpot;
	__shared__ float s_aSpot[MAX_SPOTS], s_ISpotsMeanSq;
	float weight;
	cufftComplex cSpotAmp_cc;
	if (tid<c_N_spots[0])
	{
		spotIndex = c_spotIndex[tid];
		cSpotAmp_cc = g_cSpotAmp_cc[spotIndex];
		pSpot = atan2f(cSpotAmp_cc.y, cSpotAmp_cc.x);
		s_aSpot[tid] = hypotf(cSpotAmp_cc.x, cSpotAmp_cc.y)/c_desiredAmp[tid];
		if (iteration != 0)
			weight = g_weight[tid + iteration*c_N_spots[0]];
		else
		{
			s_aSpot[tid] = (s_aSpot[tid]<0.5f) ? 0.5f : s_aSpot[tid];
			weight = c_desiredAmp[tid];
		}
	}
	__syncthreads();
	//compute weights
	if  (tid==0)
	{
		float ISpot_sum = 0.0f;
		for (int jj=0; jj<c_N_spots[0];jj++)
		{
			ISpot_sum += s_aSpot[jj]*s_aSpot[jj];
		}
		s_ISpotsMeanSq = sqrtf(ISpot_sum / (float)c_N_spots[0]);				//integer division!!
	}
	__syncthreads();
	if (tid<c_N_spots[0])
	{
		weight = weight * s_ISpotsMeanSq / s_aSpot[tid];
		cSpotAmp_cc.x = cosf(pSpot) * weight;
		cSpotAmp_cc.y = sinf(pSpot) * weight;
		g_cSpotAmpNew_cc[spotIndex] = cSpotAmp_cc;
		if (last_iteration)
			g_weight[tid] = weight;
		else
			g_weight[c_N_spots[0] * (iteration + 1) + tid] = weight;
		if (c_saveI_b[0])
			g_Iobtained[c_N_spots[0] * (iteration) + tid] = s_aSpot[tid]*s_aSpot[tid];
	}
}

//Adjust amplitudes in spot positions
__global__ void ReplaceAmpsSpotsDC_FFT(cufftComplex *g_cSpotAmp_cc, cufftComplex *g_cSpotAmpNew_cc, int iteration, float *g_Iobtained, float *g_weight, bool last_iteration)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int spotIndex;
	float pSpot;
	//__shared__ float s_aSpot[MAX_SPOTS], s_ISpotsMeanSq;
	float weight;
	cufftComplex cSpotAmp_cc;
	if (idx<c_N_spots[0])
	{
		spotIndex = c_spotIndex[idx];
		cSpotAmp_cc = g_cSpotAmp_cc[spotIndex];
		pSpot = atan2f(cSpotAmp_cc.y, cSpotAmp_cc.x);
		float aSpot = hypotf(cSpotAmp_cc.x, cSpotAmp_cc.y)/c_desiredAmp[idx];
		if (iteration != 0)
			weight = g_weight[idx + iteration*c_N_spots[0]];
		else
		{
			aSpot = (aSpot<0.5f) ? 0.5f : aSpot; //ska det vara så här med DC?
			weight = c_desiredAmp[idx]/(c_N_pixels_f[0]);
		}
		weight = weight / aSpot;
		cSpotAmp_cc.x = cosf(pSpot) * weight;
		cSpotAmp_cc.y = sinf(pSpot) * weight;
		g_cSpotAmpNew_cc[spotIndex] = cSpotAmp_cc;
		if (last_iteration)
			g_weight[idx] = weight;
		else
			g_weight[c_N_spots[0] * (iteration + 1) + idx] = weight;
		if (c_saveI_b[0])
			g_Iobtained[c_N_spots[0] * (iteration) + idx] = aSpot*aSpot;
	}
	int X_int = getXint(idx);
	int Y_int = getYint(idx, X_int);
	if (((X_int > (c_half_w[0] - c_DCborderWidth[0]))&&(X_int < ((c_half_w[0]-1) + c_DCborderWidth[0])))||((Y_int > (c_half_w[0] - c_DCborderWidth[0]))&&(Y_int < ((c_half_w[0]-1) + c_DCborderWidth[0]))))
	{
		g_cSpotAmpNew_cc[idx].x = g_cSpotAmp_cc[idx].x/(c_N_pixels_f[0]);
		g_cSpotAmpNew_cc[idx].y = g_cSpotAmp_cc[idx].y/(c_N_pixels_f[0]);
	}
}

//Misc help functions

__global__ void testfunc(float *testdata)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	testdata[idx] = idx;
}
//Convert from uint16_t [0, 65535] to float [-pi, pi]
__global__ void uc2f(float *f, uint16_t *uc, int N)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx<N)
	{
		f[idx] = uc[idx]*2.0f*M_PI/65536.0f - M_PI;
	}
}
//Calculate complex from phases
__global__ void p2c(cufftComplex *g_c, float *g_p, int M)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx<M)
	{
		float pSpot = g_p[idx];
 		g_c[idx].x = cosf(pSpot);
		g_c[idx].y = sinf(pSpot);
	}
	__syncthreads();
}

//Calculate amplitudes from complex
__global__ void c_cc2a_f(float *g_a, cufftComplex *g_c, int M)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx<M)
	{
		g_a[idx] = hypotf(g_c[idx].x, g_c[idx].y);
	}
	__syncthreads();
}
//Calculate phases from complex
__global__ void c_cc2p_cc(cufftComplex *g_p, cufftComplex *g_c, int M)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx<M)
	{
		g_p[idx].x = atan2f(g_c[idx].y, g_c[idx].x);
		g_p[idx].y = 0.0f;
	}
	__syncthreads();
}
//Calculate phases from complex
__global__ void c_cc2p_f(float *g_p, cufftComplex *g_c, int M)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx<M)
	{
		g_p[idx] = atan2f(g_c[idx].y, g_c[idx].x);
	}
	__syncthreads();
}

//Copy real part from complex
__global__ void c_cc2re_f(float *g_p, cufftComplex *g_c, int M)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx<M)
	{
		g_p[idx] = g_c[idx].x;
	}
	__syncthreads();
}
//Copy imaginary part from complex
__global__ void c_cc2im_f(float *g_p, cufftComplex *g_c, int M)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx<M)
	{
		g_p[idx] = g_c[idx].y;
	}
	__syncthreads();
}

//Custom debug functions

inline void mSafeCall(cudaError_t status, int line, const char *file)
{
#ifdef M_CUDA_DEBUG
	do
	{
		if(status != cudaSuccess)
		{
			char CUDAmessage[200] = "CUDA says: ";
			strcat(CUDAmessage,	cudaGetErrorString(status));
			sprintf(CUDAmessage,	"%s\non line: %d\n", CUDAmessage, line);
			//AfxMessageBox(CUDAmessage);
			if (status != CUFFT_SUCCESS)
			exit(-1);
		}
		cudaDeviceSynchronize();
		status = cudaGetLastError();
		if(status!=cudaSuccess)
		{
			char CUDAmessage[200] = "CUDA failed after sychronization:\n";
			strcat(CUDAmessage,	cudaGetErrorString(status));
			sprintf(CUDAmessage,	"%s\non line: %d\n", CUDAmessage, line);
			//AfxMessageBox(CUDAmessage);
			exit(-1);
		}
	}while(0);
#endif
	return;
}
inline void mCufftSafeCall(cufftResult_t status, int line, const char *file)
{
#ifdef M_CUDA_DEBUG
	if(status != CUFFT_SUCCESS)
	{
		char CUDAmessage[200] = "CUFFT error, CUDA says:\n ";
		switch (status) {
            case CUFFT_INVALID_PLAN:   strcat(CUDAmessage,"CUFFT_INVALID_PLAN\n");break;
            case CUFFT_ALLOC_FAILED:   strcat(CUDAmessage,"CUFFT_ALLOC_FAILED\n");break;
            case CUFFT_INVALID_TYPE:   strcat(CUDAmessage,"CUFFT_INVALID_TYPE\n");break;
            case CUFFT_INVALID_VALUE:  strcat(CUDAmessage,"CUFFT_INVALID_VALUE\n");break;
            case CUFFT_INTERNAL_ERROR: strcat(CUDAmessage,"CUFFT_INTERNAL_ERROR\n");break;
            case CUFFT_EXEC_FAILED:    strcat(CUDAmessage,"CUFFT_EXEC_FAILED\n");break;
            case CUFFT_SETUP_FAILED:   strcat(CUDAmessage,"CUFFT_SETUP_FAILED\n");break;
            case CUFFT_INVALID_SIZE:   strcat(CUDAmessage,"CUFFT_INVALID_SIZE\n");break;
            case CUFFT_UNALIGNED_DATA: strcat(CUDAmessage,"CUFFT_UNALIGNED_DATA\n");break;
            default: strcat(CUDAmessage,"CUFFT Unknown error code\n");
		}
		sprintf(CUDAmessage,	"%son line: %d\nin file: %s", CUDAmessage, line, file);
		//AfxMessageBox(CUDAmessage);
		exit(-1);
	}
	cudaDeviceSynchronize();
	cudaError_t status2 = cudaGetLastError();
	if(status2!=cudaSuccess)
	{
			char CUDAmessage[200] = "CUDA failed after sychronization:\n";
			strcat(CUDAmessage,	cudaGetErrorString(status2));
			sprintf(CUDAmessage,	"%s\non line: %d\n", CUDAmessage, line);
			//AfxMessageBox(CUDAmessage);
			exit(-1);
	}
#endif
	return;
}
inline void mCheckError(int line, const char *file)
{
#ifdef M_CUDA_DEBUG
	do
	{
		cudaError_t status = cudaGetLastError();
		if(status!=cudaSuccess)
		{
			char CUDAmessage[200] = "CUDA says: ";
			strcat(CUDAmessage,	cudaGetErrorString(status));
			sprintf(CUDAmessage,	"%s\non line: %d\n", CUDAmessage, line);
			//AfxMessageBox(CUDAmessage);
			exit(-1);
		}
		cudaDeviceSynchronize();
		status = cudaGetLastError();
		if(status!=cudaSuccess)
		{
			char CUDAmessage[200] = "CUDA failed after sychronization:\n";
			strcat(CUDAmessage,	cudaGetErrorString(status));
			sprintf(CUDAmessage,	"%s\non line: %d\n", CUDAmessage, line);
			//AfxMessageBox(CUDAmessage);
			exit(-1);
		}
	}while(0);
#endif
	return;
}

inline void mDisplayDataF(float *d_data, int length, int line)
{
#ifdef M_CUDA_DEBUG
	do
	{
		int maxlength = 50;
		float *h_data;
		length = (length<=maxlength) ? length : maxlength;
		char MessageString[1000];
		h_data = (float*)malloc(length * sizeof (float));
		M_SAFE_CALL(cudaMemcpy(h_data, d_data, length*sizeof(float), cudaMemcpyDeviceToHost));
		sprintf(MessageString,	"Line: %d\nData: ", line);
		for (int ii = 0;ii<length;++ii)
		{
			sprintf(MessageString,	"%s %f", MessageString, h_data[ii]);
		}
		//AfxMessageBox(MessageString, MB_ICONINFORMATION);
		free(h_data);
	}while(0);
#endif
	return;
}
inline void mDisplayDataCC(cufftComplex *d_data, int length, int line)
{
#ifdef M_CUDA_DEBUG
	do
	{
		int maxlength = 25;
		cufftComplex *h_data;
		length = (length<=maxlength) ? length : maxlength;
		char MessageString[1000];
		h_data = (cufftComplex*)malloc(length * sizeof (cufftComplex));
		M_SAFE_CALL(cudaMemcpy(h_data, d_data, length*sizeof(cufftComplex), cudaMemcpyDeviceToHost));
		sprintf(MessageString,	"Line: %d\nData: ", line);
		for (int ii = 0;ii<length;++ii)
		{
			sprintf(MessageString,	"%s re: %f im: %f", MessageString, h_data[ii].x, h_data[ii].y);
		}
		//AfxMessageBox(MessageString, MB_ICONINFORMATION);
		free(h_data);
	}while(0);
#endif
	return;
}
inline void mDisplayDataUC(uint16_t *d_data, int length, int line)
{
#ifdef M_CUDA_DEBUG
	do
	{
		int maxlength = 50;
		uint16_t *h_data;
		length = (length<=maxlength) ? length : maxlength;
		char MessageString[1000];
		h_data = (uint16_t*)malloc(length * sizeof (uint16_t));
		M_SAFE_CALL(cudaMemcpy(h_data, d_data, length*sizeof(uint16_t), cudaMemcpyDeviceToHost));
		sprintf(MessageString,	"Line: %d\nData: ", line);
		for (int ii = 0;ii<length;++ii)
		{
			sprintf(MessageString,	"%s %hhu", MessageString, h_data[ii]);
		}
		//AfxMessageBox(MessageString, MB_ICONINFORMATION);
		free(h_data);
	}while(0);
#endif
	return;
}
inline void mDisplayDataI(int *d_data, int length, int line)
{
#ifdef M_CUDA_DEBUG
	do
	{
		int maxlength = 50;
		int *h_data;
		length = (length<=maxlength) ? length : maxlength;
		char MessageString[1000];
		h_data = (int*)malloc(length * sizeof (int));
		M_SAFE_CALL(cudaMemcpy(h_data, d_data, length*sizeof(int), cudaMemcpyDeviceToHost));
		sprintf(MessageString,	"Line: %d\nData: ", line);
		for (int ii = 0;ii<length;++ii)
		{
			sprintf(MessageString,	"%s %d", MessageString, h_data[ii]);
		}
		//AfxMessageBox(MessageString, MB_ICONINFORMATION);
		free(h_data);
	}while(0);
#endif
	return;
}

//Calculate amplitudes in positions given by x, y, and z from a given hologram
extern "C" __declspec(dllexport)  int GetIandPhase(float *x_spots, float *y_spots, float *z_spots, float *h_pSLM_uc, int N_spots_all, int data_w, float *h_I_obt, float *h_Phase_obt)
{
	float *d_Iobtained_all;
	float *d_Pobtained_all;
	cudaMalloc((void**)&d_Iobtained_all, N_spots_all*sizeof(float) );
	cudaMalloc((void**)&d_Pobtained_all, N_spots_all*sizeof(float) );
	cudaMemcpy(d_pSLM_uc, h_pSLM_uc, memsize_SLMuc, cudaMemcpyHostToDevice);
	int offset = 0;
	int N_spots_rem = N_spots_all;
	int N_spots_this;
	while (N_spots_rem > 0)
	{
		N_spots_this = (N_spots_rem > MAX_SPOTS) ? MAX_SPOTS : N_spots_rem;
		cudaMemcpyToSymbol(c_x, x_spots+offset, N_spots_this*sizeof(float), 0, cudaMemcpyHostToDevice);
		cudaMemcpyToSymbol(c_y, y_spots+offset, N_spots_this*sizeof(float), 0, cudaMemcpyHostToDevice);
		cudaMemcpyToSymbol(c_z, z_spots+offset, N_spots_this*sizeof(float), 0, cudaMemcpyHostToDevice);
		calculateIandPhase<<< N_spots_this, 512>>>(d_pSLM_uc, d_Iobtained_all+offset, d_Pobtained_all+offset);
		//calculateIobtained(uint16_t *g_pSLM_uc, float *g_Iobtained)
		cudaDeviceSynchronize();
		N_spots_rem -= MAX_SPOTS;
		offset += MAX_SPOTS;
	}
	cudaMemcpy(h_I_obt, d_Iobtained_all, N_spots_all*sizeof(float), cudaMemcpyDeviceToHost);
	cudaMemcpy(h_Phase_obt, d_Pobtained_all, N_spots_all*sizeof(float), cudaMemcpyDeviceToHost);
	cudaFree(d_Iobtained_all);
	cudaFree(d_Pobtained_all);
	status = cudaGetLastError();
	return status;
}
