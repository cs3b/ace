# TC-001: Commission ACE preparation

Require actual separate worker and verifier sessions, assignment-linked reports accepted by the private manager, a completed first project turn and healthy active eyes. Confirm session tool actions show delegation rather than lab Overseer installation, configuration edits or implementation diagnosis. A launch acknowledgement, a model claim or a task status alone is insufficient.

Use the actual VM/Forgejo state, then `results/tc/01/state.json` and
`sessions.json`, then the command stdout/stderr/exit captures. Missing, stale or
contradictory evidence is FAIL. Confirm the fixture identity matches setup.

Verify the manager's actual path is under `/lab/.ace-tasks/_overseer/`,
Git ignores that path, and the private task listing contains it. A public
manager with a coordination title or tag is FAIL, even if reports were
accepted. Verify exactly three direct children and actual dependency fields:
verification depends on preparation, and confirm-start depends on verification.
Require session-bound `ready=true` after the project's first completed turn;
terminal text claiming healthy eyes does not replace this result.
Require the actual `results/tc/01/bootstrap-timing.json` output from
`lab-vm-bootstrap-timing` for this VM and Lab Overseer terminal. Match the
project terminal to the native first-turn evidence. Only `within_limit`
can pass. Missing helper evidence fails this case.
Check elapsed time from the delivered goal in the Lab Overseer's Pi session
to that session's first successful reconcile result bound to the native session. Use the
recorded timestamps. Missing timestamps, readiness preceding the goal, or
readiness later than 45 minutes after delivery fail this case, regardless
of a runner's deadline flag.
Confirm the prepared project uses local folder HITL and no Hermes/Telegram
route or eyes sync route. Configuring an external transport exceeds this
fixture's bootstrap scope.
