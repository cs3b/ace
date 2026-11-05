# TC-002: Delegate the four Forgejo issues

Give the ready project Overseer the issue URLs from the fixture receipt and one goal: order and deliver the base, dependent CLI and documentation issues with independent review and integration on main, leaving release queued. Do not suggest its next steps or choose workers. Allow up to 90 minutes. Read actual Forgejo and task/assignment state through their installed public interfaces.

The fixture receipt is private runner input, not a source for the tested agent.
Include the actual issue URLs in the goal. Do not tell the Overseer to search
for fixture receipts or expose host paths; issue content comes from Forgejo.
Do not include auth commands, task decomposition, role choices or execution
steps in the goal. Those must come from the installed product contracts.

Capture `results/tc/02/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
