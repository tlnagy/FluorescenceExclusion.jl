
abstract type AbstractSegmentable end

struct Pillars <: AbstractSegmentable end

"""
    identify(Pillars(), img; dist, min_area)

Use a simple algorithm to identify pillars and their centers. The optional
keyword `dist` allows varying the number of pixels from the edge of the
pillar that a pixel must be to be considered a center pixel. This helps correct
for incomplete sealing at the edges of pillars. Additionally, the parameter
`min_area` is the minimum pixel area that an object should have to be considered
a pillar.
"""
function identify(::Pillars, img::AbstractArray{T, 2}; dist=30, min_area=3000) where {T}
    # this labels the foreground, i.e. not pillars, so we'll need to invert it
    # later
    M₁ = opening(binarize(Bool, img, ImageBinarization.AdaptiveThreshold(img)))
    M₁ .= .~ M₁

    h, w = size(img)

    # prevent edge pixels from being included in pillars
    M₁[1:h, [1, w]] .= false
    M₁[[1, h], 1:w] .= false

    comps = label_components(M₁)
    small_objects = component_lengths(comps) .< min_area
    for o in component_indices(comps)[small_objects]
        M₁[o] .= false
    end

    dtrans = distance_transform(feature_transform(.~ M₁))

    M₁, dtrans .> dist
end

function identify(::Pillars, img::AbstractArray{T, 3}; dist=30, min_area=3000, verbose=true) where {T}
    pillar_masks = Array{Bool}(undef, size(img))
    pillar_centers = Array{Bool}(undef, size(img))

    wait_time = verbose ? 1 : Inf

    @showprogress wait_time for t in 1:size(img, 3)
        I = @view img[:, :, t]
        out = identify(Pillars(), I, dist=dist, min_area=min_area)

        pillar_masks[:, :, t] .= out[1]
        pillar_centers[:, :, t] .= out[2]
    end
    pillar_masks, pillar_centers
end

struct Cells <: AbstractSegmentable end

"""
    identify(Cells(), img, pillar_masks)

Identify cells in the FxM channel using a custom edge-based detection system that
thresholds using the distribution of spatial gradient sizes across cells.
"""
function identify(::Cells,
                 img::AbstractArray{T, 2},
                 pillar_masks::AbstractArray{Bool, 2};
                 min_pixel = 50,
                 min_pillar_dist = 30) where {T}

    grad_y, grad_x = imgradients(img, KernelFactors.scharr, "reflect");
    mag = hypot.(grad_x, grad_y)

    # remove the pillars and their vicinities from the calculations since they
    # can skew the results
    foreground = distance_transform(feature_transform((pillar_masks))) .> min_pillar_dist
    nx, ny = size(img)
    foreground[1:ny, [1, 2, ny-1, ny]] .= false
    foreground[[1, 2, nx-1, nx], 1:nx] .= false
    mag .*= foreground

    flattened = filter(x->x > 0.0, reshape(mag, :))
    lo, hi = quantile(flattened, (0.01, 0.99))

    # the magnitudes are almost log normal distributed, so we fit the
    # distribution then use 1 σ above the mean as the cutoff. A quick comparison
    # suggests that this approach catches the thin edges of cells much better
    # than common algorithms like Otsu or Yen.
    normfit = fit_mle(LogNormal, view(flattened, lo .< flattened .< hi))

    thres = opening(.~imfill(mag .< exp(normfit.μ + 1*normfit.σ), (0, 500)))
    imfill(thres, (0, min_pixel))
end

function identify(::Cells,
                 img::AbstractArray{T, 3},
                 pillar_masks::AbstractArray{Bool, 3}) where {T}

    @assert size(img) == size(pillar_masks)
    masks = Array{Bool}(undef, size(img))
    @showprogress for i in 1:size(img, 3)
        masks[:, :, i] .= identify(Cells(), view(img, :, :, i), view(pillar_masks, :, :, i))
    end
    masks
end

struct Locality <: AbstractSegmentable end

"""
    get_locality(foreground, cell_mask; dist=(mindist, maxdist))

Given a boolean matrix of the pixels belonging to a single cell,
`cell_mask`, and a boolean matrix of foreground pixels, `foreground`, this
function  identifies the local background ring around the cell that is at
minimum `mindist` away from every object (in pixels) and a maximum of `maxdist`
away from the target cell.
"""
function get_locality(foreground::AbstractArray{Bool, 2}, cellmask::AbstractArray{Bool, 2}; dist=(2, 10))
    all_localities = dist[1] .< distance_transform(feature_transform(foreground)) .< dist[2]
    locality = dist[1] .< distance_transform(feature_transform(cellmask)) .< dist[2]
    # only return true where this cells locality overlaps with other localities, this way we
    # insure that only foreground areas are counted in the locality
    locality .&= all_localities
end

