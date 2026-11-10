# TC-002: Delegate the four Forgejo issues

Give the ready project Overseer the issue URLs from the fixture receipt and one goal: order and deliver the base, dependent CLI and documentation issues with independent review and integration on main, leaving the release issue open and queued after all three merges. Capture the exact goal text before submitting it. Do not suggest its next steps or choose workers. Allow up to 180 minutes. Read actual Forgejo and task/assignment state through their installed public interfaces.

The fixture receipt is private runner input, not a source for the tested agent.
Include the actual issue URLs in the goal. Do not tell the Overseer to search
for fixture receipts or expose host paths; issue content comes from Forgejo.
Do not include auth commands, task decomposition, role choices or execution
steps in the goal. Those must come from the installed product contracts.

Capture the goal's delivered timestamp from the project Overseer's session
and the actual merge timestamp for each required PR from Forgejo. If any
required merge is missing at the 180-minute deadline, capture the failed
prerequisite and do not run TC-003. Subsequent merges are diagnostic evidence.

After the delivery, verify the integrated behavior from a separate temporary
checkout of the local Forgejo `main` ref, under the fixture operator's test
authority. If anonymous Git access is refused, read the fixture's actual
bare Forgejo repository as the forge service account through the documented
operator helper. Clone only its `main` branch. Record the bare ref SHA and
the checkout HEAD and require them to match. Run the fixture CLI as the
unprivileged guest user from that checkout. Capture a valid sequence of
increments and an invalid increment, including actual stdout and exit codes.
Remove the temporary checkout. Do not change the project's checkout, merge
anything or reuse a worker worktree for this check.

Capture `results/tc/02/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
