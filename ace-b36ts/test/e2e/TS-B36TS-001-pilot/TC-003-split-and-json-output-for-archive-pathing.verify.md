# Goal 3 - Split and JSON Output for Archive Pathing Verification

## Expectations

Validation order (impact-first):
1. Confirm `results/tc/03/` contains captures for split, path-only, and json commands.
2. Confirm all command exits are `0`.
3. Confirm outputs demonstrate the intended shape differences:
   - split output includes hierarchical components,
   - path-only output is path-focused text,
   - json output is structured JSON content.

Required checks:
1. `split.exit`, `path-only.exit`, and `json.exit` are all `0`.
2. `path-only.stdout` is non-empty and resembles a segmented path.
3. `json.stdout` is parseable JSON-like content with split-related fields.

## Verdict

- **PASS**: Split/path/json outputs all succeed and provide distinct, usable archive-pathing signals.
- **FAIL**: Any command fails, expected outputs are missing, or output types are not distinguishable.
