# Ordinary managed delivery publication — implementation plan

Base: integration2922e2a5b; branch codex/ei9-ordinary-publication. This plan is
recorded before material contract implementation. No publication/deploy/root action.
The nonsecret command source freeze remains unchanged. Taskless secret/publish
requirements remain OPEN under ei9.5; first release uses a REAL ordinary delivery
assignment/attempt and its reviewed candidate.

## Grounded gaps

OrdinaryLifecycle now admits real PreparedWork, native intent/process_start,
progress, attributable results and canonical submit_candidate/assign_review/
accept_review. The ingress and fixed merge proof join are source-verified in
03dfdb1a2 with the missing-command refusal correction d7a0ee934; they are not yet
installed. Ordinary publication must consume that owner rather than recreate it.
Endcap publication still expects a protected LaunchLifecycle origin, Deployment
mapping, protected journal writer and distinct receiver/reviewer roles.
OrdinaryOwnerAdmission currently returns worker/supervisor only. Reusing Endcap with
a fabricated protected origin or changing a result receipt into review is invalid.

Existing service and publication transitions now live in FixedServiceLifecycle
and FixedPublicationLifecycle; protected context remains in Endcap. ServiceEvidence, ServicePublicationEvidence and
EvidenceJournal already own service_claim/service_transition, artifact imports,
OTP challenge/issuing evidence, terminal receipts and uncertain settlement.
ServicePublicationBinding verifies original receiver under same-process owner
exclusion; ordinary composition currently supplies AssignmentBinding alone.

ProtectedServiceReceiver exports a candidate Git bundle and materializes it. Its
publication artifact path is relative to that candidate, so retained separately
built artifacts need a real producer/consumer join, not a pretend external output
flag or mutation of accepted source. Existing publisher --scoped-publication already
accepts exact artifact/digest/gem/version and registry verifier checks exact SHA.

## Smallest observable complete source path

Real prepared delivery registration → actual native worker start → candidate bundle
admission → independent reviewer assignment and canonical accepted review → explicit
artifact manifest authorization and retained artifact admission → fixed receiver
request_service → export exact candidate/artifact → begin_dispatch → registry absent
→ provider OTP-required → existing HITL project correlation/vault → single fresh
publication_continue → provider result → exact registry reconciliation → canonical
publication receipt → ordinary effect settlement. All mutations use the SAME ordinary
Router, journal and lifecycle exclusion; no taskless/fake assignment or second ledger.

## Implementation sequence

1. Extract source-owned fixed service/publication transition modules from Endcap.
   Keep protected admission/launch checks in its boundary adapter. Common code gets
   narrow scope hooks for held journal/attempt, live origin, exact accepted candidate,
   independent accepted review and installed fixed receiver selection. Preserve all
   existing protected checks and evidence semantics; do not generalize deployment
   configuration into a caller-selected object. Journal lower writers call the same
   source-selected service authorizer for ordinary service updates as protected ones.
2. Add ordinary managed candidate/review ingress using existing CandidateTransfer,
   ReceiptTransfer and CanonicalEvidence. Reuse candidate/review transition/receipt
   validation rules via extraction; reserve real ordinary start/runtime proof and
   owner exclusion. Protected request_review launch-control delegation stays unchanged. Ordinary
   supervisor assigns a real independent reviewer, whose authenticated accept_review
   imports the verdict. Public operations use their existing names with source-selected
   handler routes, never a duplicate of ordinary submit_result/finish. A boundary-
   specific ordinary origin reference points to actual intent/process_start digests
   and runtime binding. It NEVER invents launch_ticket/reservation_generation.
   Existing protected origin fields stay protected; immutable service identity
   distinguishes the authentic ordinary origin without weakening replay comparisons.
3. Add installed fixed publication receiver/reviewer principals and credentials to
   ordinary owner selection. Keep participant native proof for workers/supervisors;
   authenticate actual receiver/reviewer peers independently. Selection reload/revoke,
   PID/birth and project remain mandatory on every fresh transition and replay.
4. Retain one exact built gem through existing bounded transfer/canonical artifact
   import with an independently granted manifest (project, accepted head/tree,
   gem/version/platform/registry/SHA256/size). Worker build success cannot authorize
   release. Source-owned admission parses gem metadata and hashes actual bytes;
   rejected/changed manifest or artifact cannot create a service permit. Materialize
   retained gem into receiver-owned immutable staging, separate from accepted code.
5. Reuse the fixed receiver orchestration/publication state machine, extracting the
   common part instead of creating a second publisher. Ordinary public producer uses
   existing OrdinaryClient and fixed listener, with trusted installed mapping and
   actual forwarded worker identity; Python/labd is not involved. Existing
   ServicePublicationBinding wraps real ordinary parent binding and fixed owner.
   Reuse existing publication HITL envelope/OTP vault and Hermes correlation.
6. Add ordinary service/publication settlement to final completion through the
   existing OrdinaryEffectSettlement checks. Uncertain result, lost fresh permit,
   rejected OTP or stale review remains open; no automatic effect redispatch.

## Test responsibilities and boundaries

