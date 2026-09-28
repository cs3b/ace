---
id: 8wr.t.qjz
status: pending
priority: high
created_at: "2026-09-28 17:42:13"
estimate: TBD
dependencies: [8wm.t.vs2, 8wr.t.qjx, 8wr.t.qjy]
tags: [lab-readiness]
bundle:
  presets: [project]
  files: [ace-hitl/lib/ace/hitl/lifecycle/store.rb, ace-hitl/lib/ace/hitl/lifecycle/effects.rb, ace-hitl/lib/ace/hitl/lifecycle/kinds.rb, ace-overseer/handbook/workflow-instructions/overseer.wf.md]
  commands: []
needs_review: false
title: Resolve second-commander proposals with a sixteen-hour veto window
position: 6o000e
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

`ace-hitl proposal create --assignment ID --attempt ID --project ID --file PROPOSAL`; `ace-hitl proposal show ID --format json`; `ace-hitl proposal resolve-due [--now UTC]` (clock override limited to test fixtures, production uses trusted clock); `ace-hitl proposal revise ID --file PROPOSAL`. Telegram Reply performs approve/veto/clarify with exact revision correlation. Creation returns proposal/revision/request IDs, delivery state and deadline only after acknowledgement. Executor consumes the resulting immutable authorization through ace-lab service request.

### Success Criteria and Verification Plan

- [ ] SC1: Fake-clock lifecycle tests: before/exactly/after 16h, early approval/veto, revised proposal, delivery failure, restart, reply-ingress race, late veto, duplicate wake and uncertain effect.
- [ ] SC2: Tests assert every operation class, including privilege expansion and deployment, can be authorized by silence while mandatory technical gates still reject invalid execution.
- [ ] SC3: Run `ace-test ace-hitl all` and `ace-test ace-overseer all`; installed controlled 16h scenario survives restart and produces one authorization/receipt with no manual queue injection.

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
