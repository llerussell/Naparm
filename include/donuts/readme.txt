Learning Module. 

You need to run mexALL first to compile C++ functions. I have included the GCaMP6 training dataset that I used for the paper. The master_file sets the important options before actually running the algorithm. Once you are happy with a set of model parameters you can use those on any similar images by using the inference module. The algorithm should be very fast but I have not set a stopping criterion. 100 iterations is probably sufficient but you can wait longer if the parameters keep changing, or if you are estimating a model with many parameters.

Once the parameters are learned it leaves you with a 'model' structure which you should save to disk. The variable 'model' is everything you need to apply to test data in the inference module.

This is far from being a final version of the code, but it should work.

Inference Module.

Everything it needs should be in the main directory in the archive, but you only ever need to look at "master_file.m". Be sure to first run once "mexAll.m" to create your mexed .c files (only one mex file for the inference module). This contains some example 'model' parameters already, but you should swap these with the ones you get from the learning module. 


Additional Notes.

The algorithm is dependent on a preprocessing step that normalizes the variance of the signal across each image. This is in order to enhance the contrast of dim cells. There can be a large variability between how well different cells express gcamp. I am working on making the normalization steps automatic, but for now  I suggest tweaking the sig1 and sig2 parameters to see if you get a better normalized image in variable 'y' (but always keep sig1<=sig2). Their current values work well for images like the ones in the dataset we used in the paper (they are on the order of the radius of each cell in pixels). A good rule of thumb is to tweak those such that you can better see by eye the donut-shaped elements in the normalized image. Then the algorithm will see them better too. Basically, sig1 is the radius over which the signal is "whitened" (like with a center-surround filter) and sig2 is the range over which it is divisively normalized (divided by the variance in a small neighborhood). 
