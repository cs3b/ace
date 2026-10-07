---
id: 8wr.t.qk0
status: draft
priority: high
created_at: "2026-09-28 17:42:14"
estimate: large
dependencies: [8wq.t.k86, 8wr.t.qjl, 8wr.t.qjx, 8wr.t.qjy, 8wq.t.1w5, 8wm.t.vs2, 8wr.t.qjz, 8x3.t.xz9.2]
tags: [lab-readiness]
bundle:
  presets: [project]
  files: [ace-overseer/lib/ace/overseer/molecules/lab_client.rb, ace-overseer/lib/ace/overseer/cli/commands/work_on.rb, ace-overseer/lib/ace/overseer/organisms/status_collector.rb, ace-overseer/handbook/workflow-instructions/overseer.wf.md, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/protected-inventory-contract.md]
  commands: []
needs_review: true
title: Coordinate responsive overseer roles without the legacy Lab engine
position: 6o000e
---

# Coordinate responsive overseer roles without the legacy Lab engine

## Behavioral Specification

### User Experience

Kapitan can talk continuously to a project or Lab overseer, inspect progress and redirect work while delegated agents execute attributable assignments.

### Expected Behavior

- Canonical generic project-overseer, Lab-coordinator and second-commander charters ship in ACE. lab-overseer:gc0 and lab-config:gad.5/nfe adopt/configure them only. No duplicate domain-owned generic role instructions.
- On each wake inspect both task/assignment queue and scoped pending HITL. Project overseer handles local technical coordination; unresolved capability/scope is escalated to Lab overseer, then second commander/Captain via explicit proposal policy. Failed callbacks stay visible with attempts; no silent loss or retry loop.
- Coordinator delegates bounded implementation/review/service work rather than occupying the conversation with long-running tests or blocking sleep. New Captain direction is accepted and reflected in scope/task state; running conflicting work is stopped at a safe boundary with evidence.
- Remove LabClient, absolute /usr/local/bin/lab shell-outs, runtime=lab branch and Work-ID command interfaces. runtime now identifies terminal backend only (tmux/herdr/auto), independently of project/agent/service selection. Preserve task/assignment-based work-on and status.
- Public projects/agents inventory consumes ace-lab; work-on uses reviewed task plus assignment/runtime; review dispatch consumes independent review contract; stop preserves evidence/worktree; prune requires accepted completion plus verified preservation and no surviving writers.
- Status reports per task/assignment: current step, active attempt, verified liveness, blocker/decision deadline and evidence references. Never call unknown state complete or infer review acceptance from green CI. Progress is a projection of assignment authority.
- Respect configured per-project concurrency limits and max four active panes per tab. Close work pane/tab on accepted completion; preserve uncertain work and protected worktrees. No accumulating tabs merely for future queued work.

### Interface Contract

`ace-overseer work-on --task REF --project PROJECT --agent ID --runtime herdr`; `ace-overseer status [--project PROJECT] --format json`; `ace-overseer stop --assignment ID`; `ace-overseer review --assignment ID --pr REF`; `ace-overseer prompt --assignment ID --file FILE`; `ace-overseer prune --assignment ID --dry-run` and explicit apply. Existing local work-on remains valid with configured defaults. Removed --work/runtime=lab forms fail with clear usage, no forwarding shim.

### Success Criteria and Verification Plan

- [ ] SC1: Controlled source integration exercises brief -> delegated assignment -> status/chat steering -> independent review -> scoped merge -> accepted cleanup through the runtime and protected Assign APIs, without LabClient or lab binary/socket. Exercise real coordinator/consumer composition with deterministic external boundaries; fixture success does not prove installed native behavior.
- [ ] SC2: Failure cases: requester dead, unavailable service, changed head, unknown liveness, reviewer=author, late scope change, all slots busy; status remains accurate and conversation responsive.
- [ ] SC3: Run `ace-test ace-overseer all` and relevant assignment/runtime suites; fresh consumer loads canonical role workflows and cannot reach old LabClient.

### Scope and Ownership

Owner: **ace-overseer**. Consumers/boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: `8wq.t.k86`, `8wr.t.qjl`, `8wr.t.qjx`, `8wr.t.qjy`, `8wq.t.1w5`, `8wm.t.vs2`, `8wr.t.qjz`, `8x3.t.xz9.2`. Canonical cross-repository program: lab-config:`8wl.t.gad`. External gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown authority is an error, never permission. Executed tests and independent current-head review gate delivery; CI is advisory. Spec readiness is not installed acceptance.

### Provenance and Invalidated Assumptions

New generic charter and Lab-engine consumer migration. k86 owns terminal adapter replacement only; this task owns removal of the separate legacy Lab engine and role coordination.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.

### Completion versus integrated acceptance

