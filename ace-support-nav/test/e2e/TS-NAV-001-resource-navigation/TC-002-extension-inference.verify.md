# Goal 2 — Extension Inference Chain Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Three resolution sets exist** — `results/tc/02/` contains stdout/stderr/exit captures for shorthand, full, and generic resolution attempts.
2. **All exit codes zero** — All three resolutions succeeded (exit code `0`).
3. **Shorthand resolves to .g.md** — The shorthand stdout contains a path ending in `.g.md`.
4. **Full resolves to .guide.md** — The full stdout contains a path ending in `.guide.md`.
5. **Generic resolves to .md** — The generic stdout contains a path ending in `.md` (but not `.g.md` or `.guide.md`).

## Verdict

- **PASS**: All three resolutions succeeded with correct extension matches at each fallback level.
- **FAIL**: Any resolution failed, wrong extension matched, or captures missing.

Report: `PASS` or `FAIL` with evidence (resolved paths from each stdout file).
