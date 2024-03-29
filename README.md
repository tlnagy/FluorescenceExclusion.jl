# FluorescenceExclusion.jl

| **Documentation**                 | **Build Status**                                              |
|:----------------------------------|:--------------------------------------------------------------|
| [![][docs-dev-img]][docs-dev-url] | [![][status-img]][status-url] [![][ci-img]][ci-url] [![][codecov-img]][codecov-url] |

Fluorescence Exclusion Microscopy is a quantitative imaging method for measuring
cell volume that relies on the exclusion of a dye by cells in chambers with a
known height. This is a Julia implementation inspired by the "1.4 Data Analysis"
section in Cadart et al.

[¹]: Cadart, C., Zlotek-Zlotkiewicz, E., Venkova, L., Thouvenin, O., Racine, V.,
Le Berre, M., Monnier, S., & Piel, M. (2017). Chapter 6 - Fluorescence eXclusion
Measurement of volume in live cells. In Thomas Lecuit (Ed.), Methods in Cell
Biology (Vol. 139, pp. 103–120). Academic Press.
http://www.sciencedirect.com/science/article/pii/S0091679X16301613

## Installation

Until this package is registered in the General repository, the easiest way to install the latest stable version is 
to add https://github.com/tlnagy/TNRegistry as follows:

```julia
using Pkg
pkg"registry add git@github.com:tlnagy/TNRegistry.git"
```

Then installation is as easy as

```julia
using Pkg
Pkg.add("FluorescenceExclusion")
```

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://tamasnagy.com/FluorescenceExclusion.jl/dev

[ci-img]: https://github.com/tlnagy/FluorescenceExclusion.jl/workflows/CI/badge.svg
[ci-url]: https://github.com/tlnagy/FluorescenceExclusion.jl/actions

[codecov-img]: https://codecov.io/gh/tlnagy/FluorescenceExclusion.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/tlnagy/FluorescenceExclusion.jl

[status-img]: https://www.repostatus.org/badges/latest/wip.svg
[status-url]: https://www.repostatus.org/#wip
