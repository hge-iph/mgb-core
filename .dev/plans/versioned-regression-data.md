# Versioned Magdalena regression data

## Objective and boundary

Stop adding or replacing large regression binaries in Git while preserving reproducible input and expected-output versions. Store the fixture as a versioned asset in a release of the private `HGE-IPH/MGB-model` repository. Keep small case manifests and configuration overrides in the source tree. This change removes binaries from future Git revisions; it does not erase blobs already present in repository history.

## Repository state and evidence

- `tests/regression/magdalena_inertial/` occupies about 40 MB and `tests/regression/magdalena_muskingum/` about 7 MB. `precipitation.bin` is about 24 MB; each main expected output is 2,407,248 bytes. The current fixture has 458 catchments and 1,314 output records.
- `tests/regression/magdalena_inertial/manifest.json` points to local `input` and `expected`. `tests/regression/magdalena_muskingum/manifest.json` reuses the inertial input and applies its own `config.nml` override, then compares against its own `expected`.
- `tests/regression/run_regression.py` copies local input into a disposable work directory and passes the local expected directory to `compare_regression.py`. It has no download, cache, or integrity layer.
- The repository currently has no GitHub Releases. `.github/workflows/regression-gfortran.yml` grants `contents: read` and already runs both CTest regressions. The repository is private, so release downloads need authenticated repository read access.
- Some tracked expected outputs are empty because their corresponding output stream was disabled. Preserve their bytes in the archive; comparison remains controlled by the case manifests.

## Release artifact and tracked metadata

1. Create a first release tagged `regression-data-v1` with one asset named `magdalena-fixtures-v1.tar.gz`. Its archive roots are `magdalena_inertial/input/`, `magdalena_inertial/expected/`, and `magdalena_muskingum/expected/`. Retain both `config.nml` files, both case manifests, and the Muskingum override in Git; the staged inertial configuration is copied from the tracked file.
2. Record in tracked case metadata the release tag, asset name, archive SHA-256, archive layout version, source commit SHA, and individual SHA-256 digests for the files each case needs. A case must use one pinned release version; never resolve `latest`.
3. Build the archive reproducibly from the current tracked files, inspect its path list and hashes, and publish it before deleting the tracked binaries. Make the release draft first, attach and verify the asset, then publish. If release immutability is available to the repository, enable it before publication. The tracked SHA-256 remains the test's integrity check.
4. Every accepted baseline update produces a new release tag and asset. Keep prior releases available so an earlier source revision can still fetch its matching fixture. Record scientific rationale, compiler environment, and comparison statistics in the release notes and source change.

## Fixture resolver and runtime behavior

- Add a small Python fixture resolver used by `run_regression.py`, leaving `compare_regression.py` concerned only with local files. Resolve in this order: explicit `--fixtures-dir`, verified archive cache, authenticated release download. `--fixtures-dir` names an extracted directory with the archive roots above; validate required paths and their tracked per-file digests before running.
- Cache the downloaded archive under a digest-specific path, for example `~/.cache/mgb-model/regression/<sha256>/`. Hash the archive before reuse. Download to a temporary file, verify SHA-256, and atomically place it in the cache. Extract only after verifying that members are ordinary files under allowed roots; reject traversal, absolute paths, links, unexpected files, and duplicate names.
- In CI, use the job's `GITHUB_TOKEN` with repository `contents: read`. Locally, accept an explicit token environment variable or use the configured Git credential helper for `github.com`. Do not require `gh`. Never print a token, credential-helper response, authenticated URL, or request header.
- Stage verified input files into the existing disposable runtime directory, then overlay the case's tracked `config.nml`. Point comparison at the verified expected directory. Fail clearly on missing credentials, inaccessible release, absent asset, hash mismatch, invalid archive layout, or missing file. Do not fall back silently to an older release or an unverified local copy.
- Remove tracked large input and expected files only after the release exists and a clean checkout passes both routing regressions through the resolver. Keep repository documentation aligned with the new download and offline commands.

## Validation commands and scenarios

After implementation and release publication, test a cold download and a second run using the cache:

```bash
python3 -m unittest discover -s tests/regression
FC=gfortran cmake -S . -B build/gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/gfortran
ctest --test-dir build/gfortran --output-on-failure -R regression_magdalena_
python3 tests/regression/run_regression.py \
  --case-dir tests/regression/magdalena_inertial \
  --exe build/gfortran/mgb_model \
  --fixtures-dir /path/to/extracted/magdalena-fixtures-v1
```

Repeat CTest with Linux `ifx` and the validated Windows `ifx` environment. For Windows use `ctest --test-dir build/ifx -C Release --output-on-failure -R regression_magdalena_`. Exercise the same offline directory for both routing cases.

Automated resolver tests use a local HTTP fixture or mocked GitHub responses. Cover cache hit, cold download, interrupted download, 401/403/404, no credential, wrong SHA-256, missing per-file digest, unsafe archive member, unexpected root, and an explicit offline directory. Assert that failures never execute the model.

## Acceptance gates

- A clean checkout with repository read access downloads the pinned release and passes both Magdalena regressions.
- An offline run with a verified extracted fixture passes both regressions without network access.
- The archive and every staged file match tracked hashes; credentials stay out of logs.
- Large fixture files are removed from current Git tracking only after the release and both end-to-end paths are verified. Prior release versions remain available.
