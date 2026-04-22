# Goal 8 — Setup Failure Guidance Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox
path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **Artifacts exist** — `results/tc/08/` contains status snapshots and command
  captures.
- **Command failed intentionally** — exit capture is non-zero.
- **Staged set is clean** — the pre-command cached diff capture does not include
  `results/` paths.
- **Guidance surfaced** — captured output includes:
  - the failed model token (`codex:__invalid_setup_probe__`) or failed role/model context
  - `ace-llm --list-providers`
  - `ace-config doctor`
  - `ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"`
- **No unintended commit** — post-command status still reflects pending staged
  or unstaged changes for the attempted setup work.

## Verdict

- **PASS**: Failure output contains actionable setup guidance and deterministic
  fallback command.
- **FAIL**: Guidance is missing required commands/context, or behavior commits
  unexpectedly.

Report: `PASS` or `FAIL` with evidence.
