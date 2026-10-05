# Remaining consumer verification responsibility and source evidence

Specification-only candidate, 2026-10-05. No tests/probes were executed; no
implementation or installed acceptance is claimed. Tests below are required
at delivery using bin/ace-test and bin/ace-test-suite, with independent exact-head
review and the full installed family gates. Preserve 09j execution limitation;
this map never authorizes retrying blocked native/VM/privilege/SSH scenarios.

| Observable criterion | Existing task owner | Required evidence/layer |
| --- | --- | --- |
| xz9.0 SC1–SC6 fixture authority, peers, canonical import, launch integration | xz9.0 consumes 09j | Existing family test-plan.md and installed distinct-user/native fixture; no seeded journal substitution. |
| xz9.0 SC11 canonical result-to-finish | xz9.0 consumes delivered xz9.3 and implemented 9c2 | Real Git CAS/lifecycle race, success and failed zero-artifact result, current independent success review, every scope/effect/inbox refusal, atomic receipt/terminal/reply; installed positive finish. |
| xz9.0 SC12 exact recover | xz9.0 | Coordinator unit plans and real protected journal integration: lost cache, siblings unchanged, dead child/live descendant, seal without proof, corrupt checkpoint/chain, changed peer birth, stale attempt-local authority_generation (sibling mutations must not advance it; candidate/claim/scope generations are not substitutes), replay before/after terminal/cache loss, crash before/after CAS. No observed PID absence may release. |
| xz9.0 SC13 bind/reconcile inbox | xz9.0 | Real Herdr event lock/key/signature and canonical qjl: strict two-part bounds/order/EOF, wrong role/context/key/registration, worker actor mismatch, bind-vs-seal race, proof accepted by Herdr before qjl crash, exact proof repair, changed claim/replaced native target, corruption of receipt/signature/descriptor/chain independently in fetch/recovery/finish/stop/replay, no receipt_ref fallback. |
| xz9.0 SC14 full startup/routing | xz9.0 consumes 9c2 | Composition tests remove each required operation individually; require service_authorization, settlement and scope capabilities. Protected client/driver cannot choose local fallback; fixed Inbox context startup/config/ancestry refusal. Installed services command and actual public consumers, not construction mocks alone. |
| Scope local-writer closure, release/reuse and sealed service truth | 9c2 consumes 09j | Its existing whole-spec/native/OS acceptance, sealed-service-settlement-contract.md scenarios and positive manager-incarnation proof. xz9.0/.2 consumer integration does not duplicate its handlers. |
| xz9.2 SC1 prompt | xz9.2 | Resolve exact protocol/ack/body framing first; then bounded native submission, blocked/busy no-send proof, fixed target/server incarnation, issuance/CAS/lost reply, no raw durable text, no resend, installed distinct-user flow. Current desired API is not approved native capability. |
| xz9.2 SC2–SC4 stop and consumer | xz9.2 consumes 9c2/xz9.0 | Seal/first-running/later-proof, original replay remains uncertain, local closure plus remote pending effect/inbox, concurrency with finish/recover, changed slot/boot/manager/native identity, stopped terminal CAS/release-before-reuse, qk0 public API integration and installed flow. |

## Read-only source evidence

- AuthorityComposition REQUIRED_ENDCAP/build checks all declared Endcap operations;
  current Endcap::OPERATIONS lacks finish/recover/bind_inbox/reconcile_inbox and
  complete_no_effect. Preserve refusal, integrate 9c2 capabilities at delivery.
- Router uses source-owned handlers/transfer metadata, Server authenticates roles
  launcher/worker/reviewer/executor/supervisor; there is no signer enum. Deployment
  owns supervisor_uids/peer_credentials. Signature provenance remains Herdr's
  pinned receipt key, not a new transport identity.
- AttemptCoordinator finish, recovery_snapshot, resume, bind_inbox,
  reconcile_inbox, recovery_inboxes and AttemptReconciler own local semantics.
  resume iterates assignment-wide and can transition/release: protected exact
  recovery must scope its plan, never invoke this whole mutation implicitly.
- bind_inbox obtains canonical registration from Inbox.status. reconcile_inbox
  passes expected_registration and exact signed bytes/signature to Inbox.reconcile;
  current local receipt_ref cannot be protected truth. CanonicalEvidence and
  EvidenceJournal/JournalMutation supply the single protected import/CAS owner.
- Herdr Inbox.reconcile holds event lock, checks signed-byte equality, pinned key,
  claim/native binding and consumed/superseded attestation; exact accepted replay
  is retained. Recovery must preserve that mechanism across its separate qjl CAS.
- ProtectedNativeControl has pinned native request/create/observe/terminate but no
  typed prompt. HerdrExecutor agent_prompt and RuntimeAdapter send are CLI/local
  source evidence, not protected protocol acknowledgement evidence.
- 9c2 scope-owner-proposal.md supplies exact observe/close schema, two-phase seal
  and proof, original replay, manager restart and release-before-reuse; approved
  whole-spec verdict is retained in whole-spec-readiness-review.md. Its sealed
  settlement contract owns unclaimed request recovery/complete_no_effect/final
  seal-aware authorization. Source/installed delivery remains incomplete.

No success criteria or dependencies have been removed. All observable work maps
to an existing real task; the native prompt question stays in xz9.2. Historical
independent approvals/requests remain evidence of their exact reviewed scope,
not new whole-consumer readiness or source delivery verdicts.
