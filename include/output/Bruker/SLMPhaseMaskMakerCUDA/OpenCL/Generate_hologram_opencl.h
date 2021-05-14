//
//:  Interface functions for Generate_hologram_opencl.
//
//   (c) Copyright Boulder Nonlinear Systems 2016, 2017. All Rights Reserved.
//

#ifndef GENERATE_HOLOGRAM_OPENCL_H_
#define GENERATE_HOLOGRAM_OPENCL_H_

#ifdef GENERATE_HOLOGRAM_OPENCL_EXPORTS
   #define GENERATE_HOLOGRAM_OPENCL_API __declspec(dllexport)
#else
   #define GENERATE_HOLOGRAM_OPENCL_API __declspec(dllimport)
#endif

/// @file
///
// Interface to Generate_hologram_opencl.dll. More details to be added.
///

enum
   {
   e_invalid_method_cl = -1,
   e_lenses_and_prisms_cl,
   e_weighted_gs_using_fresnel_propagation_cl,
   e_weighted_gs_using_fft_cl
   };


#ifdef __cplusplus
   extern "C" {    // using a C++ compiler
#endif

   // -------------------------------------------------------------------------
   /// @brief  Initializes the DLL in preparation for hologram computations.
   ///
   /// @param slm_width         Pixel width  (number of columns) of the SLM.
   /// @param slm_height        Pixel height (number of rows)    of the SLM.
   /// @param n_max_spots       Set to the maximum number of spots that will be
   ///                          provided to any subsequent
   ///                          Generate_hologram() call.
   ///                          Used internally to set array sizes once, to
   ///                          speed up calculations.
   /// @param n_max_iterations  Set to the maximum number of iterations that
   ///                          will be requested in any subsequent
   ///                          Generate_hologram() call.
   ///                          Used internally to set array sizes once, to
   ///                          speed up calculations.
   /// @param use_gpu           0 to use a CPU; any other number for GPU.
   ///
   /// Call this function before any other function in this interface.
   /// @note An even number of pixel rows and columns is assumed. The value
   ///       need not be a power of 2.
   /// @warning  Non-square SLM holograms have not been tested yet.
   /// @return 0 for success; 1 for failure.
   /// @sa Get_last_error_message.
   // -------------------------------------------------------------------------
   GENERATE_HOLOGRAM_OPENCL_API
   int Create_generator_cl(
      unsigned int slm_width,
      unsigned int slm_height,
      unsigned int n_max_spots,
      unsigned int n_max_iterations,
      int use_gpu);


   // -------------------------------------------------------------------------
   /// @brief  Destroys allocated data structures in the DLL.
   ///
   /// Call this function once all calculations are complete.
   /// @return 0 for success; 1 for failure.
   // -------------------------------------------------------------------------
   GENERATE_HOLOGRAM_OPENCL_API
   int Destroy_generator_cl(void);


   // -------------------------------------------------------------------------
   /// @brief  Generates a hologram image for a supplied set of spots.
   ///
   /// @param n_spots             Number of spots in the next four arrays. If
   ///                            the number of spots is 0, this function
   ///                            returns @c false, and sets the @c method
   ///                            parameter to -1 (e_invalid_method).
   /// @param x_positions         Center of the SLM is 0. Allowed values
   ///                            [-(slm_width/2), (slm_width/2)-1], for
   ///                            example [-256, 255] for a 512 SLM.
   /// @param y_positions         Center of the SLM is 0. Allowed values
   ///                            [-(slm_height/2), (slm_height/2)-1], for
   ///                            example [-256, 255] for a 512 SLM.
   /// @param z_positions         0 corresponds to the SLM position.
   /// @param intensities         Intensity value at each spot. Values must be
   ///                            greater than 0.0f.
   /// @param n_iterations        Number of iterations for this calculation;
   ///                            should not exceed the value supplied to
   ///                            Create_generator_cl().
   /// @param method              Only method == 1 is supported at the moment;
   ///                            this is equivalent to method 1 in the CUDA
   ///                            implementation.
   /// @param starting_phases     Pointer to one starting phase/pixel array, or
   ///                            NULL (to use 0.5 as starting phase). Values
   ///                            in range [-pi/2, pi/2] are valid.
   ///                            Equivalent to h_pSLMstart, passed to
   ///                            startCUDA.
   /// @param hologram_image      Pointer to array of at least (slm_width *
   ///                            slm_height pixel values. On exit, contains
   ///                            the calculated image to be presented to the
   ///                            SLM.
   /// @param calc_intensities    Unused in this version.
   /// @param calc_time_us        Always set to 0.0 in this version.
   ///
   /// @warning In the CUDA implementation, "Lenses and Prisms" (method 0) is
   ///          always used if the number of spots is 1 or 2. We do not make
   ///          that method switch here.
   /// @warning The CUDA code silently limits the number of spots to 256 (the
   ///          first 256, if more are supplied); we use all the spots in this
   ///          implementation.
   /// @return 0 for success; 1 for failure.
   /// @sa Get_last_error_message.
   // -------------------------------------------------------------------------
   GENERATE_HOLOGRAM_OPENCL_API
   int Generate_hologram_cl(
      unsigned int n_spots,
      const float* x_positions,
      const float* y_positions,
      const float* z_positions,
      const float* intensities,
      unsigned int n_iterations,
      int* method,
      const float* starting_phases,
      unsigned char* hologram_image,
      float* calc_intensities,
      float* calc_time_us);


   // -------------------------------------------------------------------------
   /// @brief Returns a pointer to the string with the last error's message.
   // -------------------------------------------------------------------------
   GENERATE_HOLOGRAM_OPENCL_API
   const char* Get_last_error_message(void);


   // -------------------------------------------------------------------------
   /// @brief Returns a pointer to the string with the DLL version information.
   ///
   /// @return Null-terminated C string.
   // -------------------------------------------------------------------------
   GENERATE_HOLOGRAM_OPENCL_API
   const char* Get_version_info(void);


#ifdef __cplusplus
}
#endif

#endif  // end of GENERATE_HOLOGRAM_OPENCL_H_
