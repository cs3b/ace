---
id: 8wr.t.qjz
status: done
priority: high
created_at: "2026-09-28 17:42:13"
estimate: TBD
dependencies: [8wm.t.vs2, 8wr.t.qjx, 8wr.t.qjy, 8x4.t.5qv, 8x4.t.6yk]
tags: [lab-readiness]
bundle:
  presets: [project]
  files: [ace-hitl/lib/ace/hitl/lifecycle/store.rb, ace-hitl/lib/ace/hitl/lifecycle/effects.rb, ace-hitl/lib/ace/hitl/lifecycle/kinds.rb, ace-overseer/handbook/workflow-instructions/overseer.wf.md]
  commands: []
needs_review: false
title: Resolve second-commander proposals with a sixteen-hour veto window
position: 6o000c
---

# Resolve second-commander proposals with a sixteen-hour veto window

## Behavioral Specification

### User Experience

Second commander proposes a precise action with context/options/recommendation. Kapitan can answer early; absent a reply for 16 hours after confirmed delivery, the exact proposal is authorized and can be executed through its scoped service.

### Expected Behavior

- Add an explicit proposal decision kind; ordinary questions, verification and OTP never inherit a timeout approval. Every precisely presented proposal is eligible, including publishing, deployment and access changes (Captain decision 2026-09-28); do not silently narrow this to pre-existing mandate.
- Proposal captures immutable revision, project/assignment/attempt, exact operation/target candidate_head or artifact digest/input digest (separate from base_head and journal_commit), context, options, recommendation, rationale and technical prerequisites. Time starts at transport's confirmed submission acknowledgement, not record creation or assumed Captain reading. A failed or uncertain notification cannot arm the deadline.
- Deadline is delivered_at + 16 hours in persisted UTC. Earlier explicit approval authorizes immediately; veto denies. A reply requesting clarification or changing scope stops automatic execution and requires a revised proposal with a fresh acknowledged delivery and window.
- Changing target version/head/input or proposed access scope creates a new revision and resets the full window. Technical checks becoming stale block execution; they never transform the original authorization into permission for changed work.
- Atomically resolve answer-vs-deadline races. A reply durably received by the transport before deadline takes precedence; after deadline, consume y24 `ace-hitl-hermes ingress reconcile --request ID --through DEADLINE --format json` and its monotonic checkpoint/received_at evidence before resolving. Reconcile acknowledgement and correlated reply ingress under the single decision transition boundary so no already received reply can be skipped. If transport health/backlog cannot be established, defer timeout resolution until reconciliation proves no earlier reply. A late veto before effect claim cancels execution; after claim, stop only remaining safely stoppable work and record that an already performed effect cannot be undone by rewriting history.
- States expose proposed, awaiting-delivery, awaiting-decision, approved-explicitly, approved-by-silence, denied, superseded, executing, succeeded, failed, uncertain. One revision gets one effective authorization. HITL owns only proposal/authorization resolution; executing/succeeded/failed/uncertain are read-only projections of qjl assignment operation claims and qjx receipts. The sole effect claim and execution journal belong to ace-assign; do not create a second executor in HITL. Resume preserves deadlines and never automatically resends a potentially executed effect.
- Expiry evaluator is a deterministic command invoked by the living overseer's loop/watch and on restart. No separate scheduler service. Restart after missed deadline reconciles once, applies same checks and does not replay ticks.
- Authorization does not bypass independently executed tests/review/current head or conjure credentials/OTP. Services enforce their technical scope. Six-digit OTP remains an ephemeral input to one exact operation, requested only when needed by publisher and absent from learned history.
- Durable sanitized decision history stores context/options/proposal, Captain answer and provided rationale, resolution and actual outcome. Missing rationale stays missing (never fabricate it). Second commander retrieves relevant prior decisions; automatic model training, policy expansion or shortening 16h is out of scope.

### Interface Contract

