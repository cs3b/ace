# Goal 4 — Output Routing Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **All capture sets exist** — `results/tc/04/` contains stdout/exit files for threshold and override checks.
- **Exit codes zero** — `small.exit`, `large.exit`, `large-to-stdio.exit`, and `small-to-cache.exit` all contain `0`.
- **Small preset to stdio** — `small.stdout` contains actual content and does NOT contain cache-save messaging.
- **Large preset to cache** — `large.stdout` contains cache-save messaging and does NOT inline full content.
- **Large forced to stdio** — `large-to-stdio.stdout` contains actual content and does NOT contain cache-save messaging.
- **Small forced to cache** — `small-to-cache.stdout` contains cache-save messaging.

## Verdict

- **PASS**: Threshold and explicit override routing both behave as expected.
- **FAIL**: Any routing mode is wrong, exits are non-zero, or captures are missing.

Report: `PASS` or `FAIL` with evidence (content snippets, presence/absence of cache indicators).
