# Protected campaign technical closure proposal — 2026-10-05

This proposal supersedes the two alternatives in `protected-campaign-readiness-inputs.md`
and the source API/lock shorthand in `protected-campaign-contract.md`. It selects
existing succeeded managed campaign-free execution attempts and separates report
model from reviewer actor. It is specification only, pending independent review.
No public interface below is claimed installed.

## Managed execution attempts and exact linkage

Collection, check and independent approval run as separate managed child
**assignments**, each with its existing `Assignment.parent` equal to the parent
assignment ID, same project and task ID, and one ordinary protected attempt.
They are not nested scopes inside the parent's active assignment: LaunchLifecycle
rejects overlapping scopes in one assignment (`reserve` lines 370–375).
Each child uses scope `execution`, ordinary origin/gated process binding and its
own authority generation. Lifecycle locks are acquired for the same task and
both relevant assignments in the existing sorted multi-key order. The parent
remains active while child attempts run; parent terminalization requires all
registered child attempts settled. No child can mutate parent candidate code.
They execute against separately verified private materializations of the exact
canonical snapshot, not the live parent worktree.

Extend the existing launcher-registered managed definition with one optional,
closed `campaign_execution` object. It is forbidden on the parent definition and
for worker-selected registration. The authenticated launcher registers it before
child reservation, and the authority independently validates it against the
parent's current campaign/candidate binding. Existing definition_digest protects
it; definitions of active assignments remain immutable.

```json
{
  "version": 1,
  "parent_assignment_id": "assignment-parent",
  "parent_attempt_id": "attempt-parent",
  "parent_scope": "delivery.review",
  "parent_candidate_generation": 4,
  "subject": {"repository": "https://forge.example/team/repo", "pr": "team/repo#7"},
  "campaign_id": "campaign-id",
  "contract_identity": "<sha256>",
  "policy_digest": "<sha256>",
  "round_id": "round-id",
  "phase": "collection",
  "review_scope": "full",
  "scope_identity_digest": "<sha256>",
  "head": "<exact Git SHA>",
  "base": "<exact Git SHA>",
  "operation": "review-collect",
  "check_name": "review-execution"
}
```

Every shown field is required, no others. IDs use existing CampaignContract/Assign
ID rules; digests are lowercase 64 hex; parent_candidate_generation is a
nonnegative Integer; subject is the existing normalized CampaignContract subject;
head/base use its exact SHA validator; phase is exactly `collection`, `check` or
`approval`. `review_scope` must be in the pinned required scopes and its
scope_identity_digest equals CampaignContract.digest of that exact pinned scope
identity. Collection is one child per round/scope; check is one per required
check name per round (scope remains the registered selected scope); approval is
one child per completed round, whose registered scope selects its full required
scope set through the existing round binding. Approval's report set must cover
all scopes, irrespective of that selector.

Phase/operation/check equality is closed:

| Phase | operation | check_name | Evidence read kind |
|---|---|---|---|
| collection | review-collect | review-execution | review-collection |
| check | test when name is tests; otherwise exact required check name | exact policy required check name | check |
| approval | review | review-approval | review-approval |

The check_name `review-approval` identifies the phase; it does not replace the
independent verdict with a synthetic passed check. Existing ReceiptVerifier
succeeded requirements still need at least one actual executed passed check;
approval supplies its actual executed report-validation check. Required campaign
checks are provided by the separate check children, never double-counted from
that report-validation check. External-effect operations cannot be check phases.
All child receipts require `campaign == nil`. Binding is the existing immutable
registered definition/origin plus receipt attempt/assignment/project/scope/head;
no second receipt dialect or unsigned binding extension is necessary. Source
validation compares child receipt operation to campaign_execution.operation.

The launcher allocates one child definition per exact phase/round/scope/check.
Its existing canonical register_assignment mutation stores that definition blob
and digest, including parent and campaign_execution. That single registration is
the canonical child-to-parent linkage; no separate parent array/index, event
journal or cross-assignment atomic write is introduced. R1's existing session,
check and approval accepted receipt references identify the exact child attempt;
the protected evidence owner resolves its definition and compares every linkage
field to the expected parent tuple. Existing origin binds definition generation
and the child attempt. A worker cannot alter or select the definition. Exact
registration replay reuses IDs; changed active definition bytes conflict. A
failed child is retained and never counted; retry uses a new child attempt against
the same immutable definition, with its exact accepted attempt/digest reference.
No sibling or same-SHA different-generation receipt can satisfy the parent. The
source-owned composition checks registered children with that parent before
parent terminalization; no caller-provided list can hide an active child.

## Protected producers, independent review and terminal flow

The child worker is a real separately gated process under the parent's mapped
worker UID/actor; same actor permits CampaignExecutionEvidence's approval
producer equality to the parent producer. This does not imply same process:
each native incarnation/attempt/scope binding remains distinct. The worker
executes the collection/check/report preparation phase and submits its ordinary
campaign-free ExecutionReceipt using xz9's submit_result. Only its exact live
worker lineage submits; a reviewer cannot submit_result on its behalf.

