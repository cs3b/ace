# Goal 4 - Doctor Health to Failure Transition Verification

## Expectations

Validation order (impact-first):
1. Confirm explicit corrupted file evidence exists.
2. Confirm command artifacts under `results/tc/04/`.
3. Use debug captures as fallback.

1. `corrupted-file.path` exists, points to a scenario-local `.ace-retros/*.retro.md` file, and `corrupted-file.md` captures a structurally invalid frontmatter mutation.
2. `doctor-healthy.exit` is `0`.
3. `doctor-broken.exit` is non-zero (`1` expected).
4. `doctor-broken.stdout` or `.stderr` shows issue detection/failure messaging.

## Verdict

- **PASS**: Doctor reports healthy before corruption and failure after corruption with clear evidence.
- **FAIL**: Missing transition evidence, unchanged exit status, or missing corruption artifact.