- Assign feature tests: real prepared registration/start plus real Git/journal CAS,
  candidate/review/artifact imports, claims/challenge/continue/settlement. Native
  runtime/kernel observer is the explicitly controlled outside boundary. No invented
  process_start/accept_review/service_claim events and no admission callback replacing
  rules under test. Concurrent claims, revoke before replay/continue, changed head,
  terminal/dead original parent and journal restart are mandatory.
- Lab composition feature test: public ordinary producer/listener, same actual owner
  Router and shared HITL service/vault; provider/network and native observer only are
  controlled. Exact artifact bytes flow to maintained scoped publisher interface,
  synthetic OTP is project-correlated and absent from diagnostics/journal. Wrong
  project/manifest/artifact, bad/expired OTP, lost ACK and uncertain registry readback
  never become success. No actual registry push.
- Protected regression: execute existing candidate/review/service/publication/HITL
  tests after each extraction so shared core preserves protected admission and
  lower-writer invariants. Focused tests first; no broad suite before coherent freeze.
- Parent root acceptance after freeze: fresh hash-asserted export, real distinct OS
  worker/reviewer/executor/owner principals and installed policy; provider endpoint is
  explicitly synthetic. No production services/journal or RubyGems effects.

## Review readiness

First review decision: agree scope hooks and ordinary origin/artifact contracts
before implementation. Then incremental extracted-core tests, managed source join,
focused regressions and independent review. Entire ei9.5 remains in-progress until
actual installed delivery and taskless secret/publication contracts are proven.

## Sequencing correction and shared ingress interface

Inspection confirmed ordinary merge validates review-reference shape and reviewer
string inequality but does not independently dereference accepted canonical review
evidence. Fixed-merge admission bypasses the generic claim_service review guard.
Therefore actual .0/.8 two-PR merge acceptance depends on ordinary candidate/review
ingress and a canonical merge consumer proof join BEFORE full publication/OTP.
The independent ingress owner implements that first; this .5 service owner consumes
the same hooks and does not duplicate their producer or receipt verifier.

Agreed source-selected owner interface, always at a held current CAS prefix:
- with_scope(assignment:, attempt:, deadline:) yields the original journal and
  registration under existing lifecycle exclusion.
- origin_at!(events:, commit:) verifies actual intent/process_start digests, scope,
  base_head and live native runtime binding; output is authority/project/assignment/
  attempt plus those authentic facts, never a protected launch ticket.
- candidate_at!(events:, commit:, head:, generation:) returns exact admitted
  head/tree/candidate_generation/bundle_ref/sha256/bytes.
- review_at!(events:, commit:, head:, generation:) revalidates independent native
  reviewer assignment, accepted canonical receipt/artifact bytes/checks and producer
  association. Same UID independence needs distinct actual process generation and
  session; protected UID inequality stays unchanged.

Path ownership: ingress owner owns ordinary_candidate_review/ordinary_review_evidence,
ReceiptVerifier independence callback (protected default unchanged), merge proof guard
and public ordinary candidate/review producer. Service owner owns fixed_service_lifecycle,
fixed_publication_lifecycle and endcap_service_context extraction plus later ordinary
service boundary composition. Command cleanup review correction is a separate frozen
branch; publication expansion waits for its owned detached-child acceptance.

## First extraction verification

Common FixedServiceLifecycle/FixedPublicationLifecycle now contain the existing
transition rules. Protected Endcap hooks still delegate to original Deployment,
LaunchLifecycle, protected-journal, active-origin and approved-review checks. No
ordinary service capability is enabled by this extraction. Protected publication/
boundary/composition tests passed24 tests/186 assertions (Lab079d7b55).

Additional existing Assign replay coverage exposed a stale generic fixture labelled
publish without publication dispatch/receiver facts: candidate and unchanged base
both errored23 tests/69 assertions during fixture setup (fbf0452e/dd3bc3ed).
Correcting only that generic fixture and matching assertion to verify-artifact
restored23 tests/249 assertions PASS (fe2d7bf4). Real publication-specific fixtures
remain separate; no service evidence guard was weakened.

Command detached-child review correction subsequently reached frozen47466eb0b.
Root R6 retained both expected inherited-SIGCHLD RED failures and candidate Linux
9 tests/75 assertions PASS, plus public composition40/zero skips PASS. Configured
Pi approved the exact source; root retained that verdict and receipts. This remains
static-source kernel proof, not dynamic candidate/runtime installation acceptance.
Runtime must join the final release cut. Maintained test-runtime profile preparation
is separately blocked by platform review; see its retained blocker, not a replacement
installer or ad hoc per-run graph.

## Native origin composition boundary

The shared fixed service transitions now ask their source-selected boundary for
`service_origin_fields!` and `service_origin_matches!`. The protected Endcap
retains its exact worker process, launch ticket and reservation generation
construction/comparison. No ordinary origin, admission route or capability is
enabled by this extraction. The next ordinary adapter must return its real
canonical intent/start/runtime reference; it must not manufacture protected
launch fields. Existing claim, authorization, pre-dispatch and preview paths
all use the same boundary owner.
