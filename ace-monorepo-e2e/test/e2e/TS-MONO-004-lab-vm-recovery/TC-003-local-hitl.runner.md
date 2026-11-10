# TC-003: Local decision lifecycle

Give the Overseer a readiness-report decision requiring the local captain. Let it create the exact HITL case and finish its turn. Answer that case through installed ace-hitl reply --stdin in its owner scope. Redeliver the same answer once. Allow up to ten minutes for the owner's actual wake and the requested
effect. After the owner's turn, capture installed `ace-hitl show CASE --content`
for the exact case and the referenced owner record. The case must contain an
application with `state: closed`, `ref`, `applied_at` and `closed_at`.
Record the exact answer redelivery receipt and compare effect/assignment
state before and after. Do not mark the case applied or closed for the agent.
If the application is absent or remains open at the deadline, record the
unmet condition even if the owner acted on the answer.

Capture `results/tc/03/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
