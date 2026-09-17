# MGB-model

MGB is a legacy Fortran model for large-scale hydrology and hydrodynamics. The
repository is being prepared for maintainable collaborative development while
preserving validated scientific behavior, numerical record data, and
established runtime file formats. Source identifiers use descriptive English
names while runtime input filenames remain established MGB names.

## Purpose and scope

The model represents distributed land-surface water and energy balances,
catchment runoff generation, river routing, and floodplain processes. This
repository contains the executable, its CMake build, regression fixtures, and
the documentation needed to understand and maintain the current implementation.
The documented supported baselines are Windows x64 and Linux x64 with Intel
`ifx`, plus Linux x64 with GNU Fortran 13.3.

## Minimal build

The validated Linux GNU workflow requires GNU Fortran 13.3, CMake 3.25 or
later, and an OpenMP runtime with Fortran support:

```bash
FC=gfortran cmake -S . -B build/gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/gfortran
```

See the [full build guide](docs/development/build.md) for Intel, Windows, and
testing commands. OpenMP for Fortran is required for every supported build.

## Documentation

Read the [published documentation](https://hge-iph.github.io/MGB-model/) or
browse the [documentation source](docs/index.md). It is organized into Model,
Architecture, and Development sections. Repository change workflow and review
expectations are documented in [CONTRIBUTING.md](CONTRIBUTING.md).

The [Model overview](docs/model/overview.md) provides the main entry point for
the scientific documentation. The
[Architecture overview](docs/architecture/architecture.md) introduces the
software structure and links to the component and execution references.

## Project origin and contributors

MGB originated in Walter Collischonn's doctoral research on large-basin
hydrological simulation at the Federal University of Rio Grande do Sul in 2001.
It was subsequently developed for research and operational applications by the
Large Scale Hydrology Research Group at the Institute of Hydraulic Research
(IPH/UFRGS).
Version control contains the detailed modification history.

Contributors to the Fortran model include:

- Walter Collischonn
- Rodrigo Cauduro Dias de Paiva
- Diogo da Costa Buarque
- Paulo Rógenes Pontes
- Mino Viana Sorribas
- Fernando Mainardi Fan
- Juan Martin Bravo
- Vinicius Alencar Siqueira
- Ayan Santos Fleischmann
- Sly Wongchuig Correa
- Rafael Barbedo

## License and citation

MGB is distributed under the GNU General Public License, version 3 or later.
See [LICENSE](LICENSE) for the complete license text.

For the large-scale hydrological-hydrodynamic model, cite:

> Pontes, P. R. M., Fan, F. M., Fleischmann, A. S., Paiva, R. C. D., Buarque,
> D. C., Siqueira, V. A., Jardim, P. F., Sorribas, M. V., and Collischonn, W.
> “MGB-IPH model for hydrological and hydraulic simulation of large floodplain
> river systems coupled with open source GIS.” *Environmental Modelling &
> Software* 94, 1–20, 2017.

The [Model references](docs/model/references.md) page contains the complete
source bibliography and additional MGB publications.
