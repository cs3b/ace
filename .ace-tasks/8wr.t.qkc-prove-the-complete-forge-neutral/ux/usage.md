# Acceptance matrix — usage contract

## Run deterministic verification
`ace-test ace-git-worktree all`
`ace-test ace-review all`
`ace-test ace-task all`
`ace-test ace-assign all`
`ace-test-suite`
Expected: actual stored test reports and exact tested SHA; these supplement rather than replace real-provider success rows.

## Accept a complete row
Input: named Forgejo draft/create/review/merge scenario on a disposable scoped repository with expected/actual state, exact command/artifacts, qjl attempt, tests and reviewer.
Output: passed row bound to exact versions/head and provider identity, available to l2d.8 receipt verification.

## Reject missing or inconsistent evidence
Input: unavailable second Forgejo server, skipped required row, conflicting head, or only exit code 0.
Output: incomplete matrix with exact blocker; no fallback to default endpoint, no partial acceptance and no full-Lab-ready claim.
