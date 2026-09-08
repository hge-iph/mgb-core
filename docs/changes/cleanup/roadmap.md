# Cleanup Roadmap

This roadmap defines a staged cleanup effort for the legacy Fortran model. The
goal is to make future development safer and easier to review without changing
scientific behavior, input formats, output formats, or validated runtime results.

## Working Rules

Each cleanup branch should be small enough to review as a behavior-preserving
change. If a proposed change needs scientific judgment, changes model output, or
requires reinterpreting an input file, it should move to a separate feature or
model-change branch.

Default cleanup rules:

- Branch from `main`.
- Keep one cleanup theme per branch.
- Prefer compiler evidence over manual guessing for unused variables.
- Preserve existing input and output files exactly unless a branch explicitly
  documents and tests a format change.
- Keep Portuguese hydrological terms when translation could obscure domain
  meaning.
- Write new comments and documentation in English.
- Add glossary entries for mixed-language domain terms before broad renaming.
- Update documentation in the same branch when cleanup changes developer
  workflow, ownership boundaries, or validation expectations.

## Success Criteria

A cleanup branch is successful when all of the following are true:

- The branch has a single stated cleanup objective.
- The PR description states that scientific behavior is intended to be
  unchanged.
- Source changes are limited to the stated cleanup objective.
- Any removed variable, declaration, or routine is justified by compiler output,
  search evidence, or an obvious local proof.
- Build files and scripts remain aligned with `README.md`, `docs/build.md`,
  `docs/testing.md`, and `docs/portability.md`.
- The CMake build succeeds on an available validated environment.
- `regression_magdalena` passes on an available validated environment.
- If local validation is unavailable, the PR documents the exact blocker and the
  expected CI or reviewer validation path.
- No expected regression output is updated for cleanup-only branches.
- Any residual risk is called out explicitly in the PR description.

The cleanup effort as a whole is successful when:

- cleanup diagnostics are available and documented
- missing implicit typing protections have been addressed in targeted routines
- compiler-confirmed unused locals have been reduced in the agreed cleanup areas
- small utility routines have explicit interfaces or a documented interface plan
- current runtime responsibilities are mapped
- comment and language guidance is documented for future contributors
- each merged cleanup branch has build and regression evidence
- `main` remains releasable after every cleanup merge

## Branch strategy

1. `cleanup/code-hygiene`

   Task:

   - Add an opt-in CMake warning/diagnostic mode for the validated Fortran
     compiler.
   - Use that warning mode to clean unused local variables.
   - Remove unused files when search/build evidence shows they are not part
     of the model, tests, docs, or supported workflow.
   - Add missing `implicit none` statements and required explicit local
     declarations.
   - Keep changes local and behavior-preserving.

   Success criteria:

   - The default build remains unchanged unless warnings are explicitly enabled.
   - Removed variables and files are backed by compiler output, build evidence,
     or repository search evidence.

2. `cleanup/docs-language`

   Task:

   - Move long-form documentation out of source comments and into Markdown files.
   - Maintain the documentation tree as a MkDocs site with strict link and
     configuration validation.
   - Install with `python -m pip install -r requirements-docs.txt`, preview with
     `python -m mkdocs serve`, and validate with
     `python -m mkdocs build --strict`.
   - Improve in-code comments so they explain intent, units, assumptions, and
     non-obvious behavior instead of repeating implementation details.
   - Rename files and variables toward English where the meaning is clear and
     the change is reviewable.
   - Preserve domain terminology when direct translation would be ambiguous.

   Success criteria:

   - Documentation is easier to navigate from `README.md` and `docs/`.
   - Source comments are shorter, clearer, and closer to the code they explain.
   - Any file or variable rename is mechanical, documented in the PR, and applied
     consistently across callers/build files.

3. `cleanup/structure-and-interfaces`

   Task:

   - Introduce explicit interfaces for utility routines and other low-risk
     boundaries.
   - Map IO responsibilities: which routines open, read, write, and close each
     runtime file.
   - Start modularizing code around documented responsibilities.
   - Introduce a folder structure that separates utilities, IO, model state,
     hydrology, routing, flood/inertial routing, and program entry points where
     practical.
   - Keep IO restructuring separate from hydrology and routing logic changes.

   Success criteria:

   - Interface changes preserve argument order, precision, and runtime behavior.
   - IO ownership is documented before routines are moved or consolidated.
   - Folder/module movement is reflected in CMake and developer documentation.
   - Global-state reduction is incremental and does not hide behavior changes.

## Stop Conditions

Pause a cleanup branch if:

- regression output changes
- an input or output format must change
- a change requires hydrological interpretation
- a branch starts touching unrelated responsibility areas
- a rename becomes broad enough to hide behavior changes
- validation cannot be run and CI does not cover the affected path
