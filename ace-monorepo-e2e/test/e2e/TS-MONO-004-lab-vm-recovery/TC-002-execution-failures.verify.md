# TC-002: Worker interruption and unavailable observation/runtime

Require an explicit failed/blocked or owner-authorized retry state after worker interruption, no false done and no unaccounted duplicate assignment. Unavailable observation blocks new dispatch. Missing installed runtime refuses launch without source/bundle fallback. Each fault has its own before/after evidence and restoration; do not count one failure as proving all three.

Use the actual VM/Forgejo state, then `results/tc/02/state.json` and
`sessions.json`, then the command stdout/stderr/exit captures. Missing, stale or
contradictory evidence is FAIL. Confirm the fixture identity matches setup.
