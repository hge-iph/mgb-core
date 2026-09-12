# Task 1: Numerical naming and repository-wide formatting

## Objective

Make the numerical code concise and recognizable while applying one consistent
Fortran layout across the repository. This task must not change scientific
behavior or regression outputs.

Complete this task before the state-ownership and dependency restructuring in
Task 2.

## Naming conventions

Rename the persistent parameter arrays as follows:

- `arno_b` becomes `b_arno`.
- `brooks_corey_lambda` becomes `lambda_brooks_corey`.
- `concentration_time` becomes `time_of_concentration`.

Use the following compact names only within numerical kernels:

- `b` is the local ARNO saturation-curve parameter.
- `lambda` is the local Brooks-Corey pore-size index.
- In the runoff module, `d_*` denotes runoff depth and `q_*` denotes runoff
  discharge. Existing distinctions such as `d_sup`, `d_int`, `d_bas`, `q_sup`,
  `q_int`, and `q_bas` must remain clear.
- In routing modules, `r` denotes catchment runoff entering the river and `q`
  denotes routed river discharge.

Persistent state must retain descriptive names. Compact symbols belong only in
the local scope of a scientific equation kernel.

Use the phrase "time of concentration" consistently in identifiers, comments,
and documentation. Do not use "concentration time."

## Equation preparation

At the top of each relevant scientific loop iteration, load persistent array
inputs and mutable state into short, documented local scalars. Do this for the
inputs to the equations even when the original expression would fit within the
line-length limit.

Do not create aliases for loop indices, constants, or already-clear one-step
copies. Compute branch-dependent or sequential intermediate values immediately
before their first use when computing them at the literal top of the loop could
make them stale or change evaluation order.

Use meaningful scalar intermediates to expose the terms of an equation. Write
updated persistent state and outputs back explicitly near the end of the
iteration.

Every equation must:

- occupy one physical source line;
- remain within the 132-column free-form Fortran limit;
- be decomposed based on clarity, not only when it exceeds 132 columns; and
- preserve the existing order of dependent calculations.

Do not split mathematical expressions over continuation lines. Intrinsics,
type conversions, array indexing, and small mathematical functions remain
inline when used in an equation.

## Clarification comments

Each compact symbol must have its own clarification-comment line near the start
of the routine. Do not group several symbols on one comment line.

Each line must state the symbol's physical meaning and units where applicable.
The description must preserve important distinctions such as runoff depth,
runoff discharge, river discharge, storage, rate, and timestep-scaled quantity.

Example:

```fortran
! p       precipitation [mm per step]
! w       soil-water storage [mm]
! wm      maximum soil-water storage [mm]
! b       ARNO saturation-curve parameter [1]
! lambda  Brooks-Corey pore-size index [1]
```

## Repository-wide Fortran layout

Apply these rules to every Fortran source file in the repository:

- Declare one variable per declaration line.
- Put one allocation target in each `allocate` statement.
- Put one deallocation target in each `deallocate` statement.
- Put one imported name on each line of a `use ..., only:` list.
- Put one dummy argument on each line of a project procedure definition.
- Put one actual argument on each line of a project procedure call.
- Keep intrinsic functions, conversions, array indexing, and compact
  mathematical functions inline.
- Keep equations inline as specified above.

State modules must remain default-private and place `public` on each exported
state declaration. Avoid detached, module-wide public lists for state
variables. Behavioral modules may retain short public lists for their public
procedures.

Example state declarations:

```fortran
integer, public :: catchment_count
real, allocatable, public :: catchment_area(:)
real, allocatable, public :: river_discharge(:)
```

Example import and procedure layout:

```fortran
use runoff_state, only: &
    b_arno, &
    lambda_brooks_corey

call update_soil_water_balance( &
    p, &
    et_soil, &
    w, &
    wm, &
    b, &
    lambda)
```

## Documentation

Update `docs/development/language-and-naming.md` so the documented conventions
match the implemented code. Check related examples and terminology throughout
the English documentation, including the phrase "time of concentration."

Do not describe architectural ownership that will only become true after Task
2. Architectural documentation is finalized as part of Task 2.

## Validation throughout the task

Keep the repository buildable and integrated after each coherent portion of
the work.

On the available validated platform and compiler:

1. Configure and build with CMake.
2. Run `regression_magdalena_inertial`.
3. Run `regression_magdalena_muskingum`.
4. Confirm that neither regression baseline requires an update.
5. Review the affected equations for evaluation-order or precision changes.

Do not accept intentional scientific-output changes. Document any unavoidable
floating-point difference before considering the task complete.

## Completion criteria

- All Fortran files follow the structural layout rules.
- All scientific kernels follow the staging and inline-equation rules.
- The agreed ARNO, Brooks-Corey, runoff, and routing vocabulary is used
  consistently.
- Symbol clarification blocks contain one symbol per line with meaning and
  units.
- Naming documentation matches the source.
- The project builds successfully.
- Both Magdalena regressions pass against their existing baselines.

