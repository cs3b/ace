# TC-003: Local decision lifecycle

Give the Overseer a readiness-report decision requiring the local captain. Let it create the exact HITL case and finish its turn. Answer that case through installed ace-hitl reply --stdin in its owner scope. Redeliver the same answer once. Allow up to ten minutes for the owner's actual wake and the requested
effect. Capture the case after the owner records the effect and closes it.
Record the exact answer redelivery receipt and compare effect/assignment
state before and after. Do not mark the case applied or closed for the agent.
If the case is still answered without an effect at the deadline, record
that unmet condition.

Capture `results/tc/03/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