"""
    identify(Locality(), labels, pillar_masks; min_pillar_dist, dist) -> Dict

Gets the local background areas given the output of `label_components`. The local
background is defined as a ring around the object that is at
minimum `mindist` away from every object (in pixels) and a maximum of `maxdist`
away from the target object. Pillars, as defined by true values in
`pillar_masks`, are ignored as are areas that are `min_pillar_dist` away from a
pillar. The result is a dictionary mapping the object id to all indices in its
local background. 

!!! warning
    It's really important that `labels` has all foreground objects labeled
    because otherwise they might inadvertently be included in an object's
    locality.
"""
function identify(::Locality, 
                  labels::AbstractMatrix{Int}, 
                  pillar_masks::AbstractMatrix{Bool};
                  min_pillar_dist = 30,
                  dist=(2, 10))

    boxes = component_boxes(labels)

    # if we detect gaps in the numbering it's probably because some labels were
    # removed, which can make our foreground detection incorrect
    computed_ids = sort(unique(labels))[2:end]
    if computed_ids != collect(minimum(computed_ids):maximum(computed_ids))
        @warn "Do not remove values from `labels`, only from `ids`. Calc might be wrong!"
    end

    pillar_area = distance_transform(feature_transform((pillar_masks))) .<= min_pillar_dist
    nx, ny = size(labels)
    pillar_area[1:nx, [1, 2, ny-1, ny]] .= true
    pillar_area[[1, 2, nx-1, nx], 1:ny] .= true

    nx, ny = size(labels)
    localities = OrderedDict{Int, Vector{CartesianIndex{2}}}()

    allobjects = labels .> 0

    δ = dist[1] + dist[2]

    for id in computed_ids
        # unpack bounding box
        (minx, miny), (maxx, maxy) = boxes[id+1]

        # extend window around bounding box by the max distance
        xrange = max(minx-δ, 1):min(maxx+δ, nx)
        yrange = max(miny-δ, 1):min(maxy+δ, ny)

        local_allobjects = view(allobjects, xrange, yrange)
        local_cellmask = view(labels, xrange, yrange) .== id
        @assert sum(local_cellmask) > 0 "No object of id=$id found"

        locality = get_locality(local_allobjects, local_cellmask; dist=dist)
        localpillar = view(pillar_area, xrange, yrange)
        locality[localpillar] .= false

        # use offset arrays to return CartesianIndices in the original image coordinates
        localities[id] = findall(OffsetArray(locality, xrange, yrange))
    end

    localities
end

function remove_small!(mask::AbstractArray{Bool, 2}, labels::AbstractArray{Int, 2}; lim=100) where {T}
    for label in findall(component_lengths(labels) .< lim) .- 1
        mask[labels .== label] .= false
    end
end

function remove_small!(mask::AbstractArray{Bool, 2}; lim=100) where {T}
    # TODO: we shouldn't copy here but it needs to wait till
    # https://github.com/JuliaImages/ImageMorphology.jl/issues/21 is resolved
    labels = label_components(copy(mask))
    remove_small!(mask, labels; lim=lim)
end

function segment!(img::AbstractArray{T, 2}, label::AbstractArray{Int, 2}) where {T}
    seeds = label
    bkg = label .== 0
    # seeds will be computed by eroding 1 pixels in from the background to get
    # an idea of where the cells are
    seeds[distance_transform(feature_transform(bkg)) .<= 1] .= 0

    segments = ImageSegmentation.watershed(img, seeds; mask=.~ bkg, compactness=0.01)
    label .= labels_map(segments)
end


"""
    isencapsulated(locality) -> Bool

Given a list of the indices defining the locality of a cell, this algorithm
computes whether the locality fully encapsulates the cell, i.e. there are
no gaps around the cell. This usually happens when the cell is very close to
another cell, a pillar, or the edge of the FOV.

The basic approach is to flood fill the hole in the locality where the cell
is. We put an upper bound on the size of the cell "hole" by computing the
area of the convex hull of the locality.
"""
function isencapsulated(locality::Vector{CartesianIndex{2}})
    (length(locality) == 0) && return false
    origin = minimum(locality)
    sz = Tuple(maximum(locality) - origin + CartesianIndex(1,1))
    tmp = falses(sz)
    tmp[locality .- Ref(origin) .+ Ref(CartesianIndex(1,1))] .= true

    # compute the convex hull, slightly dilated to handle edge cases with
    # extremely thin localities where the area of the convex hull is very close
    # to the area of the hole
    hulltmp = dilate(tmp)
    (count(tmp) <= 3) && return false
    hullc = convexhull(hulltmp)
    # area contained within the convex hull, we need this to set the 
    # maximum size of the flood fill algorithm
    hullarea = max(abs(PolygonOps.area(hullc)), 1)

    # to make sure that the outer region is larger than the area inside
    # convex hull, we pad the locality with that much area
    pad = ceil(Int, sqrt(hullarea) / 2)

    tmp2 = trues(size(tmp) .+ pad * 2)
    tmp2[findall(tmp) .+ Ref(CartesianIndex(pad, pad))] .= false
    
    # flood fill any regions that are up to the area of the convex hull of
    # the locality and then check if anything has changed. If it has, that
    # means the locality fully encapsulated the cell.
    any(imfill(tmp2, (1, hullarea)) .⊻ tmp2)
end