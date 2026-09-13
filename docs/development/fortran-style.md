# Fortran style guide

The repository checks every Fortran 90 source with fprettify 0.3.7. The
formatter validates Fortran-aware whitespace without replacing the manual
continuation layout. Its settings are committed in `.fprettify.rc` and the
dependency is pinned in `requirements-dev.txt`.

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
- Give behavioral, common, I/O, and runner modules default `private` visibility and list their
  public API. The four modules under `src/vars` are intentionally default-public.
- Use `only` lists for every project-module import.
- Indent nested blocks in four-space increments.
- Put `&` at the start of every continuation line and indent it four spaces
  beyond the statement that it continues.
- Break lists at commas and expressions or calls at natural operator and
  argument boundaries; avoid aligning continuations under arbitrary tokens.
- Long format-control literals may keep their continuation marker at the
  statement indentation to remain within the line-length limit.
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

OpenMP directive lines beginning with `!$omp` are the one line-length
exclusion: fprettify 0.3.7 does not safely split their private lists, and
rewriting those directives would change parallel-region syntax rather than
formatting whitespace. Numeric `format` labels retain their required source
syntax. Comments are not lowercased because prose and citations are
documentation.
Generated documentation, namelist values, and runtime strings are not
formatted as Fortran source.

## Checks

Run from the repository root:

~~~bash
python -m pip install -r requirements-dev.txt
python scripts/check_fortran_format.py
python scripts/check_fortran_architecture.py
git diff --check
~~~

The format checker runs fprettify on a temporary copy to validate the source,
then checks indentation, continuation markers, whitespace, and line lengths
in the working tree. The CI workflow runs the same check.
