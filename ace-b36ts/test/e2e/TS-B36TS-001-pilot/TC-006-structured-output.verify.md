# Goal 6 — Structured Output Integration Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Artifacts exist** — At least one integration artifact exists in `results/tc/06/` proving a downstream tool consumed the structured output (e.g., a directory was created from path output, a jq-extracted field is saved to a file).
2. **No manual munging** — The evidence shows direct consumption (tool output piped or fed directly to the downstream tool), not post-processed strings.
3. **Downstream tool success** — The integration artifact is valid and non-empty — the downstream tool actually worked (e.g., directory exists, extracted JSON field is present and correct).

## Verdict

- **PASS**: At least one integration artifact exists proving a real downstream tool successfully consumed the structured output without manual transformation.
- **FAIL**: No integration artifacts, evidence of manual string processing, or downstream tool failure.

Report: `PASS` or `FAIL` with evidence (artifacts found and what they demonstrate).
