# Protected assignment authority contract — readiness decision, 2026-10-05

## Implementation-discovered launch ownership amendment

The cross-user launcher assumption was not satisfied by current runtime source.
Draft prerequisite 8x4.t.09j owns the smallest working protected launch origin:
authenticated register/reserve/record_launch/bind/abort transport and qjl state,
deployment-mapped native endpoint authentication/control, actual gated worker
child and public driver integration. It depends on existing qjl/runtime core,
never the future xz9.0 service endcap. xz9.0 now consumes that source and owns
candidate/review/import, broader lifecycle/inbox routing and service integration.
Its original launch SCs remain endcap integration checks. The authority remains
one account and one qjl deployment, not a second launch ledger or domain daemon.
Herdr v0.9.3 native socket ACL/control and the authority-connected bootstrap gate
are selected in 09j; enforced Linux process-injection policy and installer-pinned
server identity are required. Current Lab deployment is not claimed compliant. Historical approval predates this gap.

The earlier contract passed independent readiness review at 0626be045. The launch/composition amendments subsequently passed independent review, and 09j source is integrated. Its task remains open for the remaining native crash/restart matrix and the recorded filter execution limitation; full installed acceptance is not claimed. Historical decisions remain in readiness-review-2026-10-05.md and companion review records. Current draft/needs_review metadata intentionally covers the unresolved result/evidence/finish amendment, not rejection of the accepted service source checkpoint. Full endcap implementation and installed acceptance remain open. qjl remains the only attempt/effect journal. The protected repository below is the deployment of that journal, not a second ledger synchronized from worker refs.

## Mutation owner and installation contract

A dedicated unprivileged assignment-authority OS account runs `ace-lab authority serve --authority ID` for the full protected service composition. It alone mutates managed assignment definitions, attempt cache, lifecycle exclusion, `refs/ace/execution`, journal checkout and imported accepted evidence. The process owns no publisher/admin/installer credentials. The ACE receiving API implements this boundary; lab-config gad.8 installs accounts, protected configuration and paths, and gad.b supplies domain handlers. No Python/domain authentication daemon, root broker, UID switching or broad shared writable directory is introduced.


### One source-controlled authority composition

`ace-lab authority serve --authority ID` constructs the same Assign Authority Server/Router and 09j LaunchLifecycle, plus the generic Assign Endcap handlers. A source-owned Lab AuthorityComposition injects the existing Lab ServicePolicy/GrantResolver policy loader into the generic boundary. qjz owns the canonical proposal authorization producer and resolver integration and is now delivered with independent installed verification. xz9.0 fixture acceptance may still use an exact fixed qjx grant. Proposal references must use qjz’s canonical resolver, never a YAML/prefix bypass or an implicit cyclic prerequisite. Lab remains the single owner of technical operation/lease/grant validation; Assign never depends on Lab and no second policy dialect, journal, listener or authentication transport is introduced. The Lab receiver reloads that same owner immediately before effects, while the canonical claim/dispatch boundary revalidates it under existing lifecycle exclusion and journal CAS. No wire payload or caller path selects a handler, plugin, executable, policy or arbitrary callback.

`ace-assign authority serve --authority ID` is the distinct launch-only 09j entrypoint. It supplies register/reserve/record/bind/release/abort and launch status for assignments whose deployment selects only that scope; it does not claim the full candidate/review/service/inbox contract. Authorities.ID.composition is a fixed installed enum `launch` or `services`; the selected source entrypoint must match it. A services deployment cannot silently omit Endcap or fall back to the launch-only entrypoint. Each project has exactly one mapped authority owner/endpoint/journal; launching another composition for that same project or listener is refused. The full service composition retains the exact 09j origin, gate, native policy and driver requirements. These are meaningful product scopes, not compatibility routes.

A root-installed absolute configuration selected at deployment contains `authorities.ID.uid`, `socket_path`, `state_root`, `composition`, and `projects.PROJECT.journal_repository`, `evidence_git_ref`, `evidence_checkout_root`, `assignment_root`, `candidate_root`, `launcher_uids`, `reviewer_uids`, `worker_uids`, `service_executor_uids`. `candidate_root` holds authority-owned immutable checkouts; worker checkout registrations are records created by authenticated launchers, not requester paths. Each registration binds project/assignment/attempt, worker UID, exact worker checkout, candidate SHA, candidate generation and exact process binding including OS birth when present. A socket-only connect group/ACL may permit connection; it never permits writes to state. Configuration and ancestors are root-owned, non-worker-writable, and cannot be overridden by cwd/environment/project config. State/candidate parents are authority/root-owned with no requester write, rename or symlink substitution; private roots are 0700. Executor staging is executor-owned 0700, separate from worker and authority state. Nothing in a worker-controlled Git config, hooks, common-dir/ref, alternates or evidence tree is accepted as authority.

Existing qjx service policy retains fixed operation argv, service ID, executor UID, transport, socket and lease. It gains `authority_id` referencing this deployment map. All managed clients use the mapped authority; caller-local qjl fallback is forbidden for protected assignments. Same-user standalone/local mode stays explicit, with its existing local authority semantics; it cannot satisfy protected service acceptance.

## Attempt origin and candidate acceptance

Receipt-bearing uploads use the fixed source-owned `receipt_artifacts` binary purpose after a bounded 16 KiB control header. Part zero is exactly one nonempty receipt JSON document, at most 16 KiB; `params.receipt_sha256` binds its raw bytes and the descriptor binds its position, length and digest. Up to sixteen following evidence parts are each at most 64 KiB and together at most 256 KiB, independently of the receipt allowance (272 KiB total). The existing generic `artifacts` purpose retains its original sixteen-part/256 KiB limits. Each lifecycle operation selects its purpose from source; a peer cannot select or widen it. Before any journal mutation, the owner rejects missing/duplicate receipt framing, incomplete or duplicate artifact references, reordered/different artifact bytes, trailing bytes or missing write-EOF. Receipt declarations bind evidence part order and digests. Receipt JSON is never embedded as an unbounded control field, and failed uploads leave no canonical event/ref or private spool.

Protected service claim and fresh dispatch admission select the fixed `service_input` upload purpose: exactly one nonempty original structured JSON input part, at most 64 KiB, after the bounded control header. Receiver and authority share `Lab::ProtectedServicePolicy`, which delegates byte/schema/forbidden-field/depth validation and canonical digest/target derivation to the existing `ServiceInput` owner. The authority independently recomputes and matches the immutable input digest and target; an asserted digest from a worker or receiver is insufficient. Original values remain ephemeral memory and never enter events, request records, errors or another ledger. Every claim/begin CAS retry recomputes against these exact transferred bytes and reloads the existing root-owned `ServicePolicy` operation, authorization, project visibility and executor lease. A changed policy/input/target or stale exact peer/candidate refuses fresh dispatch. Completion after invocation records exact executor-attributed truth and cannot grant a new effect.

Each services-composition project has a fixed installed `service_receivers` map from service ID to `{executor_uid, socket_path, staging_root}`. UID is a positive nonroot mapped service-executor UID, separate from worker accounts. Canonical protected endpoint and executor-owned private 0700 staging are selected by this map, never by caller input; duplicate endpoints/authority ownership refuse startup. This map supplies identity/placement only. The existing `ServicePolicy` remains the sole operation/argv/grant dialect: its local fixed argv is the handler, while the authenticated receiving request records transport `unix`. Launch-only composition does not require receiver entries; full services configuration cannot silently omit its receiver.

