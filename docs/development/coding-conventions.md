# Coding conventions

English is the working language for new source identifiers, comments,
documentation, build messages, and developer tooling. Source formatting is
checked with fprettify 0.3.7 using the committed `.fprettify.rc` settings and
the pinned dependency in `requirements-dev.txt`.

## Language and naming

- Modules, routines, variables, and source files use descriptive
  `lower_snake_case` names.
- State and data names are nouns; routine names use leading verbs.
- Shared model variables remain in the role-based `config`, `forcing`,
  `parameters`, and `state` modules. These variables do not use `*_state`
  modules or derived-type subdivisions.
- Collection sizes carry `_count`, and general lookup indices carry `_index`.
  Equation kernels use role-qualified local indices such as `i_catch`,
  `i_hru`, `i_sub`, `i_step`, `i_reach`, and `i_face`.
- Fortran file-unit constants carry `_unit`.
- Conventional scientific terms such as `q`, `v`, `et`, `dt`, `hru`, `x`, and
  `y` remain valid components of descriptive names.
- Physical units appear in declaration or interface comments, not in names;
  `_unit` remains reserved for Fortran file-unit constants.

Scientific equation kernels may use compact lowercase notation when it makes
an established equation recognizable. A symbol block at the start of the
routine records the meaning and units of every compact symbol. Compact names
remain local variables or dummy arguments rather than public state or
assignment-only aliases. For example, a soil-water kernel may use `p`, `w`,
`wm`, `b`, `lambda`, `k_int`, `d_sup`, and `dt`, while persistent arrays retain
descriptive names such as `precipitation` and `soil_water_storage`.

Semantic qualifiers such as `_prev`, `_curr`, `_in`, `_out`, `_up`, and
`_down` identify state relationships; numbered state names are not used. Each
symbol retains one physical quantity. Persistent state uses descriptive names
such as `catchment_q_current` and `inertial_q`.

## Comments and runtime names

Comments explain intent, units, assumptions, file layouts, and non-obvious
hydrological or numerical behavior. They describe the reason for a statement
rather than restating it. Version control carries edit history; dated
modification banners, author initials, manual call inventories, and disabled
debug prints are absent from source comments.

Published titles and proper names retain their original language. A Portuguese
domain term with no unambiguous direct translation is retained and explained
in the surrounding documentation.

The current runtime interface uses the namelist groups and keys documented in
the [I/O reference](../architecture/io-reference.md), together with the
established input filenames listed there. Historical names are not accepted as
aliases. Binary layouts, numerical values, units, and execution order remain
stable.

## Fortran style

- Indentation uses four spaces, and tabs are forbidden.
- Source lines, including OpenMP directives, are at or below 132 columns.
- Fortran keywords, intrinsics, identifiers, operators, and logical constants
  use lowercase.
- Prose comments, user-facing strings, publication titles, and proper names
  retain their case.
- Spaces surround commas and assignment, relational, logical, and additive
  operators. Multiplication, division, and exponentiation remain compact.
- Declarations use explicit double-colon syntax, with one variable per line.
- Each `allocate` or `deallocate` statement has one target.
- Behavioral, common, I/O, and runner modules have default `private`
  visibility and list their public API. The five modules under `src/vars` are
  intentionally default-public.
- Every project-module import has an `only` list with one imported name per
  line.
- Project procedure definitions have one dummy argument per line. Project
  subroutine calls have one actual argument per line; intrinsic calls and
  project mathematical function references remain inline.
- Nested blocks use four-space indentation.
- Every continuation line begins with `&` and is indented four spaces beyond
  the statement it continues.
- Non-procedure lists break at commas; continuation indentation follows the
  statement structure.
- Mathematical equations remain on one physical line. Meaningful same-kind
  scalar terms provide shorter equations when a line would exceed 132 columns
  or decomposition clarifies the scientific equation.
- Long format-control literals may retain their continuation marker at the
  statement indentation when required by the line-length limit.
- Kinds, interfaces, relational syntax, calculations, and declaration
  semantics remain unchanged when formatting is the only change.

Numeric `format` labels retain their required source syntax. Generated
documentation, namelist values, and runtime strings use their own formatting.
The formatter preserves relational operators because the source's established
relational syntax remains part of the behavior-preserving style migration.

## Policy checks

The repository-root reference commands are:

```bash
python -m pip install -r requirements-dev.txt
python scripts/check_fortran_format.py
python scripts/check_fortran_architecture.py
git diff --check
```

The format checker runs fprettify on a temporary copy, then validates
indentation, continuation markers, line lengths, equations, declarations,
allocation targets, imports, procedure definitions, and project subroutine
calls. CI runs the same policy checks.
