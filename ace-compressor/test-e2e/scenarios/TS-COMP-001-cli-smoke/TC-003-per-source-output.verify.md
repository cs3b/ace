# Goal 3 Verification - Per-source output directory behavior

## Expectation

Per-source mode succeeds and returns two output paths corresponding to both input files.

## PASS Criteria

- `results/tc/03/per-source.exit` is `0`
- `results/tc/03/per-source.stdout` has exactly 2 non-empty lines
- First output path line includes `b.` and second includes `a.`
- `results/tc/03/exports.ls` lists exactly 2 `.pack` files
