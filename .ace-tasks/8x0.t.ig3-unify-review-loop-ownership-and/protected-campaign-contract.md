# Protected campaign lookup and import contract — draft, 2026-10-05

This is R2's proposed mandatory acceptance contract, not installed functionality.
It preserves accepted review policy and R3 dependencies. R1's CampaignManager
remains the only campaign/history/disposition owner; Assign remains the only
attempt, candidate, receipt and evidence owner. No new listener, campaign journal,
policy dialect or repair controller is introduced.

The exact managed-child, model/actor and nonreentrant lock proposal is now in
`protected-campaign-technical-closure.md`. It supersedes conflicting API/lock
shorthand and alternatives below; independent readiness remains required.

## Actual owners and the missing seam

At baseline `85c9704fe`, `Ace::Review::Organisms::CampaignManager` exposes
`start`, `record_round`, `collection_base`, `session_binding`, `status`, `finish`
and `store`. Its constructor accepts `repo_root`, `store`, `revisions`,
`check_evidence`, `review_evidence` and `approval_evidence`. `CampaignStore` exposes
`transaction`, `read` and `records(subject:)`; its existing checksummed identity
index, successor chain and retained finding snapshots are authoritative.
`CampaignEvidence` validates executed session/check/approval authority; an
approval names executed reports, producer, independent reviewer and exact
head/base/contract/scopes. `CampaignManager#finish` produces a local projection,
not an assignment acceptance or external-action permission.

Assign's existing `Authority::Endcap#accept_review_plan` normalizes uploaded
references and uses `CanonicalEvidence#import_plan` and `read_pending` before
journal CAS; `approved_review!` rechecks committed bytes using `read`.
`ReceiptVerifier#verify!` validates receipt binding/attribution/checks; its
`verify_campaign` currently constructs CampaignManager with `repo_root`, which
protected callers supply as the journal repository. That construction is the
incorrect seam to replace. An injected artifact reader alone does not fix it.
`verify_accepted_evidence!` is the retained evidence seam. Protected campaign
acceptance remains refused until the source-owned integration below is delivered.

## Fixed installed ownership

The existing services authority composition creates and owns one CampaignManager
context per mapped project. Extend the existing root-installed project deployment
schema with exactly `campaign_repository` and `campaign_store_root`: absolute,
authority-owned, non-worker-writable roots with protected ancestry, checked by the
same deployment owner as candidate/journal roots. Startup rejects missing,
substituted or overlapping worker/executor staging roots. The store is an
explicit `CampaignStore.new(root: campaign_store_root)`; never the default
worker `.ace-local/review/campaigns` or a store inferred from `journal_repository`.
This installs the existing R1 store; it does not copy campaign history into qjl.
The journal records only accepted receipt references and their existing import
provenance. Installation changes belong to the downstream deployment consumer;
R2 specifies and implements source validation, not an installer or auth service.

`campaign_repository` is the stable project review context, distinct in purpose
from the journal repository and transient immutable candidate checkouts. A local
subject is exactly `{repository: "local:<real campaign_repository>",
local_candidate_id: <registered canonical subject ID>}`. A forge subject retains
R1's normalized repository/PR identity, selected by the existing configured forge
owner. The authenticated launcher registers the assignment's exact campaign
subject in its existing definition/origin binding; a worker cannot register,
rename or select a repository. A worktree registration identifies which assignment
owns the candidate, not a filesystem path from which to discover campaign truth.
No implicit latest campaign/session, common-directory coincidence or same HEAD
substitutes for exact subject and ownership.

The composition supplies CampaignManager's existing revision/evidence dependencies
from the source-owned candidate and qjl owners, never uploaded callback names or
paths. Local current head/base come from the selected canonical candidate and its
registered base, not mutable worker Git HEAD. The controlled campaign repository
must contain verified candidate/base objects for review collection; missing
objects refuse. Forge current head/base still use R1's configured provider and
must match the selected candidate. Candidate generation is checked by Assign
outside the campaign projection, because identical SHA does not imply identical
accepted attempt generation. Review artifacts needed by R1 live only in its
protected context and must have positively verified canonical import provenance
before collection/approval consumption; a private file's ownership alone does not
prove execution. R1's existing check/review/approval evidence dependencies read
accepted qjl evidence from the mapped journal owner. No circular dependency on a
future positive campaign-bearing review receipt may establish those earlier
executed collection/check/approval facts.