`ace-hitl proposal create PROPOSAL_ID --assignment ID --attempt ID --project ID --file PROPOSAL`; `ace-hitl proposal show ID --format json`; `ace-hitl proposal resolve-due --project ID [--now UTC]` (clock override limited to test fixtures, production uses trusted clock); `ace-hitl proposal revise ID --expected-revision N --operation-id REVISION_OPERATION_ID --file PROPOSAL`. Telegram Reply performs approve/veto/clarify with exact revision correlation. Creation returns persisted proposal/revision/request IDs and current delivery state immediately, including when transport is unavailable. delivered_at and deadline remain absent until confirmed submission acknowledgement; show exposes them afterward. Executor consumes the resulting immutable authorization through ace-lab service request.

### Success Criteria and Verification Plan

- [x] SC1: Fake-clock lifecycle tests: before/exactly/after 16h, early approval/veto, revised proposal, delivery failure, restart, reply-ingress race, late veto, duplicate wake and uncertain effect.
- [x] SC2: Tests assert every operation class, including privilege expansion and deployment, can be authorized by silence while mandatory technical gates still reject invalid execution.
- [x] SC4: Revision operations require stable identity plus an expected source revision. Lost response and crash retries after delivery, approval or a later revision return the previously committed revision without another request, supersession or deadline reset; changed proposal/source/content/caller bindings fail. Concurrent revisions and concurrent old-effect claims have one canonical authority winner. Initial creation reports awaiting-delivery without waiting for transport.
- [x] SC5: Requester show/history and proposal request reads require current project authority; revoked projects disappear from history and direct reads refuse. Generic lifecycle create rejects proposal kind without persistence. Ordinary questions retain their character bound. Lab status preserves output and visibly reports deferred ticks, including JSON consumers.
- [x] SC3: Run `ace-test ace-hitl all` and `ace-test ace-overseer all`; installed controlled 16h scenario survives restart and produces one authorization/receipt with no manual queue injection.

### Scope and Ownership

Owner: **ace-hitl policy; ace-overseer decision role**. Consumers/boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: `8wm.t.vs2`, `8wr.t.qjx`, `8wr.t.qjy`. Canonical cross-repository program: lab-config:`8wl.t.gad`. External gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown authority is an error, never permission. Executed tests and independent current-head review gate delivery; CI is advisory. Spec readiness is not installed acceptance.

### Provenance and Invalidated Assumptions

New capability absent from previous HITL transport work. This spec intentionally changes the general no-timeout policy only for this explicit proposal kind.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.

### Review repair public contract clarification

Initial creation requires caller-persisted stable `proposal-[0-9a-f]{24}` identity.
Retry accepts only exact caller, assignment, attempt, project and content binding.
Canonical Assign evidence commits an immutable prepared lifecycle request before
projection; exact retry and the existing authenticated transport pending scan
recover crashes and uncertain commits without blind deletion or orphan requests.

`resolve-due --project` is an authenticated proposer wake, returning
`queued-for-transport`. The existing Hermes runtime loop under its actual
transport principal performs reconciliation only after post-poll coverage proof.
Wake is idempotent and never carries approval authority. Proposer role does not
inherit transport admission; no new daemon, executor or journal is introduced.
Transient tick failure preserves watch/status and future retries.

Earlier unresolved same-request ingress blocks later approval; canonical history
deduplicates exact sequence/content/time and rejects changed duplicate evidence.
An unseen lower sequence is not a duplicate. Hermes metadata excludes raw bodies.
These public changes require independent readiness/source review before acceptance.

Revision requires `--expected-revision N` and a caller-persisted `--operation-id
revision-<24 lowercase hex digits>`. Operation IDs are unique across proposals
in the canonical journal. Persist the tuple of proposal ID, source revision,
operation ID and exact file before invocation. Exact retry returns that operation's
committed revision in its current historical state, even after delivery, approval,
or a subsequent revision. Changed binding is refused. A new operation with a
stale source is refused. Prior supersession and new prepared revision commit
atomically in the existing Assign CAS; unresolved effect claims exclude revision
at that same owner boundary. No retry resets delivery or mutable lifecycle state.
