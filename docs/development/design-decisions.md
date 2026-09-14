# Design decisions

This page records durable decisions that shape the current MGB source. It
explains why the code has its present boundaries and which constraints a
future design change must address. It is not a list of proposals or a history
of every refactor.

Work-in-progress proposals belong under `.dev/plans/`. When a proposal is
accepted and implemented, update this page if it changes one of these durable
decisions.

## Keep one executable with layered source responsibilities

The project builds one `mgb_model` executable. Source directories describe
responsibilities:

- `simulation` composes the process lifecycle, initialization and timestep execution;
- `hydrology` owns scientific behavior;
- `io` owns model file access and serialization;
- `vars` owns shared model storage; and
- `common` supplies utilities that do not depend on model layers.

Dependencies point from orchestration toward behavior, I/O, state, and common
utilities. Hydrology does not call other hydrology modules, scientific modules
do not perform model I/O, and variable modules do not import project modules.
The [architecture page](architecture.md) defines the complete dependency table.

The consequence is some explicit coordination in `runner`. That
coordination is preferable to hidden calls across scientific domains because
the model execution order remains visible in one place.

## Retain role-based module storage

Shared data remains in the five flat modules under `src/vars`: `attributes`,
`config`, `forcing`, `parameters`, and `state`. These modules are
default-public, while each consumer uses an explicit `only:` import list.

This is a deliberate intermediate design. It exposes existing global-state
coupling without introducing a whole-model object or a large derived-type
migration. Allocation, deallocation, and storage-specific initialization stay
with the module that owns the variables.

New shared values should be assigned to the module matching their lifecycle
and meaning. Proposals to replace this organization must include a staged
migration and regression evidence; they should not introduce a second,
competing state organization alongside it.

## Centralize runtime I/O

Modules under `src/io` own all model input, output, hotstart, and log files.
Hydrology reads and updates model variables but does not open, close, or
serialize model files.

This boundary keeps file layouts out of scientific kernels and gives each
runtime file a clear owner. I/O modules may depend on shared variables and
common utilities, but they do not depend on hydrology modules.

## Preserve established runtime data contracts

Input filenames, namelist keys, record order, numeric precision, and binary
layouts are runtime interfaces. Direct-access record lengths are derived with
`INQUIRE(IOLENGTH=...)`.

Portability work must preserve the established physical records unless an
intentional format migration has been agreed and documented. Historical names
are not automatically accepted as aliases. The [I/O reference](../model/io-reference.md)
is the authoritative inventory of current files and records.

## Make coupling and public APIs explicit

Every project-module import uses an `only:` list. Behavioral, common, I/O, and
runner modules use default `private` visibility and explicitly name their
public API; the shared variable modules are the documented exception.

These rules make dependencies reviewable while the code still uses shared
module storage. The architecture checker enforces the directory, visibility,
import, and dependency rules so they remain consistent during incremental
modernization.

## Use CMake and regression tests as the shared baseline

CMake is the canonical build definition and OpenMP is required. Support claims
are limited to environments that the project has actually validated; the
[portability page](../model/portability.md) records that set.

The Magdalena inertial and Muskingum-Cunge cases exercise both routing paths.
They are a regression baseline, not proof that every scientific behavior is
correct. New work should improve focused coverage where practical rather than
weakening tolerances or silently accepting changed output.