The deployment-controlled launcher calls the authenticated authority public client API `reserve_attempt(project:, assignment:, scope:, worker_uid:, runtime:)`, then launches the worker and calls `bind_process(attempt_id:, process_binding:)`. The authority creates intent/reservation first and records process-start only after authenticated exact child binding, as detailed in the lifecycle API below; it returns the existing qjl attempt identity/generation. The worker is never allowed to create intent/process-start or alter actor/UID/project binding. Existing ace-assign driver/coordinator lifecycle calls for these protected assignments route to this owner. An inaccessible owner is evidence_unavailable, never permission to continue locally.

The launcher registers the actual worker checkout. A candidate submission uploads a self-contained Git bundle from the registered worker client; the authority does not read or traverse the private worker checkout. It imports the proposed object graph under controlled Git configuration (no worker hooks/config/alternates/executables). The authority verifies SHA/object closure and creates an immutable authority-owned snapshot and exports authenticated self-contained object bundles to individually authorized reviewer/executor clients. Their private verified materializations, never the inaccessible authority path, supply execution context. A separately authenticated reviewer executes checks against that exact snapshot and submits the existing review receipt, bound to SHA, candidate generation and reviewer execution identity; reviewer must differ from candidate author/worker. Only the authority accepts it into qjl. A SHA copied from the worker ref or a worker-uploaded review JSON is insufficient. Worker changes after review do not change the snapshot: dispatch uses the approved snapshot and accepted target. If an operation requires the live worker checkout, it must positively verify the registered current SHA and immutable operation inputs immediately before effect or refuse; approval is never inferred from its mutable HEAD.

The first slice includes this origin/import/review flow and one fixture effect. It does not start with a synthetic empty authority server or trust a pre-populated worker journal. Candidate approval and process binding use the same lifecycle locks as qjl; terminalization concurrent with claim blocks the claim.

## Public operations and peers

The assignment-authority client exposes reserve_attempt/bind_process/candidate import to mapped launchers, review acceptance to mapped independent reviewers, request/status/dry-run to the owning worker, and dispatch/receipt completion to the fixed mapped executor. Each API derives peer UID/GID from the accepted Unix connection; payload caller_uid is checked for equality and never supplies identity. Workers cannot impersonate a launcher, reviewer or executor by naming an ID. Assignment definitions come from the authenticated launcher's registered assignment, never arbitrary caller filesystem paths. Requests include IDs and structured input only. Existing request identity/digest/target/public outcome vocabulary remains qjx-owned.

A worker's `ace-lab service request` first contacts the configured generic service receiver under executor UID. The receiver authenticates the worker, then asks the authority to validate the exact worker binding and claim. The authority treats this as an executor-delegated caller assertion ONLY from the fixed receiver UID allowed for that service/project; it independently checks the registered worker/attempt/grant. A worker cannot use that delegated API directly. This trust is OS-account granularity, not proof of a particular executable; deployment must isolate executor accounts from workers. The receiver rechecks current policy/lease before handler invocation. The authority atomically claims uncertain in the same journal lock/CAS transaction before an effect; it returns a durable dispatch ticket identifying the canonical claim commit, request, executor, approved candidate generation and policy digest; it is not a bearer credential. The ticket phase/replay/failure rules below govern invocation. Only that executor can consume/complete this grant. Lost reply after claim never authorizes a repeated effect.

The receiver invokes fixed argv through the bounded process-group primitive, structured stdin and sanitized fixed environment, with its own private verified materialization of the approved snapshot as execution context. No request-selected command, credentials, config, sink, repo root or UID. Handler stdout/stderr are bounded and sanitized. A handler writes evidence only in the receiver-created private request staging directory. The receiver opens evidence without following symlinks and sends bounded evidence bytes/digests with receipt through the authenticated authority completion API. The authority imports verified evidence into its own private immutable root and records the existing repository-relative evidence references in the same canonical journal repository, so existing qjl reference semantics remain comprehensible. No cross-user chmod of receipts or direct executor write to authority Git state. Imported evidence is authority-owned; qjl must therefore verify immutable import provenance recorded by this owner (authenticated executor UID, exact dispatch grant/claim, artifact digest and receipt binding), rather than require the imported file itself to retain executor ownership. This is a required qjl verifier contract change in xz9.0, not a permission workaround or a caller-supplied verified flag. The same canonical transaction records the provenance and transition. Candidate inspection and journal mutation use separate protected repository contexts: candidate_head resolves the selected immutable snapshot; EvidenceJournal and receipt evidence resolve the mapped canonical journal repository. Never reuse a worker repo_root for either trusted context. Authority verifies canonical binding, executor peer, digest and outcome attestation, then writes the qjl transition. Integer executor_uid and arbitrary preexisting paths never confer settlement authority. Returned public JSON is a projection, not an accepted receipt to be re-ingested by the worker.

`status`/replays authenticate the current worker and project visibility but preserve delivered qjx terminal replay behavior across head advance, attempt terminality and expired historical authorization. Dry-run is read-only and validates current eligibility without importing candidates, claiming or acquiring credentials. Rejections preserve qjx classification and redact raw input/stderr.

## Platform, bounds and failures

Supported platforms: Linux and macOS with Ruby Unix peer authentication available. Use `BasicSocket#getpeereid`: Ruby implements native getpeereid on macOS and SO_PEERCRED on Linux; no external command/environment UID fallback. Check both listener/client peer and protected socket ancestry. Unknown passwd identity, unsupported API or credential lookup failure refuses before mutation/effects. Installed Linux multi-UID proof is mandatory; actual macOS socket peer smoke and API test are required for its supported claim.

Use qjx's existing 30-second request deadline, 16 KiB public response limit and bounded structured input limit from ServiceInput; authority receipt import separately limits each artifact to 64 KiB, total 256 KiB, at most 16 artifacts, refusing excess before import. Claims already made stay uncertain on oversized/crashed post-effect output. Handler descendants must share an owned process group; deadline/shutdown kills and reaps the group through BoundedProcess. Exclusive protected listener lock covers lifetime; inode identity gates unlink, second startup cannot remove another listener, and stale recovery requires lock plus positively absent old owner. Parallelism is bounded to 16 accepted connections; excess receives a sanitized busy refusal, never unbounded workers.

The authority stores no secret material. Evidence is retained in qjl for the existing retention policy; this task does not invent a pruning deadline. Effect-before-receipt or authority/client/receiver loss preserves uncertain; restart reads canonical qjl, does not re-execute. Reconciliation requires attributable executor evidence or proven no-effect evidence through the same completion gate. Journal/cache restoration must not resurrect a terminal attempt, free a dispatched grant or change the established 16h policy. R2/R3 installed drills remain downstream requirements.

## Research basis and review gate

Inspected ServiceRequestService, ServiceExecutor, AttemptCoordinator, EvidenceJournal, HITL Lifecycle::Service/Peer and y23 Inbox. qjx claims/settles caller-locally; qjl's refs are authoritative only if repository ownership is protected. HITL already uses kernel peer credentials, but is not a service receiver/assignment authority. Herdr owns event lock/signed event transition; assign bind_inbox/reconcile_inbox owns consumer journal recording. No new direct event-journal writes are proposed. Recovery repair dab0dbeea is independently accepted and integrated on main; implementers consume its exact process-birth and expected-registration semantics.

