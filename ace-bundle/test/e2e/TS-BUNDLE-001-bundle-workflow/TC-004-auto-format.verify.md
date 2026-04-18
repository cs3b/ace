# Goal 4 — Output Routing Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

- **All capture sets exist** — `results/tc/04/` contains stdout/exit files for default and override routing checks.
- **Exit codes are zero** — `small.exit`, `large.exit`, `large-to-stdio.exit`, and `small-to-cache.exit` all contain `0`.
- **Default small routing is user-visible** — `small.stdout` contains bundle content and does not only show cache-save messaging.
- **Default large routing is user-visible** — `large.stdout` records cache-save messaging instead of fully inlined content.
- **Large explicit stdio request has valid outcome** — `large-to-stdio.stdout` shows either inline content or successful cache-save fallback messaging.
- **Small explicit cache request routes to cache** — `small-to-cache.stdout` contains cache-save messaging.

## Verdict

- **PASS**: Default and explicit routing behaviors match user-visible contract expectations.
- **FAIL**: Missing artifacts, non-zero exits, or routing evidence inconsistent with requested/default behavior.

Report: `PASS` or `FAIL` with evidence (content snippets, cache indicators, exit codes).
