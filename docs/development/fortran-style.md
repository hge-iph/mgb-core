# Fortran style guide

The repository checks every Fortran 90 source with fprettify 0.3.7. The
formatter validates Fortran-aware whitespace without replacing the manual
continuation layout. Its settings are committed in `.fprettify.rc` and the
dependency is pinned in `requirements-dev.txt`.

## Required style

- Use four spaces for indentation. Tabs are forbidden.
- Keep source lines at or below 132 columns, including OpenMP directives.
- Use lowercase for Fortran keywords, intrinsics, identifiers, operators, and
  logical constants.
- Preserve case in prose comments, user-facing strings, publication titles,
  and proper names.
- Use spaces after commas and around assignment, relational, logical, and
  additive operators.
- Keep multiplication, division, and exponentiation compact.
- Use explicit double-colon declarations.
- Declare one variable per declaration line.
- Put one target in each `allocate` or `deallocate` statement.
- Give behavioral, common, I/O, and runner modules default `private` visibility and list their
  public API. The five modules under `src/vars` are intentionally default-public.
- Use `only` lists for every project-module import and put one imported name on each line.
- Put one dummy argument on each line of a project procedure definition.
- Put one actual argument on each line of a project subroutine call. Keep
  intrinsic calls and project mathematical function references inline.
- Indent nested blocks in four-space increments.
- Put `&` at the start of every continuation line and indent it four spaces
  beyond the statement that it continues.
- Break non-procedure lists at commas and avoid aligning continuations under
  arbitrary tokens.
- Keep every mathematical equation on one physical line. Introduce meaningful,
  same-kind scalar terms when an equation would exceed 132 columns or when
  decomposition makes the scientific equation clearer.
- Long format-control literals may keep their continuation marker at the
  statement indentation to remain within the line-length limit.
- Do not change kinds, interfaces, relational syntax, calculations, or
  declaration semantics merely to satisfy formatting.

The formatter is intentionally configured not to replace relational operators:
the source's existing relational syntax remains part of the behavior-preserving
style migration.

## Local exceptions

All source and comment lines meet the 132-column limit. Numeric `format` labels
retain their required source syntax. Comments are not lowercased because prose
and citations are documentation.
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
then checks indentation, continuation markers, line lengths, single-line
equations, declarations, allocation targets, imports, procedure definitions,
and project subroutine calls in the working tree. The CI workflow runs the same
check.
