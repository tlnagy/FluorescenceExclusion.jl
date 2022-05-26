var documenterSearchIndex = {"docs":
[{"location":"#FluorescenceExclusion.jl","page":"Home","title":"FluorescenceExclusion.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"A metapackage for analyzing fluorescence exclusion microscopy (FxM) images in Julia. Very much a WIP.","category":"page"},{"location":"#TL;DR","page":"Home","title":"TL;DR","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using Pkg\nusing TiffImages\nusing FluorescenceExclusion\n\npath = joinpath(Pkg.pkgdir(FluorescenceExclusion), \"test\", \"testdata\", \"220125_lane2_fxmraw.tif\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"This package provides tools to segment and correct fluorescence exclusion microscopy images:","category":"page"},{"location":"","page":"Home","title":"Home","text":"img = TiffImages.load(path) # load a FxM image\n\nfimg = float.(img) # convert to floating point\n\ncorrect!(fimg, fimg)\n\nhcat(img, fimg)","category":"page"},{"location":"#Public","page":"Home","title":"Public","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"correct!\nidentify\nbuild_tp_df","category":"page"},{"location":"#FluorescenceExclusion.correct!","page":"Home","title":"FluorescenceExclusion.correct!","text":"correct!(data; mask)\n\nGiven a FxM image data, corrects for inhomogeneities both in illumination and in warping. \n\nIt does this by sampling the foreground signal of the excluded dye and then interpolating into the \"holes\" in the signal like the pillars and cells. Passing an additional optional parameter mask can augment the built-in detection of cells to avoid using those areas to estimate the foreground. Additionally, it estimates the true background by interpolating between pillars.\n\nThe returned values should be centered around 0 for the centers of the pillars and around 1 for the foregound areas.\n\njulia> img = TiffImages.load(path);\n\njulia> fimg = float.(img); #convert to Gray{Float32}\n\njulia> correct!(fimg, fimg); # correct FxM channel, we don't have a denoise image so we re-use the same one\n\n\n\n\n\n","category":"function"},{"location":"#FluorescenceExclusion.identify","page":"Home","title":"FluorescenceExclusion.identify","text":"identify(Pillars(), img; dist, min_area)\n\nUse a simple algorithm to identify pillars and their centers. The optional keyword dist allows varying the number of pixels from the edge of the pillar that a pixel must be to be considered a center pixel. This helps correct for incomplete sealing at the edges of pillars. Additionally, the parameter min_area is the minimum pixel area that an object should have to be considered a pillar.\n\n\n\n\n\nidentify(Cells(), img, pillar_masks)\n\nIdentify cells in the FxM channel using a custom edge-based detection system that thresholds using the distribution of spatial gradient sizes across cells.\n\n\n\n\n\nidentify(Locality(), labels, pillar_masks; min_pillar_dist, dist) -> Dict\n\nGets the local background areas given the output of label_components. The local background is defined as a ring around the object that is at minimum mindist away from every object (in pixels) and a maximum of maxdist away from the target object. Pillars, as defined by true values in pillar_masks, are ignored as are areas that are min_pillar_dist away from a pillar. The result is a dictionary mapping the object id to all indices in its local background. \n\nwarning: Warning\nIt's really important that labels has all foreground objects labeled because otherwise they might inadvertently be included in an object's locality.\n\n\n\n\n\n","category":"function"},{"location":"#FluorescenceExclusion.build_tp_df","page":"Home","title":"FluorescenceExclusion.build_tp_df","text":"build_tp_df(img, components; dist)\n\nBuild a DataFrames.DataFrame that is compatible with trackpys link_df function. Needs to be converted to a Pandas.DataFrame before passing to trackpy. dist is a 2-tuple of integers indicating the minimum and maximum distance away in pixels from each cell to include in its local background calculation.\n\n\n\n\n\nGiven an img with at least y, x, and t axes and a 3 dimensional boolean array, thresholds, in yxt order.\n\n\n\n\n\n","category":"function"},{"location":"#Internal","page":"Home","title":"Internal","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"FluorescenceExclusion.compute_flatfield\nFluorescenceExclusion.darkfield\nFluorescenceExclusion.generate_sample_grid\nFluorescenceExclusion.get_locality\nFluorescenceExclusion.get_medians\nFluorescenceExclusion.isencapsulated","category":"page"},{"location":"#FluorescenceExclusion.compute_flatfield","page":"Home","title":"FluorescenceExclusion.compute_flatfield","text":"compute_flatfield(slice, mask; len) -> flatfield\n\nGiven a 2D fluorescence image and a boolean mask where all foreground objects are labeled true, this function returns a interpolated flatfield image to account for inhomogeneities in illumination. It does this by fitting a Multiquadratic Radial Basis function to a set of background grid points and interpolating the rest. This works well for gradual changes in topology so any sharp transitions in the background illumination will increase the error of the interpolant.\n\n\n\n\n\n","category":"function"},{"location":"#FluorescenceExclusion.darkfield","page":"Home","title":"FluorescenceExclusion.darkfield","text":"darkfield(img, pillar_centers)\n\nCompute the \"darkfield\" of an image by interpolating \"true\" minimum signal from the pillars to all points in the field. This accounts for subtle warping in the FxM chip.\n\nnote: Note\nThis isn't a classic camera darkfield, but instead what the field would look like if it were all pillar\n\n\n\n\n\n","category":"function"},{"location":"#FluorescenceExclusion.generate_sample_grid","page":"Home","title":"FluorescenceExclusion.generate_sample_grid","text":"generate_sample_grid(mask; len)\n\nCreate a sinusoidally spaced grid that avoiding areas labeled true in mask. The higher density of sampling points near the edges helps with the increased steepness in signal loss and interpolation error that occurs at the image boundaries.\n\n\n\n\n\n","category":"function"},{"location":"#FluorescenceExclusion.get_locality","page":"Home","title":"FluorescenceExclusion.get_locality","text":"get_locality(foreground, cell_mask; dist=(mindist, maxdist))\n\nGiven a boolean matrix of the pixels belonging to a single cell, cell_mask, and a boolean matrix of foreground pixels, foreground, this function  identifies the local background ring around the cell that is at minimum mindist away from every object (in pixels) and a maximum of maxdist away from the target cell.\n\n\n\n\n\n","category":"function"},{"location":"#FluorescenceExclusion.get_medians","page":"Home","title":"FluorescenceExclusion.get_medians","text":"get_medians(img, centers)\n\nGets the median intensity value for each pillar center defined by the boolean mask centers using the data in img. This can be used to determine the true \"floor\" in the intensity signal, which may drift over the course of an experiment.\n\n\n\n\n\n","category":"function"},{"location":"#FluorescenceExclusion.isencapsulated","page":"Home","title":"FluorescenceExclusion.isencapsulated","text":"isencapsulated(locality) -> Bool\n\nGiven a list of the indices defining the locality of a cell, this algorithm computes whether the locality fully encapsulates the cell, i.e. there are no gaps around the cell. This usually happens when the cell is very close to another cell, a pillar, or the edge of the FOV.\n\nThe basic approach is to flood fill the hole in the locality where the cell is. We put an upper bound on the size of the cell \"hole\" by computing the area of the convex hull of the locality.\n\n\n\n\n\n","category":"function"}]
}
