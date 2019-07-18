# Naparm
_(Near automatic photoactivation response mapping)_

Written by: Lloyd Russell ([@llerussell](https://github.com/llerussell/)) and Henry Dalgleish ([@hwpdalgleish](https://github.com/hwpdalgleish/)) in Michael Hausser's laboratory (UCL)

Complete software suite to select photostimulation targets manually, or automatically, from anatomical or activity-based images or volumetric stacks. See [STAMovieMaker](https://github.com/llerussell/STAMovieMaker) for generation of stimulus triggered average pixel maps. 
This software will generate SLM phase masks, galvanometer positioning and Pockels cell control protocols to be executed by the photostimulation modules of an all-optical microscope (using software: PrairieView [Bruker Corporation] and Blink [Meadowlark])

For calibration of SLM targeting in imaging coordinates, see our [calibration procedure](https://github.com/llerussell/SLMTransformMaker3D).


## User interface
![Imgur](https://i.imgur.com/tSSsMGR.jpg)

## Example
<img src="/misc/NaparmAnimation_reduced.gif" alt="Animation of Naparm results">

## Requirements
* [ReadYAML](https://github.com/llerussell/ReadYAML) - to read custom system parameters file
* [SLMPhaseMaskMaker3D](https://github.com/llerussell/SLMPhaseMaskMaker3D) - to generate SLM phase masks
* [TriggerBuilder](https://github.com/llerussell/TriggerBuilder) - to interface with [PackIO](http://apacker83.github.io/)
* [MarkPointsXML](https://github.com/llerussell/Bruker_MarkPoints) - to generate Bruker specific 'MarkPoints' files. Thorlabs version coming soon.

## As seen in
Russell LE, Yang Z, Tan LP, Fisek M, Packer AM, Dalgleish HWP, Chettih S, Harvey CD, Hausser M. [The influence of visual cortex on perception is modulated by behavioural state.](https://www.biorxiv.org/content/10.1101/706010v1) bioRxiv 17 July 2019. 
