# Goal 1 — Saved-Report Remediation Path

## Goal

Execute the public remediation path end-to-end:
1. `ace-git-secrets scan`
2. `ace-git-secrets revoke --scan-file <saved-report>`
3. `ace-git-secrets rewrite-history --dry-run --scan-file <saved-report>`

Use the report persisted by `scan` as the shared contract for revoke and rewrite.

## Workspace

Save all output to `results/tc/01/`. Capture:
- `results/tc/01/scan.stdout`, `.stderr`, `.exit`
- `results/tc/01/saved-report.path`
- `results/tc/01/saved-report.json`
- `results/tc/01/revoke.stdout`, `.stderr`, `.exit`
- `results/tc/01/before-head.txt` and `results/tc/01/after-head.txt`
- `results/tc/01/rewrite-dry-run.stdout`, `.stderr`, `.exit`

## Constraints

- Resolve the saved report path from real scan output or `.ace-local/git-secrets/sessions/`.
- Use that exact path for both revoke and rewrite dry-run `--scan-file` commands.
- Record HEAD before and after rewrite dry-run and preserve invariance evidence.
- All artifacts must come from real tool execution, not fabricated.
