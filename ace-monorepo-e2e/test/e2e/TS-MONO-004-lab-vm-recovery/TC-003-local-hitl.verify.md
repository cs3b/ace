# TC-003: Local decision lifecycle

Require a real local question, wake on the received answer, one applied effect and owner closure with evidence. Repeated answer produces no repeated work. No Hermes, Telegram or external human service is used.

Use the actual VM/Forgejo state, then `results/tc/03/state.json` and
`sessions.json`, then the command stdout/stderr/exit captures. Missing, stale or
contradictory evidence is FAIL. Confirm the fixture identity matches setup.