Primary source: [Ruby BasicSocket implementation](https://docs.ruby-lang.org/en/master/BasicSocket.html#method-i-getpeereid). Linux/macOS implementation branches are source evidence, not executed multi-user acceptance. Independent reviewer must assess the receiver-to-authority delegation, candidate import isolation, assignment origin, and whether the first slice closes these boundaries without hidden prerequisite work. No runtime acceptance was executed in this specification pass.

## Independent review repair — authoritative API details

The following details resolve findings 1–4 of independent review bc9e08017. They supersede the earlier shorthand where ownership/transport was incomplete. Fresh independent review accepted these changes at 0626be045 before child and parent promotion. The first real fixture slice xz9.0 owns these source contracts and their end-to-end integration; xz9.1 owns resilience proof and boundary failure handling. Lab installation/domain proof is downstream and does not become a prerequisite of generic source implementation.

### Private candidate transfer and execution access

Authority candidate/state roots remain 0700. No reviewer/executor traverses them. The owning worker uploads `submit_candidate` bundle bytes through the authenticated socket; registered worker UID and attempt/generation constrain upload, but the bytes themselves are untrusted source content. Transfer is framed with declared size/SHA256, capped at 64 MiB, deadline 30s; repository objects must be self-contained (no prerequisites/alternates/promisor objects), and target head must equal the declared exact commit. Authority uses a clean authority-owned bare quarantine repository and fixed Git argv/environment/config with hooks disabled; validates bundle, object closure and fsck before creating the new candidate generation. Incomplete/oversized/malformed upload has no candidate acceptance. Worker source mutation during bundle creation either produces a valid self-contained exact commit or fails verification, never changes the accepted generation. No private worker directory access is assumed.

`export_candidate(project_id, attempt_id, candidate_generation, head)` returns bundle bytes plus `{head, tree_sha, bundle_sha256, bytes, candidate_generation, journal_commit}` only to the mapped reviewer assigned this candidate or the mapped executor holding this request ticket. A reviewer cannot fetch other projects/candidates. The client imports into its own private 0700 scratch repository under its fixed deployment root, with no inherited Git config/hooks/alternates; it verifies byte SHA, full closure and exact head/tree. It materializes tracked content there without `.git` from the submitted filesystem or caller paths. The fixed runtime performs checkout safely: no extraction through symlink parents, no absolute/traversing paths or devices. A source symlink is never used as an extraction parent; it may exist as tracked content only when it resolves inside the private snapshot. Fresh scratch root is not worker writable; a worker cannot modify parent, refs/index/config or transferred bytes. Reviewer tests and fixed handler argv execute against these separate exact-head materializations. Changes needed by tests belong in scratch runtime output, not accepted candidate identity; verifier checks the candidate tree/reference before accepting review. The executor rechecks exact HEAD/tree and authority current candidate generation immediately before dispatch. Fixture acceptance proves actual distinct UIDs can read their exports while no peer traverses authority state or another peer's scratch root.

### Authenticated assignment lifecycle API

Wire envelope: `{version: 1, operation: NAME, mutation_id: ID, project_id: ID, params: OBJECT}`; all mutations require unique mutation_id and expected journal/registration generation in params, except first registration. Response is existing `{status: ok, data: {...}}` or `{status: error, error: {code, message}}`. Success includes IDs, canonical journal_commit and generation; read-only responses omit mutation fields. Existing error classes map to invalid_input, unauthorized, missing, conflict, invalid_attempt, evidence_unavailable, invalid_configuration. Unknown fields, malformed framing, oversized content or IDs fail closed. Exact mutation replay returns the original canonical result; same mutation_id with changed params/bytes conflicts. This dedupe is in the existing canonical evidence ref/attempt events, never a separate RPC ledger. Authentication is kernel UID plus fixed project/role allowlist and registered attempt actor binding, not Process.uid of the authority process. Public client methods take the table's named params; no arbitrary method-dispatch or identity object from a worker.

| Operation / caller | Required parameters and durable result |
|---|---|
| register_assignment / mapped launcher | assignment_id, validated current assignment definition bytes/digest, project_id, expected absent/current definition_generation; owner validates normal AssignmentManager schema, fixed project association and launcher policy, stores definition under authority assignment_root and records definition digest/generation in qjl. Exact re-registration is idempotent; changed active definition refuses. |
| reserve_attempt / mapped launcher | assignment_id, scope, worker_uid, runtime, base_head, launcher_process_binding; registered assignment must be managed, allowed worker must belong to project; records intent/reserved with authoritative actor/role/runtime, launch identity and launch_ticket, before any process-start. Response attempt_id, reservation_generation, launch_ticket. No caller-created attempt IDs/actor identity. The mapped launcher may reserve only allowed worker_uid; the authority derives attempt actor from that worker account/project binding and records launcher peer UID separately as issuer. Worker actor/role identity is never resolved from the authority account. |
| record_launch / same launcher | attempt_id, launch_ticket, exact gated child process_binding, expected reservation_generation; validates runtime/PID/UID/OS birth through current runtime binding primitives and stores a launch-binding fact, not process-start. |
| bind_process / same launcher | exact recorded child process_binding, launch_ticket, expected reservation_generation; positively observes same child alive with exact birth/UID/runtime, journals process_start/running, then returns launch permission. Exact duplicate binds return same result; any different PID/birth/runtime conflicts. Authority never resolves itself as worker. |
| gate_ready / exact gated bootstrap worker | launch_ticket, bounded protocol version; kernel peer PID/UID/GID and independently read birth/lineage must match the recorded native child; retains one stream without granting worker launcher authority. |
| release_launch / same launcher | attempt_id, launch_ticket, exact process_binding, expected_generation, mutation_id; requires canonical bind and retained exact live gate, commits launch-release-issued before one release frame. Replay returns issued state without retransmission; lost reply remains potentially executed. |
| abort_launch / same launcher or mapped recovery supervisor | attempt_id, launch_ticket, failure evidence bytes/digest and expected generation; records failed launch and frees attempt ownership only after positive no-execution/gated-child absence proof described below. Indeterminate evidence records uncertain and retains ownership. |
| submit_candidate / owning worker or launcher | attempt_id, expected candidate_generation, exact head, bundle size/digest/bytes; import contract above, actor must match worker binding, active attempt required; returns new generation/head/tree. No claim/review/effect can use an unaccepted upload. |
| export_candidate / assigned reviewer or ticket executor | attempt_id, candidate_generation, head and reviewer assignment or request ticket; read-only bounded bytes and descriptor as above. |
| assign_review / mapped launcher | attempt_id, candidate_generation, head, reviewer_uid and reviewer_process_binding; reviewer must be mapped project reviewer and differ from worker/author UID, exact observed execution binding required; journal reviewer assignment before artifact acceptance; changed head/generation invalidates assignment. |
| accept_review / assigned independent reviewer | attempt_id, candidate_generation, head, existing review receipt bytes and bounded executed-check/review artifact bytes/digests, expected generation; validates current qjl ReceiptVerifier rules, executed checks, independent actor/UID, role/runtime execution identity and exact exported candidate. Imports reviewed artifacts and accepted receipt in one commit. Uploaded worker review is unauthorized. Response accepted receipt digest/journal_commit. |
| finish / owning worker submits business evidence; mapped launcher/supervisor admits terminalization | attempt_id, expected generation, current normal finish receipt bytes/artifacts; peer-attributed receipt acceptance retains existing role/review checks. Terminalization uses current coordinator finish/lifecycle locks and refuses unproven pending effect/inbox/process cleanup. Worker cannot assert other actor or select force cleanup. |
| recover / mapped supervisor | assignment_id/attempt_id, expected generation; owner reconstructs current canonical qjl and uses current Reconciler exact runtime/process_birth facts and inbox consumer state. Returns existing recovery decision/adoption/uncertain disposition; no inferred process-start, fabricated child identity or local cache fallback. |
| bind_inbox / active owning attempt actor through authority | attempt_id, event_id, registered inbox_context_id; owner invokes current coordinator bind_inbox using peer-resolved identity and the fixed context, records canonical event/attempt/digest/key registration. No caller-selected Inbox object/path. |
| reconcile_inbox / mapped signer/supervisor | attempt_id, event_id, inbox_context_id, exact signed receipt bytes, detached signature bytes, expected registration; owner materializes these bytes privately, invokes current coordinator reconcile_inbox with fixed Inbox client and peer-resolved trusted identity, preserving expected_registration verification under Herdr event lock and exact accepted proof replay. Signature path is owner-created, never a signer/worker filesystem path. Response canonical Herdr state and qjl consumer evidence reference. |
| attempt/service status and evidence fetch / owning worker, assigned reviewer or mapped supervisor/executor | fixed project/attempt/request/evidence ID plus required role binding; visibility filtered by current project grant and purpose. Worker gets sanitized public projections; raw review/observation artifacts only to allowed peers. |

All current protected driver start/receipt acceptance/finish/recover and evidence consumers route through this API. reserve/process_start separation is a required source refactor of current start, whose intent and process_start are emitted together. Ordinary local standalone assignment behavior is a separate explicit operating mode; it never acts as a protected assignment fallback.

Reserved-unbound behavior: external request eligibility requires a running, positively bound child, never merely reserved. Launcher uses a generic gated runtime bootstrap: child cannot execute worker payload before bind permission, and pre-release authority gate-stream EOF exits without payload execution. Before creation, launcher process binding/launch ticket is durable; after spawn it records exact gated child PID/birth with record_launch, then binds, then releases the gate. This handshake belongs to prerequisite 8x4.t.09j ACE driver/runtime integration; no Lab daemon. The selected remote native child connects directly to the existing protected authority socket; no inherited launcher pipe is assumed. The full selected readiness/release/EOF/termination contract is in 09j's Selected native gate contract. bind_process commits binding without release; launcher-only release_launch durably records issuance in the same qjl before one framed gate release. Exact replay never resends release. Release reply loss/EOF after issuance means potentially executed. A ready worker connection is admitted only when kernel peer PID/UID/birth and trusted native lineage match the launcher's exact binding; worker cannot invoke launcher lifecycle operations. Root-installed immutable bootstrap, installer-pinned server birth and enforced Yama=2/no CAP_SYS_PTRACE are mandatory Linux protected prerequisites. An insecure same-UID fixture cannot count as protected acceptance. If launcher dies before child record, closed gate is no-execution evidence only with an authenticated launcher/runtime termination report and positive absence of any executing worker under that launch ticket; absent proof retains uncertain and supervisor escalation. If it dies after record but before bind, supervisor inspects/terminates that exact gated child and confirms absence before abort_launch. If it dies after bind but before release, recover checks actual exact child; it never invents a successful start/release. A 30s launch handshake deadline triggers inspection/abort, not automatic lease freeing. A live child with unreadable gate/release state stays uncertain. If journal committed bind but response was lost, exact retry returns binding; launcher may release its still-owned gate only after canonical binding and exact live birth match. If child executed or outcome cannot be excluded, ordinary current recovery applies and ownership stays held until attributable outcome. No indefinitely silent orphan: status reports reserved/uncertain reason, launch ticket and required supervisor action; deadline itself is not absence evidence.

### Canonical imported evidence and completion

Protected artifact truth is the Git blob in the accepted canonical evidence ref, not a separately written filesystem file. A single qjl commit includes artifact bytes at repository-relative `evidence/imports/ARTIFACT_ID`, immutable `evidence_import` descriptor and accepted review/service/inbox event. Descriptor version 1 contains `{artifact_id, kind, project_id, assignment_id, attempt_id, peer_uid, role, binding_digest, sha256, bytes, admitted_at, admitted_after_event_digest, request_id_or_event_id, candidate_generation_or_claim_generation}`. IDs and admitted_at are owner-generated; bytes digest is recomputed. Exact binding_digest hashes canonical receipt/event/request binding; kind constrains which verifier may consume it. Business result imports use kind `result` and role `worker`, admitted only from the authenticated mapped worker bound to the exact active attempt/native process. A result import is submitted evidence, never self-approval: mapped launcher/supervisor finish admission and independent review remain separate authority checks. No generic verified boolean. File projections/cache are disposable, private and never trusted in preference to ref blobs. Owner/import provenance event chain and referenced exact blob must remain intact; missing/mutated provenance/blob yields evidence_unavailable and cannot free an authorization or authorize retry.

All protected consumers must use this same source verifier: coordinator verify_service_evidence!, EvidenceJournal validate_terminal_receipt!, settlement_evidence_intact?/authorization reuse, terminal request status/replay, review evidence, recovery/Reconciler and failed/no-effect reconciliation. They resolve against canonical journal_repository/ref rather than candidate repo_root and check owner-authenticated import provenance plus immutable binding/content/attestation. Raw executor ownership and mtime checks remain local-mode checks only; protected mode replaces them everywhere and cannot fall back when provenance is missing. Terminal replay may survive candidate advance but still verifies retained evidence before exposing a settled assertion/freeing a grant. Add tests corrupting each independent read path, not just initial completion.

Dispatch ticket is persisted in service claim `{dispatch_ticket_id, claim_binding, executor_uid, candidate_generation, policy_digest, phase: issued}`; owner-generated dispatch_ticket_id is unique and claim_binding hashes immutable canonical request binding plus ticket ID. Actual journal_commit is returned after CAS but is not recursively embedded in its own commit/event digest; phase lives in that request record, not another ledger. `begin_dispatch(request_id, expected_claim_binding)` by exact executor rechecks live attempt, current policy/grant/lease/snapshot under lifecycle exclusion and CAS; first call changes phase to dispatch_started and returns invocation permission once. An exact retry returns status `already_started`, never invocation permission. This deliberate at-most-once permission rule leaves a lost reply uncertain; it cannot prove the effect did not happen. Receiver invokes only on its first positively received permission. Claim/start loss before invocation can later use positively verified no-effect completion; restart never automatically invokes.

Every service request mutation ID is checked by the same canonical journal mutation owner, including when its request ID already exists. Exact mutation replay retains that mutation's original `generation` and `journal_commit`; these are acceptance metadata, not a claim that the current request state was accepted at that historical generation. The sanitized `state`/dispatch projection may report later canonical outcome truth. A client needing the current attempt generation uses authoritative service status before another service mutation. A new mutation ID for an identical retained request obeys the normal expected-generation check, creates no service claim/update and returns its own mutation acceptance metadata. Claim replies distinguish `claim: created` from `claim: retained`; neither grants invocation permission. Only a fresh successful begin_dispatch response can permit invocation.


### Executor authorization read

`service_authorization` is a fixed read-only operation for the exact recorded executor UID. Its parameters are `mapping_id`, `assignment_id`, `attempt_id`, `request_id`, `claim_binding`, `head`, `candidate_generation`, `input_digest`, and the strict transfer descriptor. It uses the existing five-field authority envelope with `mutation_id: null`; non-null mutation IDs refuse. The source operation selects one nonempty `service_input` part of at most 64 KiB. No input path, actor, executable, policy selector, or authorization decision is accepted from the caller.

The authority rereads the canonical request and independently recomputes input digest and target using the same Lab input/policy owner on every call, including identical repeated calls. It checks the exact request/claim/candidate/native origin and authenticated executor, current project visibility, operation, grant or canonical qjz proposal, lease, and policy digest. Fixed qjx grants remain valid fixture inputs; proposal references require the qjz canonical resolver. No caller-local proposal journal or YAML imitation can replace it. Read success returns only `{request_id, claim_binding, head, candidate_generation, policy_digest, operation_digest}` within the existing 16 KiB response limit. It advances no journal ref, imports no bytes and creates no durable capability or replay cache. These digests identify the checked immutable operation and policy; they do not authorize an effect.

The canonical claim projection includes its immutable `policy_digest`. The same source-owned Lab protected policy adapter computes `operation_digest` from the canonical normalized operation returned by existing `ServicePolicy.operation!`, using the existing canonical evidence digest owner, and computes full `policy_digest` by its existing policy/grant/proposal binding digest. The receiver reloads that same installed Lab operation owner and compares its operation digest with the reply; it compares the returned policy digest with the immutable canonical claim projection, without reading or reconstructing the authority-private proposal journal. The fresh authority read independently computes and checks the current full policy digest. This read does not replace fresh `begin_dispatch` admission: only a positively received fresh successful begin response permits one invocation, and begin revalidates original immutable input and current policy under each CAS retry. A retained claim, repeated begin, successful authorization read, or read retry never permits invocation. If the read refuses or its reply is lost after begin permission, the receiver invokes nothing and preserves the recorded uncertainty. It must not repeat begin or infer no effect from that failure. After receiving fresh begin permission, the receiver reloads and compares the installed operation, then obtains one final fresh authority authorization read immediately before invocation. That successful authority read is the effect-admission linearization point. A policy change observed before that point refuses; a later change does not retroactively cancel an admitted effect. If its subsequent local operation consistency check differs, the receiver still refuses invocation. There is no polling loop or second controller. Completion reports already-observed truth independently of this read after revocation, lease expiry or attempt terminalization.

`complete_service` has fixed parameters `{mapping_id, assignment_id, attempt_id, candidate_generation, head, request_id, claim_binding, receipt_sha256, transfer}` and a required strict mutation ID. It does not accept caller `expected_generation` or a generation-mode selector. This completion-only operation records exact already-observed outcome truth; the canonical JournalMutation owner resolves current generation on each CAS retry under its existing lock. The completion callback rereads and revalidates exact recorded executor/request/ticket/candidate and terminal receipt/artifact binding on every retry. This source-owned mode is restricted to `complete_service`; every other mutation keeps its required caller expected-generation admission. Missing/current visibility or expired invocation lease does not discard the recorded executor's completion evidence, but status remains grant-and-purpose filtered for every role. No completion response grants invocation or broad status visibility. Strict mutation-ID/parameter digest and exact/contradictory completion replay semantics remain unchanged.

`complete_service(request_id, claim_binding, receipt_bytes, artifact_bytes[])` and `complete_no_effect(request_id, claim_binding, reconciliation_challenge, receipt_bytes, artifact_bytes[])` admit only the exact recorded executor UID. Atomic completion imports canonical bytes/provenance and transition under request/lifecycle locks. Identical receipt/artifact digest replay returns the same result; changed receipt or content conflicts, including succeeded-versus-no-effect contradiction. The executor may complete/report real observed outcome after its invocation lease expires or attempt becomes terminal; that permits recording truth, never a new begin_dispatch. Revocation stops new effect admission; it cannot discard an already dispatched effect's evidence. Invalid policy/config, lost authority or expired lease before begin_dispatch produces no handler effect; a claim already issued remains uncertain until proven no-effect. No caller boolean frees it.

For failed/uncertain effect recovery, authority issues a durable no-effect challenge bound to request/input/claim and latest failed/uncertain event digest/generation. The executor must freshly inspect actual target and provide an attestation naming that challenge and positively establishing no effect (including process/handler termination and no surviving writer), not merely old artifact bytes, failure exit or timeout. Existing attestation line remains plus challenge-bound structured data. Owner records admission strictly after the challenge/current failure event in its canonical chain; caller timestamps/mtime are irrelevant. A later failure/generation invalidates earlier challenge. Failure state can record outcome uncertainty; only complete_no_effect with verified evidence reaches existing failed-settled and releases decision consumption. Read paths verify challenge lineage and content again.

Import before Git commit remains quarantine and confers no accepted reference; crash removes/reclaims quarantine without losing effect uncertainty. Commit includes blobs/provenance/transition atomically via existing Git CAS. Crash after commit but before response returns identical canonical completion on retry. Ref conflict revalidates generation/current challenge; orphan blobs are unreachable, not accepted evidence. Crash after Herdr reconciliation but before qjl append replays exact retained signed bytes via current expected_registration/accepted proof mechanism, then appends once; no bare transition assertion is accepted.

### Domain handler transition required in gad.b

Shipped lab-config lab_setup_project.py currently requires request.transport=local and caller_uid=executor_uid, writes beneath fixed executor evidence_root, and its usage assumes assignment-repository/executor-owned evidence. It is NOT compatible with this protected cross-user receiver. xz9.0 generic fixture proves the new contract; gad.b must update the real producer/consumer source, docs/setup-project-service.md and tests before cross-user setup-project acceptance. No claim of present handler compatibility or source implementation here.

Receiver handler stdin v1 is `{version: 1, request: CANONICAL_QJX_BINDING, input: ORIGINAL_STRUCTURED_INPUT, execution: {executor_uid, authority_id, claim_binding, candidate_generation, head, staging_id}}`. request.caller_uid remains the authenticated worker UID; request.transport remains unix for this receiving path. Handler verifies current OS real/effective UID equals execution.executor_uid and request.executor_uid, fixed operation/digest/target, and the receiver-created execution binding; it does not require worker UID equals its own UID. Handler is launched only by its trusted same-account receiver with fixed environment/config; arbitrary worker stdin cannot reach admin process. Receiver supplies staging path through its owned inherited directory handle/fixed internal launch configuration, never a request-selected path or public argv. Domain handler writes only private request staging and returns `{request_id,input_digest,outcome,evidence:[{ref:RELATIVE_STAGING_PATH,sha256}]}`. Receiver verifies bounded regular files without symlink ancestry, extracts bytes and completes canonical import; it rewrites evidence refs to authority-issued canonical import refs before receipt construction. Domain project_root/credentials remain fixed admin-controlled config; only evidence sink moves. Same-user local handlers use this same envelope contract where adopted, with authentic caller preserved; obsolete local-only equality assumptions are removed, not bypassed by impersonation. gad.b must prove real cross-user setup, duplicate/loss handling and worker inability to read secrets or staging; gad.8 installs mappings/accounts, downstream of source APIs.


## Launch-origin creation provenance clarification — 2026-10-05

09j admits only a new non-restored layout from the pinned authenticated Herdr
server. The root-installed canonical workspace ID is only a container on that exact
server birth/socket generation. Protected launch never calls workspace.create
(which starts an ungated shell in Herdr0.9.3), never selects a current/label/alias
container and never adopts its existing processes. layout.apply must create only
one explicit-bootstrap fresh tab/pane/child; missing/stale container refuses
without fallback. The original layout.apply response supplies the configured
workspace plus fresh tab/pane;
terminal and child PID are queried only for that exact pane on the same server,
then bound to independently observed kernel birth/UID/lineage and pidfd. Native
non-reuse/no-respawn guarantees are required, not inferred from a label or argv.
No focused/current/aliased/reused/restored target or worker-selected pane can
supply origin. Lost creation response keeps ownership uncertain, with no search,
adoption, repeated spawn or release. xz9 consumes this accepted origin rather
than rebuilding it from worker projections. Unsupported origin guarantees refuse.


## Result, evidence-fetch and finish amendment — draft, 2026-10-05

This amendment closes the public contracts left open by the bounded result JIT
plan. It awaits an independent amendment verdict; xz9.0 stays draft / needs_review.
Real child xz9.3 owns submit_result/evidence_fetch and their public consumers;
xz9.0 consumes it and owns finish/terminal and full endcap integration. Upstream
9c2 owns the missing scope-proof capability; no research-only task or controller
is introduced. Recovery, no-effect settlement and inbox signing/consumer work
remain tracked in xz9.0; installed drills remain xz9.1 and installation children.
Full services construction continues to refuse until its complete operation set
is implemented. A tested handler seam is not full-service readiness.

### Closed wire schemas and identities

All three operations retain the existing exact envelope
`{version: 1, operation, project_id, mutation_id, params}`. Unknown/extra fields
refuse. IDs use JournalMutation's 1–128 character identifier grammar; digests are
64 lowercase hex; head is the exact full candidate commit SHA; generations are
nonnegative integers. Mapping/project/assignment/attempt must resolve together.
No wire actor, role, repository path, caller-issued import artifact ID, cleanup
assertion or authority identity is accepted. evidence_fetch alone may select an
existing owner-issued canonical artifact_id; it cannot assign IDs or blob paths. Server derives role and native peer identity from the fixed
deployment and connection. Current project visibility is checked through the
injected existing Lab policy owner, including for replay and historical fetch.

| Operation | Exact params keys | Mutation ID / transfer |
|---|---|---|
| submit_result | mapping_id, assignment_id, attempt_id, expected_generation, candidate_generation, head, receipt_sha256, transfer | Required strict mutation ID; upload receipt_artifacts |
| evidence_fetch | mapping_id, assignment_id, attempt_id, kind, purpose_id, artifact_id | Must be null; download artifacts, exactly one selected artifact |
| finish | mapping_id, assignment_id, attempt_id, expected_generation, candidate_generation, head, result_id | Required strict mutation ID; no upload/download body |

ReceiptTransfer's existing descriptor schema, receipt-first framing, SHA256,
order, EOF/deadline and byte limits apply unchanged. submit_result accepts the
normal ExecutionReceipt fields, never a second receipt dialect. Its producer
must equal exactly `{actor: map.worker_actor, role: worker, runtime: herdr}` and
its attempt/project/assignment/scope/head must equal canonical origin/candidate.
Only the mapped owning worker may submit, with a live connection positively
descending from the recorded original worker PID/UID/birth and native launch
binding. Launcher/supervisor cannot upload on its behalf. Receipt metadata
cannot replace that check, including for a failed verdict.

### Submitted result identity, digests and output

Before normalization verify SHA256 of the original JSON bytes against
receipt_sha256 and the transfer descriptor, and verify the original
ExecutionReceipt digest using EvidenceDigest / digest_payload. A missing normal
receipt digest is computed by its existing owner; a supplied digest must match.
Call the computed value `original_receipt_digest`. Validate normal schema,
forbidden fields, binding, checks, operation and artifact declarations through
the existing ReceiptVerifier owner; separate result validation from terminal
acceptance authority. No synthetic trusted wire identity or accepted receipt
is used to make worker submission appear approved.

The authority generates one immutable result_id (32 lowercase hex) for the
first admitted result of an exact candidate generation. There is at most one
submitted result per attempt/candidate generation. Any fresh mutation ID trying
to submit again conflicts, whether content is identical or different. A later
candidate generation may submit a new result; old results are retained but
cannot finish the new candidate. Correcting any result requires submit_candidate
to admit a new generation, even if HEAD is unchanged, and fresh exact review
before successful finish. A fresh mutation ID never replaces a result in-place. An exact original mutation retry returns its
original result_id and reply without importing twice while the original worker
lineage is still live and the attempt remains active. submit_result replay after
worker exit or terminality fails closed with evidence_unavailable; it does not
relax worker authentication to same UID. Apply this admission and canonical
private-record verification outside JournalMutation's replay callback. Changed metadata/raw
receipt bytes/artifact bytes/order with that ID conflicts; the mutation input
digest covers the complete params including receipt and transfer digests.

Normalize artifact paths, in declared order, to owner-issued canonical
`evidence/imports/ARTIFACT_ID` references; recompute ExecutionReceipt digest
without the old digest/recorded_at, as for accept_review. Call this value
`receipt_digest`. `uploaded_receipt_sha256`, `original_receipt_digest` and
`receipt_digest` are distinct named values and never substituted for one another.
The private normalized receipt metadata and result binding are retained in one
new source-owned `result_submitted` event type in the existing EvidenceEvent
registry and attempt event chain, not in authority_mutation.data. Its exact
payload is `{version: 1, result_id, binding, uploaded_receipt_sha256,
original_receipt_digest, receipt_digest, receipt, artifacts}`. binding is the exact
object below; receipt is the normal normalized ExecutionReceipt.to_h; artifacts
is its identical ordered normalized array. IDs/digests must agree across all
fields; receipt binding and producer must match origin and binding; exactly one
such event may bind each result_id and candidate generation. No raw receipt JSON
bytes or terminal output are retained in this metadata. The private event,
artifact blobs/import events and sanitized public authority_mutation.data are
written in the same existing EvidenceJournal CAS. Fresh/replay public data is
exactly the projection below, never the private event or nested binding/receipt.
No second journal, storage controller or RPC reply store is created. Every fetch,
finish and submit replay validates this private event's chain, identity and
receipt digest, including with zero artifacts, before using its projection.
This commit emits no receipt_accepted or terminal transition.

The exact result binding hashed by CanonicalEvidence's binding_digest is
`{mapping_id, project_id, assignment_id, attempt_id, result_id, worker_uid,
worker_actor, launch_ticket, process_binding, head, candidate_generation,
uploaded_receipt_sha256, original_receipt_digest}`. process_binding is the full
canonical recorded native binding; values are owner-resolved. Result import
kind/role is result/worker; peer_uid is the authenticated worker;
request_id_or_event_id is result_id; candidate_generation_or_claim_generation
is the accepted candidate generation; admitted_after_event_digest is the last
canonical attempt event preceding this admission. Timestamp does not prove
lineage. Normalized receipt digest is deliberately outside the import binding
because its references contain the owner-generated artifact IDs.

Success data is exactly `{result_id, head, candidate_generation, verdict,
uploaded_receipt_sha256, original_receipt_digest, receipt_digest, artifacts,
generation, journal_commit}`; artifacts is the normalized ordered array of
`{path, sha256}`. Existing Server transport.replayed wraps this projection.
Result bytes and producer/native details are not public response fields.

Failed results with `artifacts: []` are admissible under normal receipt rules:
receipt part is still mandatory; there are zero following parts and zero import
descriptors. Persist the private result_submitted event and sanitized reply in the same CAS
rather than calling CanonicalEvidence.import_plan with an empty list or inventing
a placeholder artifact. For either verdict, every declared artifact must be
transferred and verified even though normal failed receipt validation does not
require an artifact. Succeeded still requires normal artifacts and executed
passed checks. A failed result does not assert no effect or cleanup.

Campaign-bearing receipts are refused with evidence_unavailable in protected
submit_result and accept_review for this slice. Never resolve CampaignManager
against journal_repository or worker-local .ace-local, or infer campaign approval
from an uploaded result. Ordinary independently executed review receipts remain
supported. Mandatory protected campaign integration is owned by existing R2 task
8x0.t.ig3 (consumed by R3/final qkc review-policy acceptance), whose amendment
requires the existing ace-review CampaignManager authority to resolve exact
campaign/repository/worktree/result identity and policy through a trusted owner
boundary. ig3 consumes xz9.0 canonical transfer/provenance and must close this
refusal before mandatory full-program review-policy acceptance. xz9.0 does not
depend on ig3 and cannot fall back to local campaign state. This bounded source
checkpoint is implementable without campaign support; it is not completion of
R2/R3 or the overall program.

### Purpose-filtered evidence fetch

kind is exactly result, review, service, inbox or observation. purpose_id is the
canonical result_id / review_id / request_id / event_id / observation event ID
for that kind. artifact_id selects one artifact already referenced by that exact
accepted/submitted record, never a caller path or journal commit. The owner
resolves the reference, producer peer UID, exact binding and generation from
canonical records, then reads descriptor and bytes from one current immutable
canonical commit with CanonicalEvidence. Historical candidate and terminal
attempt reads are allowed where retained purpose authorization below holds;
current head/liveness is not fabricated as historical evidence. Corrupt/missing
record, provenance, chain or bytes is evidence_unavailable; an unknown valid
purpose/artifact is missing. Fetch imports nothing and grants no effect/replay.

| Peer | Allowed raw kinds and purpose binding |
|---|---|
| Owning worker | result only, its own mapped attempt; live descendant of original worker binding |
| Assigned independent reviewer | review for the exact retained assigned review_id and result for that review's exact candidate; live descendant of its recorded reviewer process binding, not merely same UID |
| Recorded executor | service for its exact recorded request/executor UID, including terminal/historical completion evidence; no general result/review/inbox access |
| Mapped launcher | all kinds for an attempt whose recorded launcher identity exactly matches the live peer PID/UID/birth |
| Mapped supervisor | all kinds for its mapped project/attempt under current supervisor visibility |

Reviewer reassignment revokes the previous review-purpose fetch permission;
terminality/head advance alone does not. The current assigned review must still
name the retained candidate/result being fetched. Retained approval verification
for finish uses its admitted independent attribution, not live reviewer presence;
reviewer exit does not invalidate executed review evidence. Worker receives only
sanitized review/observation projections through existing status, never raw bytes.
Inbox and observation fetch refuse evidence_unavailable until their existing
canonical signer/observer owner supplies the complete exact bound provenance;
there is no permissive generic project-visible reader.

Success data is exactly `{descriptor, generation, journal_commit, transfer}`
plus one artifacts transfer part. transfer is the existing TransferCodec
descriptor `{version: 1, bytes, sha256, parts: [{bytes, sha256}]}` generated by
Server from the one returned part using fixed artifacts purpose. Its aggregate
and sole part bytes/sha256 must equal the canonical descriptor bytes/sha256;
For evidence_fetch, Client.call validates the closed canonical descriptor
and its equality to the one-part data.transfer before calling receive; then
reads data.transfer using the existing codec with download: true and
purpose: :artifacts. This source-owned operation-specific consistency check is
part of xz9.3 Client integration, not reliance on example code after bytes
have already escaped the client. A missing, extra-part or mismatched transfer descriptor fails
evidence_unavailable before the client exposes bytes; no alternative framing. descriptor contains the existing exact
CanonicalEvidence.DESCRIPTOR_FIELDS (including version); its length/SHA256 binds
the one download part. generation is current canonical authority_generation;
journal_commit is the immutable read commit. No null descriptor, empty synthetic
artifact, caller-selected order, history ref or mutation ID is supported.

### Canonical result discovery through existing attempt_status

xz9.3 extends the source-owned services-composition projection of existing
attempt_status, not a new operation/listener/journal. In services composition
its exact params are `{mapping_id, assignment_id, attempt_id,
result_candidate_generation}`; mutation_id must be null and no transfer/body is
allowed. result_candidate_generation is null for the latest canonical candidate
or a nonnegative integer selecting an already admitted retained candidate
generation (including same-head replacements). Launch-only composition retains
its existing launch-status product schema and exposes no result projection.
The normal source composition attaches the trusted canonical result projection
to LaunchLifecycle's existing status owner; Router must retain exactly one
attempt_status route. No caller selects an adapter or private record reader.

Authenticate current project visibility and live mapped principal before any
result discovery. Exact recorded launcher incarnation and mapped supervisor may
discover current or retained attempt results even after worker exit or terminal
attempt; they need not revive the worker. Owning live worker may discover only
its own attempt results under original descendant binding. Current assigned live
reviewer may discover only a result for its exact assigned candidate/process
purpose, with reassignment revoking old access. Executor cannot discover result
metadata through this projection. These conditions are the same family purpose
rules as fetch; neither status nor result discovery permits effects or cleanup.

Retain normal role-filtered launch status fields, and add exactly
`{result_candidate_generation, submitted_result, authority_generation}`.
journal_commit is the one immutable read commit for launch/result projection;
authority_generation is current JournalMutation.authority_generation from that
commit, suitable for next expected_generation, never the historical result
admission generation. result_candidate_generation is the resolved selected
candidate generation, or null if no candidate has been admitted for latest.
submitted_result is null if that known candidate has no admitted result;
otherwise exactly `{result_id, head, candidate_generation, verdict,
uploaded_receipt_sha256, original_receipt_digest, receipt_digest, artifacts}`.
artifacts is the ordered normalized `{path, sha256}` array (zero entries allowed).
artifact_id is obtained by stripping the fixed evidence/imports/ prefix from
path; no new identifier or filesystem lookup is needed. Existing launch fields
may expose native details only to their already authorized launcher/supervisor;
submitted_result never contains private receipt, producer or process_binding.

Resolve this projection from the unique verified private result_submitted record
at the selected commit, not authority_mutation's cached reply alone. Revalidate
normal receipt digest, exact private binding, candidate lineage and each import
provenance/blob; zero-artifact results still validate the full private record.
Missing syntactically valid attempt or explicitly selected nonexistent candidate
is missing; malformed selector/mutation/body is invalid_input; denied peer or
visibility is unauthorized; corrupt/duplicate/missing referenced record, chain,
provenance or blob is evidence_unavailable, never submitted_result null.
No submitted result is an ordinary null only when canonical absence is provable.
Responses retain existing 16 KiB bound and transport.replayed false; one selected
result avoids an unbounded history list. Failure to fit refuses without partial
private disclosure. A lost submission reply followed by worker exit does not
require a retry: supervisor/launcher discovers the committed result here, fetches
its artifacts and later references result_id for finish once 9c2 is available.

### Concrete client and consumer surface for xz9.3

The public surface of this child is existing Authority::Client.call, not a new
CLI. Client.new(mapping_id:) resolves installed project/socket/credentials;
call injects mapping_id/project_id and upload transfer descriptor. Callers pass
ordered local receipt/artifact byte strings via upload_parts and fixed
purpose :receipt_artifacts; no local upload path crosses the wire. Discovery
calls attempt_status with null mutation ID and the selector above. Fetch calls
evidence_fetch with download: true and purpose :artifacts; Reply.parts supplies
the one verified blob and Reply.data the sanitized descriptor/projection.

xz9.3 owns Client/Server download integration, generic Endcap result/fetch and
LaunchLifecycle's single trusted services status projection, plus actual public
Client consumer tests/examples. Existing CLI attempt finish (--receipt FILE)
and attempt evidence (--receipt-digest, check/review purpose) are not silently
reinterpreted as these result APIs. Their protected coordinator/driver routing
and terminal receipt acceptance remain xz9.0 responsibilities; local explicit
mode stays separate and an unavailable protected owner must never fall back.
No CLI command/flag is introduced by xz9.3; its direct client surface is complete
and independently usable without finish. Public runnable examples are in the
xz9.3 ux/usage.md and apply only after this draft's implementation/review.

### Finish admission, cleanup and replay

finish references the immutable result_id; it never uploads a second receipt or
uses a bearer result token. Only the exact live recorded launcher incarnation or
mapped live supervisor may call. Owning worker/reviewer/executor may not finish.
Resolve the verifier identity from that authenticated mapped peer through the
existing ExecutionIdentityResolver trusted coordinator/service authority; the
producer remains the result's worker. Do not let actor strings choose authority.

Under exclusive existing task+assignment lifecycle exclusion, each normal
expected-generation CAS attempt resolves current canonical state, exact result,
current head/candidate generation and all referenced provenance/bytes again.
Revalidate the normalized receipt/digest with ReceiptVerifier's canonical reader
and, for succeeded, the current candidate's existing approved_review!
independent review. Failed finish follows the existing normal failure-receipt
semantics: it requires exact attributable worker failure binding/checks/artifacts
and the same settled effects, inboxes and positive no-writer proof, but does not
require a successful approved review. Missing or rejected independent review
cannot make a failed receipt authorize success or another effect. Any already
accepted review is reverified as retained evidence where referenced; no fabricated
approval is added when review is unavailable. Embedded worker review metadata
never supplies successful approval. A valid failed receipt plus all independent
cleanup conditions can terminalize failed through this same finish route, avoiding
a permanently held failure with no settlement route. External
operations keep all existing additional normal verifier/coordinator restrictions.
Campaign receipts remain refused. A stale result/head/generation conflicts.

Finish is eligible only for running canonical bound/issued attempts. Reserved,
stopped, uncertain or already terminal attempts cannot freshly finish. Every
service request for this attempt must be canonically succeeded or failed-settled:
requested/claimed/issued/uncertain/failed, missing/corrupt completion evidence or
outstanding no-effect challenge blocks admission. Reverify terminal service
provenance using its existing owner; a failure exit/timeout is not no-effect.
Every bound inbox must have its exact current signed consumer reconciliation
accepted by existing Inbox/Herdr and recorded canonically; pending/missing or
unverifiable inbox binding blocks admission. An attempt with no service requests
or inbox bindings needs no invented empty proof.

Worker may submit while alive, then exits. Before terminal admission the
existing LaunchLifecycle owner supplies its exact recorded origin/child birth
and pidfd observations, but these prove only original-child state, not the
absence of all descendant or externally spawned writers. Genuine upstream draft
8x4.t.9c2 owns the missing trustworthy exact execution-scope no-writer capability,
extracted from xz9.2. It depends on 09j, never on xz9.0 or xz9.2; both children
consume it. The native containment mechanism and installer topology are not yet
selected. Current 09j source, an empty process group/subtree or pane disappearance
do not satisfy it; accessible native/external spawner creation must be prevented
or exhaustively bound into the same exact scope before emptiness is meaningful.

Until 9c2's independently reviewed contract and implemented proof are available,
finish must refuse evidence_unavailable, preserve ownership and remain incomplete.
Result submission and authorized fetch are independently implementable; positive
terminal finish acceptance is blocked, never simulated by a trusted boolean or
mock no-writer response. Once selected, finish consumes that owner's exact scope,
native origin, incarnation, closed-to-new-writers state and independently observed
no-writer evidence under the same exclusive lifecycle/CAS boundary. No worker,
caller timestamp, service outcome or original PID absence supplies that proof.
Finish does not kill the worker or run an effect. Restart must reestablish the
same scope proof or refuse; missing handles/unsupported/unreadable proof requires
existing recovery inspection, never guessed absence or abort's pre-execution proof
for an issued launch. Each CAS retry revalidates proof against exact current
scope/origin and no fresh claim is admitted while the boundary is held.

One durable existing journal CAS includes normal receipt_accepted with the
normalized worker receipt, the legal succeeded/failed transition and finish
mutation reply. Submitted-result blobs are retained and referenced, not imported
again. Canonical terminal truth releases scope/reservation through existing qjl
active-attempt semantics. Cache/store projection happens only after commit and
is reconstructible; crash before commit retains ownership, crash after commit
cannot resurrect it or accept/release twice.

Success data is exactly `{attempt_id, result_id, head, candidate_generation,
receipt_digest, state, generation, journal_commit}`; state equals the admitted
normal receipt verdict. Exact same-ID retry validates current mapped peer and
visibility plus retained result/accepted provenance outside the replay callback,
then returns the original committed reply even after worker/reviewer exit,
terminality or later head advance. It must not rerun cleanup or require the worker
to be live. Changed parameters with that mutation ID conflict. Any new finish
mutation ID for a terminal attempt conflicts, including same result. A replay
whose canonical evidence is now unverifiable returns evidence_unavailable,
never a success cached solely in the filesystem.

### Error and verification contract

Reuse Server errors: malformed schema/framing/ID/null rule is invalid_input;
wrong role/native incarnation/project visibility/purpose is unauthorized; stale
generation/candidate, duplicate fresh result or terminal finish is conflict;
unknown syntactically valid identity is missing; unverifiable evidence, receipt
rejection or unproven process/effect/inbox cleanup is evidence_unavailable.
Refusal records no terminal acceptance, frees no scope and removes private upload
spool. Public reasons are bounded/sanitized and contain no raw artifact content.

xz9.3 acceptance must execute the result/fetch scenarios below; xz9.0 owns
finish/terminal integration scenarios and consumes that verified result. Use real
Git ref/blob/event-chain and JournalMutation
CAS tests for original versus normalized digests, ordered multi-artifact imports,
failed zero-artifact result, private metadata exclusion from fresh/replay replies,
one-result-per-generation and same-head new-generation correction/fresh review,
submit replay after worker exit fails closed, exact/changed-ID replay,
forged producer/process/native binding, stale result/current review, campaign
refusal, all fetch peer/purpose cases and current visibility revocation. Delete
private caches and restart readers; corrupt descriptor/blob/chain and prove no
fallback. Test live submitted worker then positively cleaned worker finish;
failed receipt with unavailable/rejected review still settles only after all
independent cleanup conditions; missing handle, surviving descendants or external
spawner writers, pending/failed service, no-effect challenge
and unreconciled inbox must preserve ownership. Compete finish with claim/begin
under real lifecycle locks and CAS retry; fault before ref update and after commit
before reply; independently inspect accepted receipt and terminal event in the
same commit. Test consumer routing has no caller-local protected fallback.
Use bin/ace-test / bin/ace-test-suite, then independent exact-source verdict.
Injected exact-child observations may test refusal mechanics but cannot prove
positive scope cleanup. 9c2 must provide actual scope-owner source integration
and installed no-writer acceptance before positive finish completeness. Real installed
multi-UID/native acceptance remains separately required before full-service claims.


Round-2 verification additions for xz9.3: execute real Client upload, status and
download against source Server/Router/canonical Git (not handler-hash assertions).
Drop reply after committed submit then let original worker exit; authorized
supervisor discovers result/ordered artifact IDs, fetches exact bytes after
reader restart/cache deletion. Test no result null vs missing selected generation,
corrupt private record/import/blob, exact historical generation, reassigned
reviewer, executor/wrong launcher/current revocation denial. Test generated
multipart download descriptor equals canonical descriptor and malformed/missing/
mismatched data.transfer never exposes bytes or private fields. Zero-artifact
status and fresh/replay sanitized reply remain bounded and leak-free.
