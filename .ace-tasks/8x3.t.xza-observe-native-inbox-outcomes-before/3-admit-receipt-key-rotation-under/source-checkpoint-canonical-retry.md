# Canonical retry and read-only issuer retirement source checkpoint

This successor over 0d2a44520/7278b8e7a is frozen for independent review, not self-approved or merged. Contract readiness is recorded in1fd5b2f1f. Formal review of the earlier candidate failed on provider deadline_exceeded (root-retained invocation WkcH6coO); no approval or silent rerun is inferred.

The fixed context completion owner now writes a closed bounded canonical_completion binding in the SAME DeliveryRecord after its authenticated query and second admission check. Explicit queued/superseded retry requires that exact current receipt/registration/key/claim/native binding and source completion; private signed supersession alone refuses. Every new claim and proof replacement invalidates the marker. Direct entry and the separate claim-preparation transaction both refuse unresolved same-event issuers and outstanding reconciliation admissions. Unrelated events remain independent.

A first stored commit is the authenticated query's observation tip. Exact replay retains that original snapshot while the new fixed query must reverify all immutable receipt/effect/reconciliation/reply bindings; unrelated canonical append does not replace the marker. This preserves existing completion semantics without a new journal, proof shortcut or current-tip equality requirement.

Root review identified a reachable nil-claim defect in the earlier source: genuine accepted direct delivery ends, then a stale read-only invocation returns with no claim and known-idle state; a lost end ACK retains it and strict effectful retirement then blocks canonical confirmation. Actual reproduction28a0de5b-09a4-459d-b0c0-aabb5b7c4643 failed1/4, seed62821,3.84s. Repair permits only source-returned deliver + nil admitted claim + in_flight0 through fixed direct_idle_readback and same exact current canonical retained-record verification. Effectful claims retain exact generation/claim-owner lineage; running or unconfirmed admissions never take this observation branch. Actual repaired1/8 PASS6edab797-16cb-4925-a6ec-0ac8804c0b66,6.21s.

Final executed evidence, under this worktree's .ace-local/test/reports:

- assign/7094ff90-ee34-468e-8da6-6ffe045e2b31: seven specifically selected actual composed methods,7 tests/92 assertions PASS, seed8136,39.56s. Raw method list confirms returned issuer restart/retirement, genuine consumed proof refusing pre-return clearance, post-query foreign reconciliation race/replay, stale read-only nil-claim retirement, private pre-CAS supersession refusal and accepted one-effect explicit retry, marker-save/context-publication fault plus exact replay after unrelated canonical append, and concurrent reconciliation between entry/claim preparation with no native effect. Includes seven malformed/stale marker refusals, old-proof refusal after a new claim, marker invalidation, consumed proof creating no further claim, and byte/ref/effect count assertions.
- herdr/ba55a259-f6f1-4f34-988f-ef645eba757b: existing context-owner/direct-effects files,22 tests/144 assertions PASS, seed784,.283s. Exact older/later/foreign effectful claim negatives remain enforced.
- Prior current successor runs b63f665d2/30 and c768b1115/71 passed before later observation/replay refinements; they are retained but do not replace final proof.

No native/root/systemd/installed/process-identity/external probes ran. Actual sockets, signed receipts, private record store, journal/import CAS and fixed query/confirmation owners executed; excluded native/kernel/provisioning observations are controlled seams. Full selected-entry subprocess/producer composition, maintained context service, explicit original guarded assignment association and dead-launcher pre-return recovery remain required. Canonical superseded replacement-target guard admission remains a separate missing guarded-target join. No family or task success condition is closed here.

## Independent review and integrated verification — 2026-10-08

Root inspected the frozen implementation and failure/race tests. Independent
reviewer `review_lab_bootstrap` approved the protected CLI/context stack after
reviewing `0d2a44520`, `7278b8e7a`, and `52bab7b62`. This does not derive approval
from the failed external provider review. Integration commits are `d5e346be3`,
`9bf82e842`, and `f1a92addc`; the only conflict retained both changelog entries.

On integrated `f1a92addc`, executed from the respective package directories:

- Herdr context-owner/direct-effects files: **22 tests / 144 assertions PASS**,
  no skips, report `345fe8cc-64d8-4646-b7dd-1a2750dae105`, raw seed34739,
  0.264911s (the rendered summary rounded duration to zero).
- Assign `endcap_inboxes_test.rb` selections 418, 450, 500, 533:
  **4 tests / 60 assertions PASS**, report `4e7d6a76-9c79-4124-9c13-e18d41c560ae`.
  These exercise nil-claim retirement, explicit superseded retry, marker-save /
  context-save failure, and reconciliation admission between entry and claim.

### Required source consumer follow-up

The reviewer corrected an initially overbroad caller claim after root and author
identified `ace-hitl/lib/ace/hitl/live_client.rb`: `reconcile` uses a local
coordinator and raw `Inbox#deliver`; construction uses `Inbox.from_config`.
This path does not use protected context admission. Neither this review nor
socket-owner validation establishes exhaustive store/native access confinement.
Therefore the approval above is limited to the protected CLI/context stack.

Protected LiveClient adoption is required source work owned by the current
xza.3/gad.8 integration, not an installed-only gad.2 probe. Preserve the historical
vs2 result. Route supported protected operations through maintained authenticated
owners; prove marker-save/context-failure causes zero native dispatch and exact
canonical replay permits one explicit retry. A permanent refusal of required HITL
delivery is not completion. This source consumer gap and the earlier listed
producer/service/recovery gaps remain open before family/program acceptance.
