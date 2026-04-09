# Goal 1 — Help Survey (Task-Aware Flags) Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Help captures exist** — `help.*`, `create-help.*`, and `list-help.*` are present.
2. **Help commands succeeded** — all three `.exit` files report success.
3. **Task-aware concepts are evidenced** — the combined help captures reference task-related flags or options such as `--task`, `--show-tasks`, `--task-associated`, `--no-task-associated`, or `--delete-branch`.
4. **Subcommand help carries task flags** — at least one of `create-help.stdout` or `list-help.stdout` includes task-aware option text beyond the root help banner.

## Verdict

- **PASS**: The help captures exist, succeed, and expose the expected task-aware worktree help surface.
- **FAIL**: Captures are missing, help fails, or task-aware flags are not evidenced.

Report: `PASS` or `FAIL` with evidence from the help captures.
