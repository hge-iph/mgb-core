# Evaluation and possible adoption of scaled output storage

## Objective and boundary

Evaluate whether selected ordinary model outputs can use 8-bit or 16-bit scaled integers without losing scientifically meaningful information. A scaled 32-bit integer does not reduce per-value storage relative to the current float32 output and is excluded. Change the default representation only for variables whose range and resolution budgets receive scientific approval. Hotstarts reconstruct state and are outside this output-storage change.

## Repository state and numerical evidence

- `src/vars/state.f90` allocates ordinary output staging arrays as `real(4)`. `src/io/output_io.f90` writes one unformatted direct-access record per timestep, with catchments in array order and no format header. Existing Python regression readers assume raw little-endian float32. External readers may make the same assumption.
- With 200,000 catchments and 10,958 daily timesteps, one float32 output stream contains 2,191,600,000 values and occupies about 8.164 GiB. At the current upper bound of 22 streams, total uncompressed storage is about 179.616 GiB. Halving value width would roughly halve payload storage; a header has negligible effect at this scale.
- Current Magdalena expected outputs show these observed ranges: inertial discharge `-1348.499` to `12048.933`, Muskingum discharge approximately zero to `17229.797`, inertial level `0.0217` to `2549.727`, flooded area `0.656` to `976.55`, and inertial total water storage `54.182` to `6704.265`. The ranges cover one small case and do not define national-scale bounds.
- Even with the full signed 16-bit code span, the inertial discharge range alone implies a scale of about 0.204 units per code and a half-step error near 0.102 units. Muskingum discharge implies about 0.263 units per code. This is a screening calculation, not evidence that either error is acceptable.

## Study and decision procedure

1. Inventory every ordinary output variable, its units, physical and configured range, source precision, missing-value convention, downstream calculations, visualization use, and known external readers. Consult model documentation and representative large simulations; do not infer the permitted range from the Magdalena fixture alone.
2. Write a proposed, variable-specific absolute resolution budget and valid range. Obtain scientific review of both before deciding the default format. The budget should represent useful hydrological precision, not the current broad regression tolerances.
3. For signed 8-bit and 16-bit candidates, reserve the minimum code for missing data and quantify the remaining range. Use `decoded = offset + scale * code` and `code = nint((value - offset) / scale)`, with positive scale and a documented rounding rule matching the writer. Choose offset and scale from the approved range and resolution budget; reject any candidate that cannot cover both. Never silently clip overflow.
4. Measure maximum, p99, and distribution of absolute and relative quantization errors per variable across representative runs; include near-zero, negative, and extreme values. Measure raw size, compressed size using the same compressor for each candidate, write/read time, and reader memory. Confirm that the quantized output remains suitable for each documented downstream use.
5. If a candidate passes its reviewed budget, make it the default for that variable. Keep float32 for variables that fail. Publish the selected policy and national-scale storage projection. If no candidate passes, retain all existing float32 defaults and record the study.
6. Update the regression reader so it can read both historical headerless float32 and the new versioned format. Do not quantize water-balance or inertial hotstarts through this pathway; their precision follows continuous-versus-restart equivalence.

## Binary interface for any adopted integer output

Keep the existing output filename but give integer-coded files a versioned 48-byte little-endian header followed by timestep-major catchment values:

- Bytes 0–7: eight-byte magic `MGBQ001` followed by a zero byte.
- Bytes 8–11: signed 32-bit header version, initially 1.
- Bytes 12–15: signed 32-bit payload width, 8 or 16 bits.
- Bytes 16–19: signed 32-bit catchment count.
- Bytes 20–23: signed 32-bit timestep count.
- Bytes 24–31: float64 scale.
- Bytes 32–39: float64 offset.
- Bytes 40–43: signed 32-bit missing-value code, `-128` or `-32768`.
- Bytes 44–47: reserved zero bytes.
- Payload: signed integers of the declared width in record order; 16-bit words use little-endian byte order.

Use round-to-nearest with halfway cases away from zero, matching Fortran `NINT`. Reject a value outside the representable non-missing codes or a non-finite value without an approved missing-data mapping. Validate header version, dimensions, file length, scale, width, and reserved bytes before decoding. A file without the magic is interpreted as historical raw float32 only when its expected shape and length match. Document the per-variable scale and offset policy and provide a Python reference decoder and migration example for external readers. The format change is deliberate compatibility work and must be called out in release notes.

## Validation commands and acceptance gates

```bash
python3 -m unittest discover -s tests/regression
FC=gfortran cmake -S . -B build/gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/gfortran
ctest --test-dir build/gfortran --output-on-failure -R regression_magdalena_
FC=ifx cmake -S . -B build/ifx -DCMAKE_BUILD_TYPE=Release
cmake --build build/ifx
ctest --test-dir build/ifx --output-on-failure -R regression_magdalena_
```

Run `ctest --test-dir build/ifx -C Release --output-on-failure -R regression_magdalena_` in the validated Windows Intel environment. Record OS, compiler, CMake flags, output selection, timing method, and input version.

- Codec tests cover negative and zero values, both valid code endpoints, halfway rounding, missing code, non-finite input, overflow, malformed header, byte order, record count, and historical float32 decoding.
- Quantization evidence for each adopted variable stays within its approved absolute resolution and valid range on representative runs. Regression output comparisons account for the quantization budget rather than treating binary equality as the scientific criterion.
- Default-format changes happen only after scientific review of each variable's range and resolution. A reference reader, binary specification, external-reader migration guidance, and projected national-scale storage accompany any change.