The existing launcher assigns a mapped independent reviewer process for that
child's exact candidate. Its UID differs from the child/parent worker UID.
That reviewer executes/validates the phase and submits a campaign-free ordinary
review receipt through existing accept_review. It covers the exact candidate,
phase's executed artifacts/checks and actual report set, and is imported as kind
review. This admission does **not** complete the child attempt and does **not**
count a campaign round. It supplies the existing independent review prerequisite
for the child's later successful finish. Receipt role/runtime and actor stay
exactly as existing Endcap requires; it is authenticated reviewer ingress carrying
worker-attributed producer and independent reviewer verdict, not permission for
the reviewer to impersonate the worker's result upload.

After child worker exit and positively verified cleanup/no-writer proof, the
recorded launcher or mapped supervisor calls existing finish(result_id).
Campaign-free child finish consumes its accepted independent review, submitted
result and cleanup evidence, then emits ordinary receipt_accepted and succeeded
transition in one canonical CAS. R2 makes no exemption from successful finish's
independent-review or no-writer requirements. An approval-phase submitted result
contains operation review and the exact already admitted reviewer actor/verdict/
head/report binding; the protected owner rechecks it against canonical
accept_review, so worker embedded metadata is not independently trusted.

There is no recursion: child accept_review validates executed checks, artifacts,
actor/UID independence and current candidate using ReceiptVerifier with
`campaign == nil`; it never needs a campaign finish, succeeded child or another
reviewer's approval of itself. Collection/check children can each finish after
one such direct independently executed review. Approval child additionally
consumes already succeeded collection/check children, then receives its own
direct independent review. Only afterward does R1 finish the parent campaign.
The parent campaign-bearing review receipt is submitted/accepted later and
cannot establish an earlier child proof.

## Exact reads and equality checks

Extend the existing `CampaignExecutionEvidence` check/review/approval dependency
interfaces with required source-owned `execution_binding:` in protected
composition. Local standalone uses its existing interface. The value is the exact
registered campaign_execution object plus resolved child assignment/attempt IDs,
definition_digest and binding_digest, supplied from canonical child-definition linkage and expected parent tuple, never session
metadata alone. R1 stores the accepted `{attempt_id, digest}` receipt reference
and that linkage as proof provenance with each session/check/approval.

The existing Assign accepted-evidence owner reads the child attempt at an exact
journal commit and verifies: definition blob digest; definition.parent and every campaign_execution
field/digest; intent/origin project/task/assignment/scope; succeeded transition;
unique coordinator-accepted receipt and digest; expected operation and no campaign;
head/base and parent generation at collection time; exact authenticated worker
producer and independent review actor/UID/process-purpose; imported bytes and
artifact digests. Read paths do not mutate or obtain journal write locks. Each
artifact comes from CanonicalEvidence.read at the receipt's accepted commit with
its original result or review context; report path translation is an explicit
owner-generated map from imported ref to R1 private materialization, checked by
both digests. Path equality is compared after this source-owned normalization,
never by treating a projected path as provenance. Missing link or substituted
projection refuses evidence_unavailable.

Historical reads validate recorded tuple and exact retained bytes even after
parent head/generation changes; they preserve R1 history. Current R1 approval and
parent acceptance additionally compare the tuple to the live registered parent
candidate and current policy. Existing AttemptCoordinator's succeeded-managed /
campaign-free evidence rule remains intact; protected reading adds exact linkage
and immutable-import verification, not nonterminal evidence acceptance.

## Separate report model from reviewer actor

R1 approval retains String fields `producer` and `reviewer` as authenticated
execution actors. Add required `report_models`, an Array of closed objects:
`{report: {path: String, sha256: SHA256}, report_model: String}`. Reports are the
existing approval `reports` references; exactly one report_models entry per
report, same normalized reference set, no duplicates/missing/extra entries.
`report_model` is a nonempty actual execution model identity string from the
report's verified session execution metadata, compared using the existing normal
model-identity resolver/equality semantics used by the review runner (no actor
substitution, uid-based alias or model-display-label comparison). If source has
no canonical alias resolver, equality is exact recorded model String equality;
R2 does not invent alias resolution. Provider identity stays in the existing
verified report execution metadata and is not erased.

CampaignEvidence validates each approved report's executed metadata and
report_model equality, report coverage and accepted collection proof. It no
longer compares execution.model to the reviewer actor. CampaignExecutionEvidence
still compares approval reviewer to the accepted approval receipt's
review.reviewer.actor, and producer to receipt.producer.actor.
The protected owner maps that actor to assigned reviewer_uid/process binding;
producer equals parent/child mapped worker_actor, with independent reviewer UID
and actor. Parent ReceiptVerifier compares approval producer/reviewer/head with
its receipt exactly as before; report_models must also match the executed report
set bound in the accepted approval-phase child's verified artifacts. Arbitrary
model text or an OS actor in report_model refuses. The extra R1 field becomes
part of stored approval/result identity and cannot be changed after completed
round acceptance. This is one coherent pre-1.0 contract replacement, no shim.

