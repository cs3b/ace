# Canonical observation source checkpoint — 2026-10-08

Scoped source work in `/tmp/ace-canonical-observation-routes`, based on integration
9915a901a plus parent private-correlation producer 8e4488183 (local e64ce5c05).
No task status or success criteria are completed here.

The production authority now exposes bounded import_observation/fetch_observation
through its existing Client, transfer server, Endcap and canonical journal.
Dedicated authenticated observer/signer credentials and static runtime bindings
are validated at deployment. The issuer independently reads the protected owner
snapshot, including persisted Codex submission/receipt correlation, validates
completed-turn semantics and exact native process identity, and stores canonical
observation bytes. Fetch verifies descriptor, provenance, current registration
and trust; historical claims are ineligible for current signing. Identical
imports retain the evidence ID; conflicting positives refuse replacement.
Configured signers also use the existing inbox reconciliation/evidence routes,
with exact proof replay rather than a new recovery protocol.

Executed deterministic checks:

- Focused journal/context/deployment source tests: 4 tests, 44 assertions, pass
  in 23.49s; report 455ef5fb-82fd-484a-99c1-0218a4d98a88.
- Canonical evidence and protected participant classification: 12 tests,
  77 assertions, pass; report 61d94ed9-60eb-4c0c-bdc9-d89fae3a6293.
- Existing transfer codec/server with observer upload and signer fetch byteflow:
  22 tests, 142 assertions, pass; report 1e03c9c2-8e87-42f9-845c-5f44a1248ba3.
- git diff --check passed.

The first broad legacy inbox/deployment file run was interrupted after about
1m58s (exit 143), not passed. Existing fixture helpers were extracted unchanged
into maintained support modules to permit bounded route checks. Their native
adapter seam explicitly returns nil from prepare_submission. These controlled
socket/journal fixtures are source tests, never installed native evidence.

Parent owns public observer producer/CLI; the signer agent owns protected key
loading, canonical fetch validation and public settle. Lab deployment must supply
project observer_uids/signer_uids plus complete peer_credentials, context role
lists/runtime_bindings and protected signer key reference, with matching service
visibility. Actual protected installed provenance, startup/ACL decisions,
operator/runtime installation, Pi and supersession remain open. No native/model,
root or publication action ran in this source slice. One combined independent
review remains pending.
