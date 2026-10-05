# Test responsibility map — protected scoped services

All authority/data-integrity behaviors are high risk. Plan only: no implementation tests were run for this spec change.

| Parent criterion | Child | Layer and proof owner |
|---|---|---|
| SC1 protected cross-user effect | xz9.0 | ace-lab/assign integration; real installed launcher/reviewer/worker/authority/executor UID fixture |
| SC2 invalid authority refusal | xz9.0 | ace-assign unit role/binding validation; real filesystem/socket symlink/ref/config/candidate substitution integration |
| SC3 duplicates and loss | xz9.1 | journal CAS/lifecycle integration; actual concurrent CLI and crash-after-effect E2E |
| SC4 listener and descendants | xz9.1 | protected socket ownership integration and real process group timeout/late-write E2E |
| SC5 same-user/Unix behavior | both | existing ace-lab contract suite plus Linux multi-UID and actual macOS peer smoke; independent review |

Unit: immutable fields, authorization reuse, role grants, fixed root mapping and redaction; bounded artifacts/config parsing. Integration: real canonical Git ref/CAS and protected evidence ancestry; do not mock UID/stat/lstat/peer credentials for boundary acceptance. Mock external fixture handler outcome only in unit classification; installed fixture must actually write one harmless protected effect. E2E: terminalization-before-claim, revoke-before-dispatch, worker mutable HEAD after review, all crash windows, same ID conflicting input, second authority/listener startup and noisy/stuck descendant output. Restore current source fixture after each crash; never treat worker cache as authority. Failure evidence includes no effect count and unchanged accepted journal state.

Record source SHA, exact commands, real UIDs, protected roots/ownership, approved candidate/generation/reviewer and qjl receipt digest. `bin/ace-test --help` selects affected package/layer commands at implementation; run `bin/ace-test-suite` default fast suite then installed multi-user scenario. gad.8/gad.b separately prove real installation/domain services; generic fixture does not close them. No broadened retention/16h policy.

## Review repair verification mapping

- xz9.0 SC4: real gated child/launcher crash before record_launch, before/after bind commit and lost response; verify exact PID/birth, no fabricated process_start, no effect from reserved and no premature ownership release.
- xz9.0 SC5: distinct reviewer/executor download verified bundles into own 0700 roots, execute exact candidate; worker/private-root traversal, missing objects, malicious config/hooks/alternates and mutable upload refuse.
- xz9.0 SC6 / xz9.1 SC4: corrupt canonical import blob/provenance on coordinator, journal validation, terminal status/replay, settlement_evidence_intact?, authorization reuse and recovery readers; every path fails closed. Atomic import-before/after Git CAS drills prove accepted artifact state only at commit.
- xz9.1 SC5: older no-effect attestation, forged caller mtime/time and outdated failure challenge refuse; fresh authenticated target/process absence settles once and repeated exact completion is idempotent.
- xz9.1 SC6: begin_dispatch reply loss, restart and lease expiry cannot issue another invocation permission; authenticated late real outcome may settle without dispatch.
- Generic handler fixture validates v1 preserved worker caller_uid/unix transport/staging import. Real lab_setup_project handler migration and usage/tests remain gad.b acceptance; current local-only handler is not a positive fixture.

Every authenticated API role includes wrong-project/wrong-role/unknown mutation ID and exact-versus-conflicting mutation replay integration. Context/inbox consumer tests preserve accepted recovery expected_registration/exact proof replay at event lock and real cross-user byte transfer, not shared receipt paths.

## Composition amendment verification mapping

- xz9.0 SC2 / deployment unit and real filesystem/socket integration: missing or unknown composition refuses; `services` deployment through the launch-only entrypoint and `launch` deployment through the full-service entrypoint refuse before startup. Assert no listener socket, new journal ref or accepted event is created. 09j owns the common Deployment enum and Server entrypoint validation; Lab owns full-service composition completeness.
- xz9.0 SC2 / deployment integration: two authority IDs owning one project, or two configured owners sharing an endpoint, refuse before startup. Assert no additional listener or journal ref is created; an existing valid listener/ref remains unchanged. Real second-start lifetime ownership tests preserve the same outcome.
- xz9.0 SC1 / policy integration: exact fixed qjx grant admits the harmless fixture without a proposal prerequisite. Proposal references require the qjz canonical producer/resolver; absent producer, YAML imitation and prefix-only references refuse before claim/effect. This preserves qjz ownership without adding a reverse or cyclic dependency.
## Receipt-bearing binary framing

`transfer_codec_test.rb` owns real-socket acceptance at the full separate capacities (16 KiB receipt plus sixteen evidence parts totaling 256 KiB), oversized first/evidence parts, excess evidence count/aggregate, EOF/digest/trailing-byte refusal and private spool cleanup. Generic `artifacts` limits remain unchanged. `receipt_transfer_test.rb` owns receipt-first SHA/JSON identity and exact evidence count/order/digests, missing/duplicate receipt framing, duplicate artifact identities and forbidden receipt fields. Fixed Endcap operation bindings select `receipt_artifacts`; Server/Router integration tests must prove peers cannot select another purpose and failed framing produces no journal mutation.

`transfer_codec_test.rb` also owns the fixed one-part/nonempty/64 KiB `service_input` limit. `protected_service_policy_test.rb` uses the actual existing input and policy validators for hostile asserted digest/target, changed body, secret/depth/byte schemas, policy change after claim, revoked visibility, expired lease, proposal-prefix YAML bypass and root/worker executor refusals. Endcap real-journal/socket integration owns recomputation before initial mutation and on every begin CAS retry, including changed policy between claim and invocation, zero handler effects and no input values in canonical records/errors. Deployment startup tests own missing/duplicate/foreign receiver endpoint and unsafe staging refusal before listeners/refs; actual kernel/native distinct-UID acceptance remains the installed proof owner.


### Executor authorization read acceptance

- Endcap real-journal tests: exact recorded executor and original immutable body yield the closed six-field digest projection within 16 KiB; repeated reads leave ref/events/blob count unchanged. Non-null mutation ID, wrong peer/request/claim/head/generation, changed bytes with asserted original digest, target mismatch and forged policy selectors refuse without input values in replies/errors/events/blobs.
- Lab receiver integration: exact fixed qjx grant and canonical qjz proposal use the same installed policy owner; no local proposal journal, YAML/prefix bypass or wire-selected owner. Operation digest mismatch or returned policy digest differing from the canonical claim refuses before handler effect. Changed grant/proposal/lease before the final fresh authorization read refuses. A change after that admission linearization does not retroactively cancel the admitted effect; a subsequent local operation mismatch still refuses. Repeated reads rerun current validation instead of returning cached approval.
- One-shot effect gate: successful read plus retained claim or `already_started` begin produces zero invocations. Fresh successful begin followed by fresh successful read allows exactly one fixture invocation. Lost begin/read reply or a refusal after begin produces zero receiver invocations and retained uncertainty; no automatic re-begin or false no-effect settlement.
- Completion regression: late exact outcome remains recordable after visibility revocation, lease expiry and terminalization without this authorization read. Original mutation replay metadata remains distinct from current state generation.
- Installed proof retains actual mapped executor/worker distinct-UID and protected native origin prerequisites; isolated unit success cannot stand in for these gates.

Protected service status uses JournalMutation's same generation projection under owner exclusion. Claim → another Endcap mutation → status → begin tests current generation, stale refusal and unchanged original replay acceptance metadata. Status never refreshes an authorization, advances ref or returns invocation permission.