Task delivery proves implemented role/workflow/CLI composition, executed deterministic integration checks with qjx-conforming service fixtures and controlled merge boundaries, plus independent source review. The sole installed acceptance owner is lab-config:`8wl.t.gad.2`, checklist `qkb-delivery / WORKFLOW`, with `9c2-scope / SCOPE` for surviving-writer proof. That row already requires responsive coordinator, live runtime, Captain steering, exact accepted SHA and cleanup. It remains unchecked until actual installation and exercise. qkc owns executable acceptance scenarios; gad.2 executes them against the installed system. Neither qkb/gad.b/gad.2 completion nor missing installed evidence blocks this source deliverable; unfinished prerequisite source APIs still do.

### Protected steering prerequisite discovered during implementation planning

`8x3.t.xz9.2` owns protected prompt/stop through the existing canonical Assign
authority and mapped native driver. qk0 consumes those public owner APIs; it
does not derive authority from a pane name, raw PID, runtime.send or Ctrl-C.
Prompt submission is distinct from native consumption. Stop preserves uncertain
descendant writers and unsettled service effects, and does not authorize prune.
Protected steering acceptance requires that child; ordinary local mode does not
substitute for it. This explicit prerequisite returns qk0 to draft/needs_review
for a narrow independent readiness amendment. The dependency runs from qk0 to
xz9.2, never back to qk0/qkb from the owner capability.

### Readiness amendment — 2026-10-07

The Captain selected the original-attempt-terminal guarantee in xz9.2. A prompt acknowledgment means `submitted` to the captured, unchanged terminal/runtime with its original spawn guard; it never means agent consumption. Replacement before admission has zero effect. Lost acknowledgment, partial write or uncertain completion remains visible and is not automatically resent. Stop requests consume the canonical owner API and require exact whole-scope writer proof plus service/inbox settlement before reporting stopped; otherwise report uncertain and retain the worktree. This amendment remains draft/needs_review until independent readiness review; it does not declare xz9.2 implemented. Historical installed wording is preserved in `history/before-central-acceptance-amendment-2026-10-07.md`.

### Foreground launcher consumer — proposed source contract

The configured launcher-role overseer runs with the exact UID/GID/groups selected by the protected mapping. It starts and retains the original `ace-assign` launcher as a foreground child; it does not detach it or replace its identity with a new process. lab-config:gad.8 provisions the account and mapping, gad.b owns service startup ordering, and gad.9 owns the Pi/domain role integration. qk0 owns the generic child lifecycle and readiness consumer. These are downstream consumers of xz9.2, never reverse dependencies of that producer.

On successful original launch, xz9.2 flushes exactly one JSON readiness line, bounded at 16,384 bytes, with fields `version: 1`, `type: "launch_ready"`, `mapping_id`, `assignment_id`, `attempt_id`, `generation`, `journal_commit`, and `original_binding_digest`. qk0 reads that line with a bounded deadline and verifies its complete shape and exact selected task/assignment/mapping binding before reporting the child ready. The generation and journal commit must resolve to the accepted original binding through Assign; self-reported fields alone confer no authority. The same child remains in the authenticated control loop; stdout is not a polling/event stream. Dry run, refusal or replayed reservation cannot produce a new original-ready transition.

qk0 retains child wait/cancel ownership after readiness and keeps the conversation responsive. Transient control-channel loss is visible and can reconnect only through the same original launcher process; it never resends a prompt or substitutes a new PID. Process loss is reported as uncertain until canonical recovery resolves it. Cancellation uses the canonical inhibit/settlement protocol; killing only the worker unit or receiving EOF is not evidence that the launcher and native input queues are drained. Missing, malformed, oversized, mismatched or late readiness never authorizes work and is reconciled against Assign before cleanup or another launch.

SC1/SC2 include controlled consumer composition for valid readiness, each refusal above, retained child exit, transport reconnect without prompt replay, and cancellation with an unresolved native outcome. The producer/consumer contract must be checked against xz9.2's final source interface before promotion. This amendment adds no delivered capability and leaves `draft`, `needs_review: true` unchanged.

Independent scoped review (wave_5h5, 2026-10-07): APPROVE this amendment and usage. The original Assign binding remains the authority; child ownership, uncertainty, and dependency direction are explicit. Before snapshots are byte-identical to the previous committed spec and usage. `ace-task show` confirms unchanged draft metadata; diff validation passes. This is not whole-task readiness or implementation acceptance.

### Protected status and restart discovery — draft amendment

`protected-inventory-contract.md` defines the missing owner enumeration and the overseer consumer within SC1/SC2: authorized discovery from a single retained canonical revision, bounded continuation, accepted task/scope associations, and explicit unknown/unavailable status. Inventory is not liveness or permission to mutate. Review this amendment independently before promotion; the earlier scoped foreground-launch approval does not cover it. No dependency is added to xz9.2.
