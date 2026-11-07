# TC-001: Redelivery and coordinator restart

Find an accepted bootstrap report through the private manager and identify
its original assignment, execution worktree and prepared coworker config.
Before restart, repeat publication from that worktree through the installed
`ace-coworker report --config <prepared-config> --assignment <original-id>`.
This fixture uses local `observe` delivery. Record the command result and
verify through HITL that it reused the same event ID and outcome. Capture
the private step, assignments and session identities before and after.
Do not create a replacement event or configure a transport adapter.

Restart only the lab Overseer session through the documented native/systemd
lifecycle and public start. Preserve the old session evidence before stopping
it. Capture the new session's completed first turn, healthy eyes and the
unchanged accepted report and assignment state. Do not reset the VM or
recreate completed work.

Capture `results/tc/01/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
