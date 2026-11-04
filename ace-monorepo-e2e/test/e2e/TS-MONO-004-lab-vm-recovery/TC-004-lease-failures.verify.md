# TC-004: Lease expiry and singleton issuer crash

Require actual Forgejo access before revocation and rejection afterwards, terminated command processes, unchanged unrelated session isolation, and terminal LeaseStore cleanup. An unconfirmed remote revoke remains blocked. Verify request and exec use the same issuer invocation until the injected crash; post-crash recovery reconciles old leases before accepting new ones. Token values must not occur in argv, prompts or reports. Component-only synthetic-provider probes cannot substitute for this case.

Use the actual VM/Forgejo state, then `results/tc/04/state.json` and
`sessions.json`, then the command stdout/stderr/exit captures. Missing, stale or
contradictory evidence is FAIL. Confirm the fixture identity matches setup.
