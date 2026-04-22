# Architecture Bootstrap

This bootstrap phase does not refactor model internals. It adds only the minimum infrastructure needed for repeatable build and regression execution.

## Current Runtime Flow

At startup the main program:

- reads `infomgb.sim`
- allocates state
- loads static parameters, topology, and climate inputs
- opens runtime input and output files
- enters the simulation loop

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
