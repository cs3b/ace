# TC-003: Local decision lifecycle

Give the Overseer a readiness-report decision requiring the local captain. Let it create the exact HITL case and finish its turn. Answer that case through installed ace-hitl reply --stdin in its owner scope. Redeliver the same answer once. Do not mark the case applied/closed on the agent behalf.

Capture `results/tc/03/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
