# Goal 8 — Batch Sort Order Verification

## Injected Context

The verifier receives the `goal/` directory tree and access to the sandbox path.

## Expectations

1. **Files exist** — Two files exist in `goal/8/`: one with encode-order IDs and one with sorted IDs.
2. **At least 4 IDs** — Each file contains at least 4 token/date pairs.
3. **Lexicographic = chronological** — The lexicographically sorted order of the tokens matches the chronological order of their original dates. Earlier dates produce tokens that sort before later dates.
4. **Valid tokens** — All tokens consist of lowercase alphanumeric characters only (base36 charset: `[0-9a-z]`).

## Verdict

- **PASS**: Both files exist with at least 4 IDs each. Lexicographic sort order of tokens matches chronological order of dates. All tokens are valid base36.
- **FAIL**: Files missing, fewer than 4 IDs, sort order does not match chronological order, or invalid tokens.

Report: `PASS` or `FAIL` with evidence (the two orderings and whether they align chronologically).