## Nonreentrant CampaignStore lock composition

Replace the proposed verify_result! shorthand with a source-owned public
`CampaignManager#with_verified_result!(result:, subject:, contract_identity:,
policy:, head:, base:, producer:, reviewer:) { |projection| ... }`.
It acquires exactly one existing CampaignStore transaction, validates the record
and computes current projection using private lock-held logic, validates all
expected values, yields a frozen projection to the fixed receipt/CAS composition,
then releases in ensure. It performs no history mutation. Without a block it
raises ArgumentError; projection cannot be retained as a later acceptance grant.
No opaque wire token, caller callback selector or user-approved boolean appears.

Existing public status/finish/start/record_round/session_binding continue to
acquire their own transaction and call the same private logic. They are never
called from this guarded block. In particular neither guard nor ReceiptVerifier
calls status/finish or opens another store flock descriptor. ReceiptVerifier
validates campaign result against the guard's source-owned current projection;
only the fixed protected composition supplies it, scoped to this call. Protected
verification without the guard refuses. Current public APIs retain their own
standalone semantics.

Ordering is lifecycle exclusion keys (task/parent/child, sorted by existing
owner), authority mutex where required by existing composition, one campaign
store transaction, then journal mutation lock/CAS. qjl historical reads inside
the store guard are read-only exact-commit reads with no writer lock. All protected
campaign mutations follow lifecycle-before-store ordering; no journal mutation
block acquires CampaignStore or lifecycle locks. The composition acquires the
store guard *before* entering journal.mutate, then each journal CAS retry
revalidates candidate/policy under the same held store guard and rechecks its
current expected tuple. If a retry needs a changed campaign expectation, abort
and reacquire the entire sequence; no stale result can be reused. No lock is held
during transfer/provider execution or child process cleanup waiting.

## Acyclicity and the precise structural prerequisite

Execution graph: registered parent -> independent collection/check children ->
independent approval child -> R1 completed round/finish -> parent campaign review
acceptance. Child direct campaign-free accept_review has no edge to parent
campaign acceptance. No R2-before-qkb or xz9.3 campaign prerequisite is introduced.

However positive child finish is **not currently delivered**: xz9's declared
finish requires 9c2 exact no-writer proof, and 9c2's native containment contract is
still draft. R2's dependency on xz9.0 therefore cannot be satisfied merely by its
current campaign-free review/source checkpoint or xz9.3 submission/fetch. This is
an exact structural prerequisite, not generic future work. The managed-child
choice waits for the already-owned campaign-free xz9 finish and 9c2 implementation;
it does not weaken cleanup proof to unlock R2. Its source graph is acyclic provided
xz9.0 is delivered with campaign-free finish and does not require R2's positive
campaign integration to complete its own scope. R2 later removes campaign refusal
for its own integrated consumer; final qkc/R3 then consume R2.

If xz9.0 completion is instead interpreted to require positive campaign-bearing
finish, its existing R2 prerequisite creates a cycle with ig3's xz9.0 dependency.
Independent readiness must settle that scope interpretation before promotion;
within ig3, consume xz9.0's **campaign-free** completed endcap contract explicitly.
Do not silently call a partial checkpoint a completed dependency. No xz9 task
files are modified by this proposal.

The rejected nonterminal alternative would change AttemptCoordinator#evidence's
succeeded-managed rule to read authenticated immutable phase subreceipts before
attempt terminality. It would require separate explicit phase admission/event,
independent verdict/report binding, candidate/generation policy rechecks, bounded
imports, exact historical reads, immutable replay and a distinct no-effect grant
rule. Those facts could prove executed reports without no-writer terminal proof,
but would introduce a new acceptance category rather than preserve current R1
semantics. Existing intent does not require that category; select managed children
and retain the precise 9c2/finish prerequisite.

## Independent review inputs and acceptance additions

Review the closed definition/linkage schemas, actual launcher/worker/reviewer
roles, phase operation matrix, no-recursion argument, model/actor checks and
nonreentrant guard. In addition to existing R2 acceptance, prove wrong child
parent/round/scope/generation/operation/ref refusal; campaign-bearing child
refusal; real succeeded children before parent finish; failed-child retry without
replacement; exact report_models coverage with actor/model mismatch controls;
CAS contention with no nested flock; restart reads of linked accepted children.
Source readiness must name the campaign-free finish/no-writer prerequisite and
cannot claim installed proof from this spec. Task remains draft / needs_review
until an independent reviewer approves the amended contract and prerequisites.