## Source API acceptance surface

Existing wire operations and xz9 receipt/artifact framing remain the ingress;
there is no new public campaign service operation. Campaign receipt shape stays
`campaign: {id: <campaign ID>, result: {path: <normalized import reference>,
sha256: <digest>}}`, with that result also in `artifacts`.

R2 adds a source-owned `CampaignManager#verify_result!(result:, subject:,
contract_identity:, policy:, head:, base:, producer:, reviewer:)` contract.
These are exact expected values provided by the fixed composition after
canonical-byte verification, not a worker-selected trust source. It returns the
current authoritative projection only when the supplied result is the matching
non-dry-run accepted finish projection and all expected identities match.
It raises `CampaignContract::Invalid` otherwise. It performs no campaign creation,
round completion, disposition change, provider call or repair. The manager checks
its existing store and CampaignEvidence under the existing store transaction;
implementation may factor existing projection logic but cannot create a second
campaign evaluator. Public `status` and `finish` remain the R1 interfaces.

`ReceiptVerifier` receives this manager solely through the fixed protected
composition as an explicit protected campaign dependency. Protected mode requires
it for campaign-bearing receipts; it never reconstructs CampaignManager from
`repo_root` or falls back to local mode. This is source construction, not a
caller-selectable callback or wire field. Local explicit standalone receipt
verification retains R1's ordinary repository semantics. Protected mode is
selected by installed composition, never inferred from an uploaded flag.

The composition derives the expected tuple from authenticated origin, candidate,
assigned review and resolved consumer policy: project/assignment/attempt,
registered subject, owning worktree registration, candidate generation/head/base,
campaign ID/contract identity, effective policy and policy provenance,
round ID/scope identity, session references, worker producer and assigned executed
reviewer. Campaign ID/result are selectors requiring equality to that registered
binding, not authority. `verify_result!` compares the R1 fields it owns; Assign
compares origin/generation/peer/process-purpose and exact receipt/import binding.
Neither package reimplements the other's state machine.

Policy uses R1's exact `{revision, minimum_rounds, clean_rounds, required_scopes,
required_checks}` schema and digest from `CampaignContract.digest`. Preserve R2's
config-cascade provenance and stricter consumer gates. The fixed source policy
resolver reloads current constraints before acceptance; equality to an old policy
snapshot is insufficient after revocation. Changed policy requires the existing
explicit successor contract flow with reason, not silently overwriting a campaign
or inventing a policy epoch/controller. Impossible round/budget constraints fail
preflight. A historical policy snapshot is retained evidence, not current consent.

## Acceptance and import order

1. Authenticate the existing mapped peer/role and exact live process purpose.
   Resolve current project visibility, registered origin, candidate generation,
   independent assigned reviewer and explicit campaign subject/contract. Worker
   submissions never impersonate reviewer execution.
2. Decode the bounded receipt transfer and verify raw receipt/artifact digests.
   Use the existing `kind: review` CanonicalEvidence import for the campaign finish
   projection, binding its reviewer UID, review ID, head/generation/process
   binding and preceding event digest. Do not introduce `kind: campaign`.
3. Normalize `campaign.result` to the same imported reference as its matching
   receipt artifact. Obtain exact pending bytes with `read_pending` using the
   writer's current events/pending events/blobs/commit. Parse those bytes only;
   worker path names never cause an authoritative filesystem read.
4. Check ReceiptVerifier's attempt/producer/reviewer/check/receipt digest rules,
   then invoke the mapped CampaignManager verification with current expectations.
   Require active contract, `accepted == true`, `dry_run == false`, identical
   campaign ID, subject, contract identity, policy, result_identity, current/source
   head and base, completed round/scope/session provenance, and final approval
   producer/reviewer/head equality to the independently assigned review. Retain
   R1's convergence, blockers and required executed-check rules unchanged.
5. Before the same existing journal CAS, revalidate current candidate generation,
   authorization, visibility and policy. Hold existing lifecycle exclusion and
   campaign-store transaction through that acceptance decision; all campaign
   mutations use the same store lock. Fix lock order to lifecycle exclusion then
   campaign store then journal CAS; no reverse acquisition. CAS retries reread
   campaign/candidate/policy and reconstruct pending imports. A success reply
   grants no additional external effect.

On any failure no canonical accepted receipt, import event/ref or terminal
success is published. Temporary transfer cleanup follows the existing owner.
The campaign itself retains any earlier verified findings/rounds; rejection must
not erase history or rerun completed provider work.

## Recovery, retained reads and visibility

Committed campaign artifacts are read with `CanonicalEvidence#read` at one exact
journal commit supplying both chain/provenance and bytes. Recheck project,
assignment, attempt, reviewer peer UID/role, review ID, binding digest, generation,
length and digest; replaced/import-without-event bytes refuse. xz9.3's exact
historical evidence-purpose authorization governs byte visibility and supplies
no campaign mutation or current acceptance. Its submit_result/evidence_fetch work
remains independently executable and unchanged.

