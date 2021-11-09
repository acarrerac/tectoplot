tectoplot
=========

See the (thus far imaginary, hopefully soon actual) [project website][tectoplot] for documentation of tectoplot's features.

tectoplot is a bash script and associated helper scripts/programs that makes it easier to create seismotectonic maps, cross sections, and oblique block diagrams. It tries to simplify the process of making programmatic maps and figures from the command line in a Unix environment. tectoplot started as a basic script to automate making shaded relief maps with GMT, and has snowballed over time to incorporate many other functions.

Caveat Emptor
-------------

tectoplot is software written by a field geologist, and is in very early stages of development. Most of the code 'works', but the overall structure and design needs much improvement. None of the routines have been rigorously tested and there are certainly bugs in the code. tectoplot operates using bash, which means it can theoretically access or delete anything it has permission to access. I am making tectoplot publicly available at this early stage because my students and colleagues are already using it and their advice is helping me improve the code. With that being said, if you use tectoplot, please be sure to:

 * Only run tectoplot on a computer that is backed up, and run from an account that doesn't have root privileges or access to critical directories.

 * Validate all data, maps, and figures produced by tectoplot.

 * Appropriately cite datasets that you use, and please also cite [GMT 6][gmt6]

 * Let me know if you find a bug or problem, and I will try to fix it!

What does tectoplot do?
-----------------------

Here's a simple tectoplot command that plots seismicity and volcanoes in Guatemala.

```proto
tectoplot -r GT -t -tmult -tsl -z -vc -legend onmap -o Guatemala
```

Let's break down the command to see what it does:

|Command|Effect|
|--|--|
|-r GT|Set the map region to encompass Guatemala|
|-RJ B|Select an Albers map projection|
|-t|Plot shaded topographic relief|
|-tmult|Calculate a multidirectional hillshade|
|-tsl|Calculate surface slope and fuse with hillshade|
|-z|Plot earthquake epicenters (default data are from USGS/ANSS)|
|-vc|Plot volcanoes (Smithsonian)|
|-legend onmap|Create a legend and place it onto the map pdf|
|-o Guatemala|Save the resulting PDF map to Guatemala.pdf|


The resulting figure (click to see the original PDF):

<a href=examples/Guatemala.pdf><img src=examples/Guatemala.jpg height=400></a>

Credits and redistributed source code
-------------------------------------

tectoplot relies very heavily on the following open-source tools:

[GMT 6][gmt6]

[gdal][gdal]

tectoplot includes modified source redistributions of:

[Texture shading][text] by Leland Brown (C source with very minor modifications)

NDK import is heavily modified from [ndk2meca.awk][ndk2meca] by Thorsten Becker

Various focal mechanism calculations are modified from GMT's classic [psmeca.c/utilmeca.c][utilmeca] by G. Patau (IPGP)

Data
----

tectoplot will download and manage a wide variety of open geological and geophysical data, including data from:

* Topography/Bathymetry: SRTM - GEBCO - GMRT

* Satellite imagery: Sentinel cloud-free

* Earthquake hypocenters: ANSS - ISC - ISC-EHB

* Focal mechanisms: GCMT - ISC - GFZ

* Gravity: WGM - Sandwell2019

* Magnetics: EMAG_V2

* Lithospheric structure: LITHO1

* Faults: SLAB2.0 - GEM active faults


Methods
-------

Code and general analytical approaches have been adopted from or inspired by the following research papers. There is no guarantee that the algorithms have been correctly implemented. Please cite these or related papers if they are particularly relevant to your own study.

[Reasenberg, 1985][rb]: Seismicity declustering (Fortran source, minor modifications).

[Zaliapin et al., 2008][zaliapin]: Seismicity declustering (Python code by Mark Williams, UNR)

[Weatherill et al., 2016][weatherill]:  Seismic catalog homogenization

[Kreemer et al., 2014][kreemer]: GPS velocity data and Global Strain Rate Map

[Hackl et al., 2009][hackl]: Strain rate tensor calculations

[Sandwell and Wessel, 2016][sandwess]: GPS interpolation using elastic Green functions


Installation
------------

 [text]: http://www.textureshading.com/Home.html
 [utilmeca]: https://github.com/GenericMappingTools/gmt/blob/master/src/seis/utilmeca.c
 [gdal]: gdal.org
 [ndk2meca]: http://www-udc.ig.utexas.edu/external/becker/software/ndk2meca.awk
 [gmt6]: http://www.generic-mapping-tools.org
 [gmtcite]: https://www.generic-mapping-tools.org/cite/
 [tectoplot]: https://kyleedwardbradley.github.io/tectoplot/

 [rb]: https://doi.org/10.1029/JB090iB07p05479
 [zaliapin]: https://doi.org/10.1103/PhysRevLett.101.018501
 [weatherill]: https://doi.org/10.1093/gji/ggw232
 [kreemer]: https://doi.org/10.1002/2014GC005407
 [hackl]: https://doi.org/10.5194/nhess-9-1177-2009
 [sandwess]: doi.org/10.1002/2016GL070340
