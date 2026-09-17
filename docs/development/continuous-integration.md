# Automation and documentation

Pull requests and pushes are checked by GitHub Actions. The workflows use the
same build, test, formatting, and documentation commands described in this
site.

## Documentation workflow

The documentation workflow runs on pull requests and pushes to `main`. It
uses Python 3.12, installs `requirements-docs.txt`, and runs
`python -m mkdocs build --strict`. A successful push to `main` uploads the
generated `site/` directory and deploys it to GitHub Pages.

## Fortran format and architecture workflow

The format workflow runs on pull requests and pushes. It installs the pinned
development tools, checks Fortran formatting, checks the module architecture,
and runs the focused architecture-checker unit tests.

## GNU Fortran regression workflow

The regression workflow runs on pull requests and on demand. On Ubuntu 24.04
it installs GNU Fortran 13, configures `build/linux-gfortran`, builds the
executable, and runs the complete CTest suite. Failed runs upload the CTest
log as an artifact.

The [testing guide](testing.md) describes the Magdalena fixtures and the
[build guide](build.md) records validated compiler environments. Workflow
definitions remain under `.github/workflows/`.

## Documentation maintenance

The MkDocs site is built from `docs/` with the configuration in `mkdocs.yml`.
Documentation dependencies are pinned in `requirements-docs.txt`.

Install the dependencies and start the development server with:

```bash
python3 -m pip install -r requirements-docs.txt
python3 -m mkdocs serve
```

Build the strict site used by pull-request validation with:

```bash
python3 -m mkdocs build --strict
```

The generated site is written to `site/` and is not committed.

## Documentation boundaries

Technical explanations belong in `docs/`: architecture, scientific domains,
execution and data flow, shared state, I/O contracts, formulation, and durable
design decisions. Contributor workflow instructions remain in
`CONTRIBUTING.md`, which links to the canonical technical pages.

Model pages explain scientific concepts, equations, processes, parameters,
and assumptions. Architecture pages explain source structure, module
interfaces, state organization, execution flow, and runtime file ownership.
Development pages explain environments, builds, testing, debugging,
automation, documentation maintenance, and coding standards.

Documentation uses declarative, active prose with concrete technical terms.
Headings and lists state facts, responsibilities, or behavior. Explanations
record intent, assumptions, units, file formats, and non-obvious hydrological
behavior.
