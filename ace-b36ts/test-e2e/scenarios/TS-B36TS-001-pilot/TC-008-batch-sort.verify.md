# Goal 8 — Batch Sort Order Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Required files exist** — `encode-order.tsv` and `sorted-order.tsv` both exist.
2. **Exactly four rows per file** — each file contains 4 non-empty rows.
3. **Row format is valid** — each row is `<token>\t<date>`; tokens match `[0-9a-z]{2,8}`.
4. **Sorted token order** — `sorted-order.tsv` is lexicographically sorted by token.
5. **Chronological alignment** — dates in `sorted-order.tsv` are non-decreasing, showing lexical token order tracks date order for this set.

## Verdict

- **PASS**: Required files and formats are valid, sorted file is truly sorted by token, and date order is non-decreasing.
- **FAIL**: Missing files, wrong row count/format, unsorted tokens, invalid tokens, or date order mismatch.

Report: `PASS` or `FAIL` with evidence (rows and ordering checks).
