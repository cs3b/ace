# Goal 3 — Dry Run and Path Handling Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **Both test sets exist** — results/tc/03/ contains captures for both dry-run and path-handling tests.
- **Dry run: HEAD unchanged** — Evidence shows HEAD hash was the same before and after dry-run.
- **Dry run: changes still staged** — Evidence shows the changes remain staged after dry-run.
- **Path handling: single file committed** — Git show --stat shows only the specified file in the commit.
- **Path handling: other file uncommitted** — Evidence shows the other modified file remains in working tree.

## Verdict

- **PASS**: Dry run preserves HEAD and staged changes. Path filtering commits only the specified file.
- **FAIL**: HEAD changed during dry run, or wrong files committed.

Report: `PASS` or `FAIL` with evidence.
