# Goal 3 — Discovery to Listing Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **List capture sets exist** — `results/tc/03/` contains stdout/stderr/exit files for both list commands.
2. **List commands succeeded** — `list.exit` and `list-tree.exit` are `0`.
3. **Listings are actionable** — At least one listing output includes protocol URI(s) or path rows usable for follow-on commands.
4. **No internal-priority assertion** — Verification avoids requiring extension-priority internals; it evaluates visible browse usefulness only.

## Verdict

- **PASS**: Listing commands succeed and produce actionable browse output.
- **FAIL**: Missing captures, non-zero exits, or empty/non-actionable listing output.

Report: `PASS` or `FAIL` with evidence (listing snippets and exit codes).
