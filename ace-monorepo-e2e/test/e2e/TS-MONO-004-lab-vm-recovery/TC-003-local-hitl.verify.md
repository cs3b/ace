# TC-003: Local decision lifecycle

Require a real local question, wake on the received answer, one applied effect and owner closure with evidence. Repeated answer produces no repeated work. No Hermes, Telegram or external human service is used.

Check the final canonical case for `application.state: closed`, the effect
owner reference, and both application and closure timestamps. Correlate the
reference to the actual owner record and the Overseer's turn. Fail if closure
is absent even when the owner applied the effect, acknowledged its wake or
continued to later work. `answered` records receipt of an answer.

Use the actual VM/Forgejo state, then `results/tc/03/state.json` and
`sessions.json`, then the command stdout/stderr/exit captures. Missing, stale or
contradictory evidence is FAIL. Confirm the fixture identity matches setup.
