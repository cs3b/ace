# TC-003: Observe five quiet minutes

Require zero additional model turns during the unchanged interval, active healthy observation throughout, no duplicate assignments, and the same integrated Forgejo state. If notifications remain pending or state changes, the interval is not evidence of idle acceptance; begin a new bounded interval only after they settle.

Use the actual VM/Forgejo state, then `results/tc/03/state.json` and
`sessions.json`, then the command stdout/stderr/exit captures. Missing, stale or
contradictory evidence is FAIL. Confirm the fixture identity matches setup.
