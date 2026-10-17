# No-effect producer source contract — normative clarification

Implements the independently approved plan for existing xz9.1SC5 and sealed service settlement. Root and n0n approved the generic authority challenge/import/reader direction; source implementation and frozen review remain required. Domain fresh inspection is not delivered by this clarification.

## Atomic ingress and authority ownership

ProtectedServiceReceiver submits to the fixed executor's request_service; accepted canonical request and executor claim/ticket are atomic. No accepted requested-but-unclaimed protected record exists. Missing request refuses missing; local-mode or unverifiable ticket records refuse evidence_unavailable. No new request, invocation, ledger or recovery controller is introduced. Original issued/dispatch_started identity and phase survive seal, lease/policy revocation, worker death and current candidate advance.

claim_service_settlement uses the exact accepted sealed contract params and fixed recorded executor. Every CAS retry authenticates original project/map/assignment/attempt/request/head/candidate, seal and canonical request provenance. Succeeded/failed-settled reauthenticates and returns no challenge without reopening. Exact mutation replay retains original projection/generation/commit; a later genuine failure requires fresh mutation/challenge.

## Acyclic selected challenge

The owner creates a unique32lowercasehex token and a service_no_effect_challenge event. Its closed payload is `{version,request_id,input_digest,claim_binding,dispatch_ticket_id,no_effect_challenge,challenge_generation,failure_event_digest,failure_generation}`. Version is Integer1; both generations are positive Integers, never JSON floats/bools. Request/input/claim/ticket are exact original canonical identity. Failure selector names the latest authentic uncertain/failed service outcome and the canonical authority generation at that outcome. Challenge_generation is its issuing authority mutation generation. The source fixes recorded_at once and constructs its exact chained digest before the subsequent record update; the challenge event never hashes that replacement record. The record stores the existing3field selector `{no_effect_challenge,challenge_generation,challenge_event_digest}`. Challenge disposition is distinct from a new failure, so a challenge update does not invalidate itself.

A shared ServiceEvidence authenticator validates the one original challenge event, exact failure/event generation, current selector, whole canonical chain/provenance and absence of a later actual failure. Initial pending imports use the same owner and exact held CAS prefix; retained/coordinator/status/authorization-reuse readers reauthenticate original accepted evidence. Any presence of a retained selector field (including null) requires strict complete selector authentication. Settlement/status authenticate the original accepted selector even after a later failure; fresh no-effect completion additionally requires the latest failure. Missing/partial/orphan selectors remain unavailable, never actionable pending. No persistent cache or caller-selected alternative journal/key/path. A generic terminal update cannot mint a challenge or rewrite an immutable claim.

## Exact fresh inspection artifact

The existing attestation line remains mandatory. The bounded artifact additionally contains exactly one line prefixed `ace-service-no-effect ` followed by a compact UTF8 JSON object with exactly:

`version,request_id,input_digest,claim_binding,no_effect_challenge,challenge_generation,challenge_event_digest,failure_event_digest,failure_generation,target,dispatch_phase,effect_absent,handler_terminated,writers_absent`.

Version is Integer1; generations are positive Integers. Request/input/claim/challenge/failure fields exactly match the authenticated original selection. Target and dispatch_phase exactly equal the original canonical record. The three inspection results must each be literal true, not numeric/string substitutes. Duplicate keys, invalid UTF8, missing/extra fields, extra prefixed lines or trailing JSON content refuse. The artifact obeys existing transfer/import byte bounds. No caller timestamp or filesystem mtime grants freshness.

These are attributable reports from the authenticated fixed recorded executor's imported bytes, not facts the generic authority independently observes. Actual fresh target absence, handler termination and no surviving effect writers must be produced by the domain-selected inspection owner under gad.b. Current ProtectedServiceHandler only has ordinary operation execution; its inspection producer remains an explicit prerequisite for full recovery/installed acceptance. Generic tests may inject that named external inspection boundary, never a verification callback returning true or a claimed native proof.

## Atomic completion

complete_no_effect uses exact sealed contract framing/receipt_artifacts, original executor/claim and source-owned current-generation CAS only for this named operation. The selected challenge/failure is revalidated before import and on every retry. Imported bytes are admitted strictly after the exact accepted challenge event. Existing CanonicalEvidence/ServiceEvidence/journal terminal receipt validation remains the owner; successful verified completion atomically reaches failed-settled and retains its imported refs. Exact receipt/artifact/challenge replay returns the same acceptance, never a second effect. Success/no-effect contradiction or changed retained content conflicts. Corrupt/missing proof remains unavailable, not a typed pending or successful cancellation.

Fresh effect routes retain seal checks; settlement/challenge never grants begin_dispatch or final authorization. Scope closure, timeout, receiver/worker absence and canonical phase absence alone cannot establish no effect.

## Source checklist

- [ ] Actual challenge API, original executor/lineage admission and exact CAS/replay.
- [ ] Shared challenge/fresh inspection/import-order authenticator on every maintained reader.
- [ ] Actual complete_no_effect atomic import/transition, contradiction and lost reply behavior.
- [ ] Genuine controlled Authority/Server/real Git producer-to-consumer tests; separate domain inspection prerequisite identified.
- [ ] Independent frozen source review and integration; xz9.1 remains in progress.
- [ ] gad.b actual domain fresh inspection producer and gad.2 installed evidence (outside this checkpoint).
