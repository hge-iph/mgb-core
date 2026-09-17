# Design decisions

This page records durable decisions that shape the current MGB source. It
explains why the code has its present boundaries and which constraints a
future design change must address. It covers implemented decisions and their
rationale.

Work-in-progress proposals belong under `.dev/plans/`. When a proposal is
accepted and implemented, update this page if it changes one of these durable
decisions.

## One executable with layered source responsibilities

The project builds one `mgb_model` executable. Source directories have these
responsibilities:

| Directory | Responsibility |
| --- | --- |
| `simulation` | Process lifecycle, initialization, and timestep execution |
| `hydrology` | Scientific behavior |
| `io` | Model file access and serialization |
| `vars` | Shared model storage |
| `common` | Utilities independent of model layers |

Dependencies point from orchestration toward behavior, I/O, state, and common
utilities. Hydrology does not call other hydrology modules, scientific modules
do not perform model I/O, and variable modules do not import project modules.
The [components and dependencies](components-and-dependencies.md) page defines
the complete dependency table.

`runner` provides the explicit coordination required by this layering. The
model execution order remains visible in one place, while scientific domains
retain separate responsibilities.

## Role-based module storage

Shared data remains in the five flat modules under `src/vars`: `attributes`,
`config`, `forcing`, `parameters`, and `state`. These modules are
default-public, while each consumer uses an explicit `only:` import list.

This deliberate intermediate design exposes existing global-state coupling and
keeps allocation, deallocation, and storage-specific initialization with the
module that owns the variables. It does not introduce a whole-model object or
a large derived-type migration.

New shared values belong to the module matching their lifecycle and meaning. A
proposal to replace this organization includes a staged migration and
regression evidence and maintains one state organization during that
migration.

## Centralized runtime I/O

Modules under `src/io` own all model input, output, hotstart, and log files.
Hydrology reads and updates model variables but does not open, close, or
serialize model files.

This boundary keeps file layouts out of scientific kernels and gives each
runtime file a clear owner. I/O modules depend on shared variables and common
utilities; hydrology modules remain outside that dependency direction.

## Established runtime data contracts

Input filenames, namelist keys, record order, numeric precision, and binary
layouts are runtime interfaces. Direct-access record lengths are derived with
`INQUIRE(IOLENGTH=...)`.

Portability work preserves the established physical records. An intentional
format migration requires prior agreement and documentation. Historical names
are not automatically accepted as aliases. The [I/O reference](io-reference.md)
is the authoritative inventory of current files and records.

## Explicit coupling and public APIs

Every project-module import uses an `only:` list. Behavioral, common, I/O, and
runner modules use default `private` visibility and explicitly name their
public API; the shared variable modules are the documented exception.

These rules make dependencies reviewable while the code still uses shared
module storage. The architecture checker enforces the directory, visibility,
import, and dependency rules during incremental modernization.

## CMake and regression tests as the shared baseline

CMake is the canonical build definition and OpenMP is required. Support claims
are limited to environments that the project has actually validated; the
[setup and build guide](../development/build.md) records that set.

The Magdalena inertial and Muskingum-Cunge cases exercise both routing paths.
They are a regression baseline; passing them does not establish correctness for
every scientific behavior. Focused coverage complements this baseline, while
tolerances and expected outputs remain reviewed project data.
