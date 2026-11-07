# TC-002: Worker interruption and unavailable observation/runtime

Require an explicit failed/blocked or owner-authorized retry state after worker interruption, no false done and no unaccounted duplicate assignment. Unavailable observation blocks new dispatch. Missing installed runtime refuses launch without source/bundle fallback. Each fault has its own before/after evidence and restoration; do not count one failure as proving all three.

For interruption, require the owner to respond within ten minutes of the
stop and without another user goal. An unchanged paused assignment or a
retry after an unrelated prompt does not establish recovery on wake. For
the source fault, require evidence of the owner's dispatch refusal while
the source is degraded. For the runtime fault, require the installed public
start failure and unchanged native session inventory while the executable
is unavailable.

Use the actual VM/Forgejo state, then `results/tc/02/state.json` and
`sessions.json`, then the command stdout/stderr/exit captures. Missing, stale or
contradictory evidence is FAIL. Confirm the fixture identity matches setup.
