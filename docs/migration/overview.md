# Legacy migration reference

This reference maps the flat Fortran source tree and runtime interface before
the architecture refactor to the current modules and names. It helps readers
follow older code notes, papers, local patches, and model datasets.

## Reference versions

| Reference | Revision | Meaning |
| --- | --- | --- |
| Legacy source and runtime baseline | [`41146b1`](https://github.com/HGE-IPH/MGB-model/commit/41146b1) | Parent of the architecture refactor in #11; the source tree contains 43 flat Fortran files. |
| Architecture refactor | [`a14415a`](https://github.com/HGE-IPH/MGB-model/commit/a14415a) | Refactor commit for #11. |
| Current implementation | [`3858334`](https://github.com/HGE-IPH/MGB-model/commit/3858334) | Repository `main` when this reference was prepared. |

The source comparison uses the parent of #11 as its baseline. The runtime
comparison uses that revision's readers, writers, namelists, and regression
fixtures. Later historical migration drafts are not authoritative when their
names differ from either endpoint.

## Current source layout

The former flat source tree is organized by responsibility:

| Current directory | Responsibility |
| --- | --- |
| `src/simulation/` | Program entry point, initialization phases, simulation lifecycle, and timestep coordination |
| `src/hydrology/` | Catchment water balance, reservoirs, and river routing |
| `src/io/` | Configuration, static inputs, meteorological forcing, hotstarts, logs, outputs, and reservoir files |
| `src/vars/` | Shared attributes, configuration, forcing, parameters, and evolving model state |
| `src/common/` | Date/time, interpolation, random-seed, and runtime support |

The module responsibilities and dependency direction are described in the
[architecture overview](../architecture/architecture.md) and
[components and dependencies](../architecture/components-and-dependencies.md).

## How to use the tables

The tables record correspondence for reading and migration work. They do not
add runtime aliases, preserve old Fortran entry points, or guarantee that an
old configuration or dataset runs unchanged. Use the current names and formats
listed in the [runtime name mapping](runtime-names.md) and authoritative
[I/O reference](../architecture/io-reference.md).

“Split” means one legacy file or variable now has owners in more than one
module. “Consolidated” means multiple legacy routines or files now share one
current owner. “Removed” means the old interface or calculation has no current
counterpart. An item marked “absorbed” remains part of a larger current
procedure but no longer has a separate entry point.

## Related references

- [Architecture overview](../architecture/architecture.md)
- [Execution and data flow](../architecture/execution-and-data-flow.md)
- [I/O reference](../architecture/io-reference.md)
- [Model processes and numerical assumptions](../model/model-processes.md)
