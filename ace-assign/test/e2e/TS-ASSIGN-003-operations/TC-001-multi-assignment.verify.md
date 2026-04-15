# Goal 1 — Multi-Assignment Operator Flow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/01/`.
3. Use debug evidence only as fallback.

1. **Two assignments created** — evidence includes two distinct assignment IDs.
2. **List output includes both IDs**.
3. **Selection behavior works** — selected assignment status reflects active context.
4. **Explicit targeting works** — `--assignment <id>` status queries the intended assignment.
5. **Selection isolation** — explicit targeting does not unexpectedly overwrite active selection.

## Verdict

- **PASS**: Multi-assignment list/select/target operations behave as documented.
- **FAIL**: Missing assignment visibility, targeting mismatch, or selection corruption.

Report: `PASS` or `FAIL` with evidence (IDs, list/status outputs).
