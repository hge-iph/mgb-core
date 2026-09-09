# Fortran style guide

The repository formats every Fortran 90 source with fprettify 0.3.7. The
exact settings are committed in .fprettify.rc and the dependency is pinned in
requirements-dev.txt.

## Required style

- Use four spaces for indentation. Tabs are forbidden.
- Keep source lines at or below 100 columns.
- Use lowercase for Fortran keywords, intrinsics, identifiers, operators, and
  logical constants.
- Preserve case in prose comments, user-facing strings, publication titles,
  and proper names.
- Use spaces after commas and around assignment, relational, logical, and
  additive operators.
- Keep multiplication, division, and exponentiation compact.
- Use explicit double-colon declarations.
- Give project modules default `private` visibility and list their public API.
- Use `only` lists for every project-module import.
- Indent continuations and align blocks consistently.
- Do not change kinds, interfaces, relational syntax, calculations, or
  declaration semantics merely to satisfy formatting.

The formatter is intentionally configured not to replace relational operators:
the source's existing relational syntax remains part of the behavior-preserving
style migration.

## Local exceptions

All ordinary source and comment lines meet the 100-column limit. The
behavior-preserving continuation pass wraps legacy allocations, expressions,
I/O statements, and declarations without changing their calculations or
interfaces.

OpenMP directive lines beginning with !$omp are the one line-length
exclusion: fprettify 0.3.7 does not safely split their private lists, and
rewriting those directives would change parallel-region syntax rather than
formatting whitespace. Comments are not lowercased because prose and citations
are documentation.
Generated documentation, namelist values, and runtime strings are not
formatted as Fortran source.

## Checks

Run from the repository root:

~~~bash
python -m pip install -r requirements-dev.txt
fprettify --recursive --config-file .fprettify.rc src
fprettify --recursive --config-file .fprettify.rc src
python scripts/check_fortran_format.py
python scripts/check_fortran_architecture.py
git diff --check
~~~

The second formatter invocation must be clean. The CI workflow runs the same
check and fails if formatting the copied source tree would produce a diff.
