# Goal 2 - Decode Roundtrip from Real Token Verification

## Expectations

Validation order (impact-first):
1. Confirm `results/tc/02/` contains captures for encode and both decode commands.
2. Confirm all command exits are `0`.
3. Confirm the same token is used for both decode commands, using `results/tc/02/token.txt` as the explicit shared token artifact.
4. Confirm decode outputs are non-empty and format-distinct (`iso` vs `timestamp`).

Required checks:
1. `encode.exit`, `decode-iso.exit`, and `decode-ts.exit` are all `0`.
2. `encode.stdout` contains a compact token and `results/tc/02/token.txt` records that same token.
3. `decode-iso.stdout` and `decode-ts.stdout` both contain meaningful decoded output.

## Verdict

- **PASS**: Roundtrip token generation and decode outputs are consistent and successful.
- **FAIL**: Any command fails, token continuity is broken, or decode outputs are missing/empty.
