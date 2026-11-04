# TC-001: Redelivery and coordinator restart

Require the same accepted work and report identity after reconciliation, no second worker for completed work, no repeated integration, active healthy eyes and real first-turn evidence for the new session. An ambiguous owner or lost report must block visibly rather than duplicate work.

Use the actual VM/Forgejo state, then `results/tc/01/state.json` and
`sessions.json`, then the command stdout/stderr/exit captures. Missing, stale or
contradictory evidence is FAIL. Confirm the fixture identity matches setup.
