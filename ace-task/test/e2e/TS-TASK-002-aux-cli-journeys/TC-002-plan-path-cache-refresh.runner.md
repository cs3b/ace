# Goal 2 - Plan Path Cache Refresh

## Goal

Validate the public `ace-task plan` path-mode invocation contract in sandbox
environments where planning dependencies may be unavailable.

## Workspace

Save all artifacts to `results/tc/02/`.

When a plan command succeeds and prints a path, copy that referenced plan file
into `results/tc/02/` as:
- `plan-path-initial.plan.md`
- `plan-path-refresh.plan.md`

## Constraints

- Use only `ace-task ...` commands.
- Prefer path output mode (`ace-task plan <ref>`) for verification.
- Use `--timeout 30` on plan-generation invocations so the public CLI surfaces actionable timeout diagnostics instead of hanging indefinitely in sandbox runs.
- Capture stdout/stderr/exit for each command.
- Do not wrap `ace-task plan` with `timeout` or other shell wrappers; rely on the E2E harness timeout instead so real diagnostics can surface.
- Do not rely on inline `--content` output.

## Steps

1. Run `ace-task create "E2E plan path task" --status pending` and save `create.*`.
2. Resolve the created task ref from command output.
3. Run `ace-task show <ref> --path` and save `show-path.*` to identify the exact task file path.
4. Run `ace-task plan <ref> --timeout 30` and save `plan-path-initial.*`. If it exits `0` and stdout contains a path, copy that plan file to `plan-path-initial.plan.md`.
5. Run `ace-task plan <ref> --refresh --timeout 30` and save `plan-path-refresh.*`. If it exits `0` and stdout contains a path, copy that plan file to `plan-path-refresh.plan.md`.
6. If either command exits non-zero, keep stderr artifacts as primary evidence and do not fabricate copied plan files.
