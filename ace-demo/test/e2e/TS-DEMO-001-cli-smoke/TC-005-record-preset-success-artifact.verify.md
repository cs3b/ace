# Goal 5 - Record Preset Success Artifact Verification

## Expectations

Validation order (impact-first):
1. Confirm filesystem/artifact evidence under `results/tc/05/`.
2. Use debug captures only as fallback.

Contract anchors:
- `ace-demo/docs/usage.md` (`ace-demo record hello` example and non-dry-run behavior)

1. `record-success.exit` is `0`.
2. `record-success.stdout` indicates recording succeeded (for example includes
   `Recorded:` and references the output path).
3. `artifact-ls.exit` is `0` and listing includes `hello.gif`.
4. If `record-success.stderr` explicitly reports that no browser binary is available, treat that as valid constrained-environment evidence for this high-cost recording path.

## Verdict

- **PASS**: Non-dry-run `record` succeeds and produces a concrete output artifact, or the artifacts show an explicit browser-dependency constraint rather than an ambiguous product failure.
- **FAIL**: Command fails without clear dependency evidence, success signal is missing, or artifact evidence is absent.
