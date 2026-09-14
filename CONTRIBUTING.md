# Contributing to MGB

This guide explains how to prepare and submit a change to this repository. The
[project documentation](docs/index.md) explains how the model is designed and
how it works.

## Before you start

Small, focused fixes can go directly to a pull request. Start an issue or a
design discussion before changing:

- scientific or numerical behavior;
- file structures and formats;
- module boundaries or dependency rules; or
- the runtime interface or established execution order.

Early discussion is also useful when the intended behavior is unclear or a
change is likely to span several modules. Record work-in-progress design notes
under `.dev/plans/`; update the public documentation only when a decision has
become part of the project.

## Get the source and create a branch

Group members work on branches in the main repository. Do not commit directly
to `main`. This workflow assumes that you have group write access to the
repository.

For a new checkout:

```bash
git clone https://github.com/HGE-IPH/MGB-model.git
cd MGB-model
```

Before each change, update `main` and create a branch from it:

```bash
git switch main
git pull --ff-only
git switch -c docs/contribution-guide
```

Use a short, descriptive branch name with a category prefix. Common prefixes
are:

| Prefix | Use |
| --- | --- |
| `docs/` | Documentation changes |
| `fix/` | Defect corrections |
| `feature/` | New behavior or capability |
| `refactor/` | Behavior-preserving source restructuring |
| `test/` | Test or fixture changes |
| `build/` | Build, tooling, or CI changes |

Examples include `fix/routing-boundary`, `refactor/io-layout`, and
`docs/hotstart-format`.

## Set up a development environment

### Recommended: development container

The repository's development container supplies CMake, Ninja, GNU Fortran,
Intel `ifx`, Python, and the editor extensions used for Fortran development.
Install a container runtime and Visual Studio Code with the Dev Containers
extension, open the repository, and run **Dev Containers: Reopen in Container**
from the command palette.

Install the Python tools used by the repository checks inside the container:

```bash
python3 -m pip install --break-system-packages \
  -r requirements-dev.txt -r requirements-docs.txt
```

The `--break-system-packages` option is appropriate for this disposable
development container. Do not use it to manage a system Python installation on
your workstation.

To create an initial GNU Fortran build in the container:

```bash
FC=gfortran cmake -S . -B build/linux-gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux-gfortran --parallel
```

### Native environment

Native development is also supported. Follow the complete
[build guide](docs/getting-started/build.md) for the prerequisites and commands
for a validated environment. Keep a separate build directory for each
compiler.

## Make a focused change

Keep a branch and pull request focused on one purpose. Do not combine a bug
fix, broad formatting, unrelated cleanup, and a new feature in the same change.
In particular, separate behavior-preserving modernization from intentional
scientific changes.

Follow the detailed project standards:

- [architecture and dependency rules](docs/development/architecture.md);
- [language and naming](docs/development/language-and-naming.md); and
- [Fortran style](docs/development/fortran-style.md).

New identifiers, comments, documentation, build messages, and developer tools
use English. Preserve numerical precision, record layouts, units, and
calculation order unless an agreed change explicitly requires otherwise.

## Commit the change

Review the files you changed before staging them:

```bash
git status
git diff
git add path/to/changed-file
git commit -m "improve contributor setup guidance"
```

Use clear, descriptive commit messages. No Conventional Commits prefix or
other rigid message format is required.

## Run relevant checks

Local builds and checks are strongly encouraged. They shorten review and catch
problems before CI, but contributors may rely on pull-request CI for checks
they cannot run locally. State what you ran in the pull request and explain any
checks left to CI.

Run this whitespace check for every change:

```bash
git diff --check
```

For documentation changes, build the site strictly:

```bash
python3 -m mkdocs build --strict
```

For Fortran source changes, run the formatting and architecture checks:

```bash
python3 scripts/check_fortran_format.py
python3 scripts/check_fortran_architecture.py
python3 -m unittest discover -s tests/architecture
```

When practical, build the model and run both Magdalena routing regressions:

```bash
FC=gfortran cmake -S . -B build/linux-gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux-gfortran --parallel
ctest --test-dir build/linux-gfortran --output-on-failure \
  -R regression_magdalena_
```

Source, CMake, and test-harness changes should receive build and regression
coverage. The [testing guide](docs/getting-started/testing.md) describes the
suite, individual runner commands, fixtures, and compared outputs. Consult the
[portability reference](docs/model/portability.md) when a change is specific to
a compiler or operating system.

Pull-request CI provides a common baseline by checking the documentation,
Fortran formatting and architecture, the architecture-checker tests, and the
GNU Fortran build and CTest suite.

## Update tests and documentation

A pull request should leave the repository documentation and regression
coverage consistent with the code:

- Add or update a test for a defect fix or behavior change when practical.
- Treat changed regression output as an intentional scientific result: explain
  and review it rather than silently replacing expected files.
- Update the I/O reference when a configuration key or file contract changes.
- Update the process documentation when scientific assumptions or execution
  order change.
- Update the architecture or design-decisions pages when module
  responsibilities, dependencies, or durable design constraints change.
- Update the build, testing, or contribution guides when their workflows
  change.

If no test or documentation update is needed, briefly explain why in the pull
request.

### Keep the documentation boundary clear

Place explanations of the software in `docs/`: architecture, model domains,
execution and data flow, shared state, I/O contracts, scientific formulation,
module APIs, and durable design decisions all belong there.

## Open a pull request

Push the branch to the main repository:

```bash
git push -u origin docs/contribution-guide
```

Open a pull request against `main` and complete the pull-request template. A
draft pull request is welcome when early feedback would help. After pushing,
use the link printed by Git or open the repository on GitHub and choose
**Compare & pull request**. The description should:

- explain the problem and the scope of the solution;
- link the prior discussion when one was required;
- identify scientific, numerical, and runtime-interface effects, or state that
  there are none;
- list the local checks run and those left to CI; and
- identify corresponding test and documentation changes.

Review your own diff before requesting review. Push follow-up commits to the
same branch when responding to comments; the existing pull request updates
automatically.

Every pull request requires at least one approving reviewer. Contributors do
not merge their own pull requests; an approving maintainer completes the merge
after the required checks pass.
