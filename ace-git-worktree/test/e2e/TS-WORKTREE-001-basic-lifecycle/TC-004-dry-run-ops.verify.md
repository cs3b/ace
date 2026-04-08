# Goal 4 — Dry-Run Operations Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Dry-run artifacts exist** — results/tc/04/ contains captures for both create-dry and remove-dry.
2. **Create dry-run shows plan** — create-dry.stdout indicates what would be created (path or branch name) and exit code is 0.
3. **Create dry-run is no-op** — create-dry-check.txt confirms the planned child worktree directory does NOT exist after dry-run (checking only the parent `.ace-wt` directory is insufficient).
4. **Remove dry-run shows target** — remove-dry.stdout identifies the worktree that would be removed and exit code is 0.
5. **Remove dry-run is no-op** — remove-dry-check.txt confirms the targeted worktree still exists after dry-run.

## Verdict

- **PASS**: Both dry-run operations show plans without making actual changes.
- **FAIL**: Dry-run actually creates/removes, or captures missing, or exit codes non-zero.

Report: `PASS` or `FAIL` with evidence (output snippets, filesystem checks).
