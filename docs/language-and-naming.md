# Language and Naming

English is the working language for new source identifiers, comments,
documentation, build messages, and developer tooling. The purpose of this rule
is to make maintenance accessible without erasing established MGB terminology
or changing runtime interfaces.

## Source identifiers

- Use descriptive `lower_snake_case` names for modules, routines, variables,
  and source files.
- Use nouns for state and data, and verb-led names for routines.
- Add `_count` to collection sizes and `_index` to loop or lookup indices.
- Add `_unit` to Fortran file-unit constants.
- Conventional scientific terms such as `q`, `v`, `et`, `dt`, `hru`, `x`, and
  `y` may remain as components of a descriptive name.
- Include units in the name only when otherwise ambiguous; always document the
  units at the declaration or interface.

## Comments

Comments should explain intent, units, assumptions, file layouts, and
non-obvious hydrological or numerical behavior. Do not repeat the statement
below the comment, keep a manual call inventory, or retain disabled debug
prints. Use version control for edit history instead of dated modification
banners and author initials.

Published titles and proper names remain in their original language. When a
Portuguese domain term has no unambiguous direct translation, retain it and add
it to the [glossary](glossary.md).

## Runtime interface

The current runtime interface is the descriptive English interface documented
in the [I/O reference](io-reference.md). The migration is deliberately
breaking: old names are not accepted as aliases. Binary layouts, numerical
values, units, and execution order remain stable.

The source formatting rules are maintained separately in the
[Fortran style guide](fortran-style.md).
