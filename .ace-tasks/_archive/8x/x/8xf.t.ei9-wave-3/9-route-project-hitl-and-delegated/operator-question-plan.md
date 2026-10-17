# Truthful host operator questions — grounded implementation plan

Base: release assembly `33bf2efe5`; source-only work in `codex/ei9-operator-questions`.

## Existing contracts and gap

`Lifecycle::Store#create/prepare_request` requires real Assign assignment/attempt
IDs and a live Binding. `ManagedEnvelope` requires the same IDs; Hermes validates
it when publishing and correlating requests. The domain host ask surface has no
such execution. Synthetic IDs or an unverified managed binding would be false.

The existing Store already owns request locks, atomic request/public/terminal
files, stable request IDs, role gates, pending pagination, authenticated Unix
frames, answer delivery and consume/cancel recovery. Reuse these mechanisms.
Hermes already has project-qualified routes and exact Reply correlation.

## Explicit current contract

- Add a closed `OperatorEnvelope` with its own schema tag and literal
  `operator-question` context; fixed nonsecret `question` kind, request/incarnation,
  project, kernel-derived requester/UID, correlation and nonsecret input digests.
  It cannot contain assignment, attempt, reverse, OTP, effect or publication grants.
- Add a closed `RequestEnvelope` union selecting only the existing managed schema
  or this operator schema. Managed validation stays unchanged. Generic HITL owns
  operator authority; the contract validator proves structure only.
- Add public `operator_question` creation through the existing Unix frame/API,
  with strict arguments and stable-ID retry after lost response, restart or
  terminal consumption. Changed content/principal/project/context fails closed.
  Existing read/pending/deliver/consume/cancel use the same Store files and locks.
- Admission requires an explicit root-installed `hitl.operator_uids` grant plus
  an exact project in that UID's authorization principal. Empty project lists
  do not grant all operator projects. Record the actual kernel identity; caller
  payloads cannot supply it. Recheck original requester grant and exact UID at
  reads, transitions, retries and terminal replay; transport must independently
  retain its own project grant. Revocation preserves unresolved files/history.
- Operator questions never run effects or become native execution claims. They
  reject secret-shaped question/answer content and cannot authorize proposals,
  managed merge/publication, OTP, or silence decisions.
- Provide an explicit operator-only public serve mode whose binding refuses all
  managed execution requests; no Assign journal or fake attempt is introduced.
  Expose supported request contexts through authenticated endpoint health and
  allow transport configuration to require operator capability at startup.
- Hermes consumes the tagged envelope union and uses operator incarnation as its
  immutable transport revision. Route/project/Captain fingerprint and first-body
  durability remain unchanged. Domain deployment and legacy-history handoff are
  separate work, with no migration or production changes in this implementation.

## Verification map

1. Contract tests: valid variants; closed fields; malformed/secret/effect/OTP and
   mismatched expected project/principal refused; managed examples unchanged.
2. Store/policy tests: exact explicit UID/project admission; stable retries;
   changed payload/context refused; request/answer/terminal restart; revocation
   before delivery/read/consume/replay preserves history; managed binding fails
   in operator-only mode. Tests do not claim distinct identities when one Unix
   UID intentionally holds both roles.
3. Public real Unix client/server tests: kernel-derived requester attribution,
   create/read/pending/deliver/consume and restart, strict frame operations.
4. Hermes integration: two operator project authorities with identical request
   IDs, exact Reply, first-body durability and restart; missing startup capability
   refuses activation. Existing managed/OTP/proposal regressions continue passing.
5. Execute appropriate `bin/ace-test` package tests and retain source/test proof.
   No version bump, deploy, publish or main merge. Independent verdict follows.

A same-UID operator/transport deployment is one OS trust domain; configuration
must select a distinct transport principal wherever Captain isolation is required.
No API can manufacture that isolation. Legacy unresolved host questions/history
remain intact until an explicit domain adoption proves all existing groups.
