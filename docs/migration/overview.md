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
fixtures.

## How to use the tables

The tables record correspondence for reading and migration work. “Split” means one legacy file or variable now has owners in more than one module. “Consolidated” means multiple legacy routines or files now share one current owner. “Removed” means the old interface or calculation has no current counterpart. An item marked “absorbed” remains part of a larger current procedure but no longer has a separate entry point.

The [shared-variable mapping](shared-variables.md) lists former globals by
their current module. The [routine-local mapping](routine-locals.md) lists
selected former globals now used as local equation inputs or temporaries.

For current implementation, see:

- [Architecture overview](../architecture/architecture.md)
- [Components and dependencies](../architecture/components-and-dependencies.md)
- [Execution and data flow](../architecture/execution-and-data-flow.md)
- [I/O reference](../architecture/io-reference.md)

## Terminology

| Historical term | Current term | Usage |
| --- | --- | --- |
| URH | HRU | Historical abbreviation for *unidade de resposta hidrológica*; current English term is hydrological response unit. |
| minibacia | catchment | Local contributing area associated with one explicit river segment. |
| montante | upstream | Direction toward the headwaters. |
| jusante | downstream | Direction toward the outlet. |
| cota | stage or elevation | Water-surface or floodplain elevation, depending on context. |
| cota-área-volume | stage-area-volume | Floodplain lookup relation used by local-inertial routing. |
| vazão | discharge or flow | Volumetric flow rate; identify the variable context and units. |
| solo | soil | Soil storage and flux domain in catchment water balance. |

The current model's spatial units and storage concepts are introduced in
[Model concepts](../model/model-concepts.md).
