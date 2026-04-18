# Goal 3 — Dry Run and Path Handling Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Both test sets exist** — `results/tc/03/dry-run/` and `results/tc/03/path-only/` both contain capture files.
2. **Dry run: HEAD unchanged** — `head-before.txt` and `head-after.txt` both exist and have the same value.
3. **Dry run: state not committed** — `status-after.txt` shows the change remained available after dry-run, or equivalent dry-run evidence proves no commit was created.
4. **Path handling: single file committed** — `git-show-stat.stdout` shows only the specified file in the commit.
5. **Path handling: other file uncommitted** — `status-after.txt` under `path-only/` shows the other modified file remained in the working tree.

## Verdict

- **PASS**: Dry run preserves HEAD and does not silently commit the pending change. Path filtering commits only the specified file.
- **FAIL**: HEAD changed during dry run, or wrong files committed.

Report: `PASS` or `FAIL` with evidence.
