# Language and Naming

English is the working language for new source identifiers, comments,
documentation, build messages, and developer tooling. The purpose of this rule
is to make maintenance accessible without erasing established MGB terminology
or changing runtime interfaces.

## Source identifiers

- Use descriptive `lower_snake_case` names for modules, routines, variables,
  and source files.
- Use nouns for state and data, and verb-led names for routines.
- Add `_count` to collection sizes and `_index` to general lookup indices;
  equation kernels use role-qualified local indices such as `i_catch`,
  `i_hru`, `i_sub`, `i_step`, `i_reach`, and `i_face`.
- Add `_unit` to Fortran file-unit constants.
- Conventional scientific terms such as `q`, `v`, `et`, `dt`, `hru`, `x`, and
  `y` may remain as components of a descriptive name.
- Do not encode physical units in names; document units in declaration or
  interface comments instead. Keep `_unit` for Fortran file-unit constants.

Scientific equation kernels use a deliberately narrower vocabulary than
persistent model state. Compact, lower-case notation is encouraged when it
makes an established equation recognizable, provided that a short symbol block
at the start of the routine records the meaning and units of every compact
symbol. For example, a soil-water kernel may use `p`, `w`, `wm`, `b_arno`,
`k_int`, `d_sup`, and `dt`, while the arrays that supply those values retain
descriptive names such as `precipitation` and `soil_water_storage`.

Compact names are local variables or dummy arguments, not public state or
assignment-only aliases. Use semantic qualifiers such as `_prev`, `_curr`,
`_in`, `_out`, `_up`, and `_down` instead of numbered state names. A symbol
must not silently change physical quantity: use separate names such as `d_sup`
for runoff depth and `q_sup` for the corresponding discharge after conversion.

## Comments

Comments should explain intent, units, assumptions, file layouts, and
non-obvious hydrological or numerical behavior. Do not repeat the statement
below the comment, keep a manual call inventory, or retain disabled debug
prints. Use version control for edit history instead of dated modification
banners and author initials.

Published titles and proper names remain in their original language. When a
Portuguese domain term has no unambiguous direct translation, retain it and
explain it in the surrounding documentation.

## Runtime interface

The current runtime interface uses the namelist groups and keys documented in
the [I/O reference](../model/io-reference.md), together with the established input
filenames listed there. Old names are not accepted as aliases. Binary layouts,
numerical values, units, and execution order remain stable.

The source formatting rules are maintained separately in the
[Fortran style guide](fortran-style.md).
