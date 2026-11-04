# TC-002: Delegate the four Forgejo issues

Require executable fixture tests on each actual candidate HEAD, independent review bound to that HEAD, and actual merged commits on local Forgejo main. The dependent CLI merge follows the base merge; documentation may integrate independently. Verify counter behavior from the integrated main checkout, not a worker branch. Release issue remains open and no release/package was published. Reviewer and author are distinct; integrator has the configured role.

Use the actual VM/Forgejo state, then `results/tc/02/state.json` and
`sessions.json`, then the command stdout/stderr/exit captures. Missing, stale or
contradictory evidence is FAIL. Confirm the fixture identity matches setup.
