# Architecture Bootstrap

This bootstrap phase does not refactor model internals. It adds only the minimum infrastructure needed for repeatable build and regression execution.

## Current Runtime Flow

At startup the main program:

- reads `infoMGB.sim`
- allocates state
- loads static parameters, topology, and climate inputs
- opens runtime input and output files
- enters the simulation loop

## Working Directory Rule

The model currently resolves input and output directories relative to the process working directory in `src/1main.f90`:

- `INPUT_DIRECTORY = '.\\Input\\'`
- `OUTPUT_DIRECTORY = '.\\Output\\'`

That means the model behavior depends on the directory it is launched from unless a wrapper stages the runtime layout explicitly.

## Bootstrap Changes In This Phase

- opt-in non-interactive execution through `MGB_NONINTERACTIVE=1`
- canonical CMake build entry point
- first regression fixture and comparator
- staged runtime execution for the Magdalena regression case

## What This Phase Does Not Change

- hydrology or routing algorithms
- file formats
- global-state structure
- legacy module organization
