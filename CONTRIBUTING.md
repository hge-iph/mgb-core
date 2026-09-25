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

The [setup and build guide](docs/development/build.md) covers
the recommended development container, Python tools, initial GNU Fortran build,
and native setup for a validated environment.

## Make a focused change

Keep a branch and pull request focused on one purpose. Do not combine a bug
fix, broad formatting, unrelated cleanup, and a new feature in the same change.
In particular, separate behavior-preserving modernization from intentional
scientific changes.

Follow the detailed project standards:

- [architecture and dependency rules](docs/architecture/components-and-dependencies.md);
- [coding conventions](docs/development/coding-conventions.md).

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

The [automation and documentation guide](docs/development/continuous-integration.md)
describes the strict site build. The [testing and debugging guide](docs/development/testing.md)
describes formatting, architecture, build, regression, and fixture checks.
Consult the [setup and build guide](docs/development/build.md) when a
change is specific to a compiler or operating system. The
[automation and documentation guide](docs/development/continuous-integration.md)
records the pull-request baseline.

## Update tests and documentation

A pull request should leave the repository documentation and regression
coverage consistent with the code:

- Add or update a test for a defect fix or behavior change when practical.
- Treat changed regression output as an intentional scientific result: explain
  and review it before updating expected files.
- Update the [I/O reference](docs/architecture/io-reference.md) when a
  configuration key or file contract changes.
- Update the process documentation when scientific assumptions or execution
  order change.
- Update [components and dependencies](docs/architecture/components-and-dependencies.md) or
  [design-decisions](docs/architecture/design-decisions.md) pages when module
  responsibilities, dependencies, or durable design constraints change.
- Update the [build](docs/development/build.md), [testing](docs/development/testing.md),
  or contribution guides when their workflows change.

If no test or documentation update is needed, briefly explain why in the pull
request.

### Keep the documentation boundary clear

The [automation and documentation guide](docs/development/continuous-integration.md)
defines the boundary between technical documentation in `docs/` and contributor
workflow instructions in this file.

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