A restart reconstructs CampaignManager from the installed mapping and retained
R1 identity index/records, then resolves qjl accepted imports. It never imports
worker campaign records or uses an accepted response as a restoration source.
Missing/corrupt R1 store/index returns evidence_unavailable with restoration of
that retained owner required; no auto-start of a new campaign. Partial rounds
resume through existing pinned round/session identity. Identical completed
attempt replay remains R1's digest-checked replay; changed bytes conflict.

Historical artifact fetch may return exact formerly accepted bytes under current
purpose/visibility authorization after head advance or policy expiry. It must
label them historical and cannot claim live acceptance. Every fresh acceptance,
finish or effect prerequisite requires a fresh manager/candidate/policy check.
Head/base/generation change, successor, later blocker assessment, revoked policy,
wrong registration or missing provenance refuses current acceptance. Historical
qjl acceptance remains recorded; it is never rewritten as fresh approval.

## Mandatory executed acceptance for R2

| Case | Required observation |
|---|---|
| Real R1 campaign and protected import | Actual CampaignManager with pinned rounds/executed checks/independent approval produces finish bytes; authenticated reviewer import and exact candidate acceptance succeed. |
| Two worktrees/subjects, interleaved sessions | Exact registered subject/round/session selected; newer unrelated session, same SHA wrong generation and wrong project/PR all refuse without acceptance. |
| Forged worker result | Uploaded `accepted: true`, copied result identity, wrong producer/reviewer or self-review cannot replace current owner truth. |
| Fresh and restart reads | Same retained R1 history and journal-backed imported bytes survive restart; neither disposable worker files nor journal-repository campaign files are consulted. |
| Drift and corruption | Head/base advance, successor, policy revocation, later blocker, damaged store/index, altered bytes/import event or missing executed receipt refuse. |
| Race/replay | Concurrent campaign change/CAS retry cannot accept stale projection; exact replay produces no duplicate repair/provider work/import/acceptance; conflicting replay refuses. |
| Historical visibility | Authorized exact historical fetch works without current acceptance; unrelated worker/reviewer/executor purpose is denied. |

These are implementation requirements, not executed results. Deterministic public
CLI/assignment integration and actual owner objects are mandatory; provider stubs
alone do not prove this seam. Installed platform/auth/crash proof remains with its
existing downstream owners. No new native probe is authorized by this document.

## Dependency and readiness disposition

R2 still depends on R1, qkb and xz9.0 as declared. This contract is an R2 input,
not a prerequisite that qkb must implement before qkb can finish: qkb retains its
provider-neutral workflow ownership and R2 subsequently integrates its delivered
consumer. xz9.0 does not depend on R2 for its bounded campaign-free checkpoint;
positive campaign-bearing acceptance waits for R2. xz9.3 is neither blocked by
this contract nor responsible for implementing it. R3/final qkc consume mandatory
R2 integration; none of these dependencies is weakened.

The mapping, public method, lock order and provenance expectations above are
explicit proposed decisions requiring independent readiness review. They are
not evidence that source supports them today. The two exact unresolved source
choices (non-circular execution receipt ingress and model/actor attribution) are
recorded in `protected-campaign-readiness-inputs.md`; an implementer must not
silently invent their resolution. Independent readiness must decide them and
amend this contract before approving positive integration. Task stays
`draft` / `needs_review: true` until independent review closes this contract.
