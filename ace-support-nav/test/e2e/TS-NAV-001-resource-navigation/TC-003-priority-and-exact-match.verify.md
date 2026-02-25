# Goal 3 — Inference Priority and Exact Match Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Both capture sets exist** — `results/tc/03/` contains stdout/stderr/exit captures for both priority and exact-match tests.
2. **Both exit codes zero** — Both resolutions succeeded (exit code `0`).
3. **Priority: shorthand wins** — The priority stdout contains a path ending in `.g.md` (not `.guide.md` or bare `.md`), proving shorthand has highest priority.
4. **Exact match: explicit extension used** — The exact-match stdout contains a path ending in `.guide.md`, proving the explicit extension was used directly without inference.

## Verdict

- **PASS**: Priority test selected shorthand `.g.md` over alternatives. Exact-match test used the explicit extension directly.
- **FAIL**: Wrong extension selected in priority test, exact match triggered inference, or captures missing.

Report: `PASS` or `FAIL` with evidence (resolved paths from each stdout file).
