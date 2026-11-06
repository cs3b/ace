# TC-002: Delegate the four Forgejo issues

Require executable fixture tests on each actual candidate HEAD, independent review bound to that HEAD, and actual merged commits on local Forgejo main. The dependent CLI merge follows the base merge; documentation may integrate independently. Verify counter behavior from the integrated main checkout, not a worker branch. Release issue remains open and no release/package was published. Reviewer and author are distinct; integrator has the configured role.

Use the actual VM/Forgejo state, then `results/tc/02/state.json` and
`sessions.json`, then the command stdout/stderr/exit captures. Missing, stale or
contradictory evidence is FAIL. Confirm the fixture identity matches setup.

For each PR, verify full review rounds cover the complete forge PR delta at the
recorded candidate HEAD, including committed task/coordination records. A range
based on a local main containing unpublished commits may omit PR changes: compare
its base and selected files against the actual forge target/merge-base. Reject
partial worker-only review presented as a full round, even if HEAD matches.

Require a merged Forgejo PR for each of the base, CLI and documentation issues.
Check that the configured reviewer approved each exact tested candidate and the
configured integrator merged it. A direct update of main without the matching
merged PR and effective approval fails this case.
