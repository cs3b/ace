---
id: 8wr.t.qjl
status: in-progress
priority: high
created_at: "2026-09-28 17:41:47"
estimate: TBD
dependencies: []
tags: [ace-assign, lab-readiness]
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/molecules/assignment_manager.rb, ace-assign/lib/ace/assign/molecules/evidence_calculator.rb, ace-assign/handbook/workflow-instructions/assign/drive.wf.md]
  commands: []
needs_review: false
title: Persist assignment attempts and exact execution evidence
position: 6o0003
worktree:
  branch: qjl-persist-assignment-attempts-and-exact-execution-evidence
  path: .ace-wt/ace-t.qjl
  created_at: "2026-09-28 20:03:47"
  updated_at: "2026-09-28 20:03:47"
  target_branch: main
---

# Persist assignment attempts and exact execution evidence

## Behavioral Specification

### User Experience

An operator starts a scoped attempt for an assignment and can reconstruct its accepted state and evidence after losing the terminal session. Task definitions own goals; assignments alone own execution.

### Expected Behavior

- An attempt binds an immutable attempt ID to assignment, step/subtree, project, authenticated actor/role, runtime identity and base_head at start. The deliverable candidate_head is pinned when submitted for review/effects; changing it invalidates prior candidate evidence and authorizations. base_head never masquerades as candidate_head. IDs use ACE's existing generator. Only one active attempt owns a subtree; a duplicate start returns that attempt or a conflict, never launches a second writer.
- Record state transitions reserved -> running -> succeeded/failed/stopped/uncertain. A stop is not success. User/agent prose and exit 0 alone never establish succeeded. An outcome needs the attempted operation, exit receipt, required artifact and checks for that step.
- Keep canonical non-secret execution/<assignment-id> journals/checkpoints in a separate configured evidence Git ref (default refs/ace/execution) and isolated audit checkout, outside the deliverable candidate branch. Link records to the source task ID. Record journal_commit separately from base_head and candidate_head; accepting/committing evidence must never advance or exempt changes to the reviewed candidate. .ace-local/assign retains disposable session/log data and projections. Only the trusted coordinator/service identity writes accepted evidence; serialize ref updates to preserve concurrent attempts. Do not commit terminal bytes. Before an external side effect, durably record its intent; after it, durably record receipt. Lost receipt after a possible effect becomes uncertain.
- Existing assignment/step state commands and the new attempt surface read one authority. For taskless assignments, local durable state under .ace-local/assign is supported, but must be attached to a task before managed Lab delivery; this path must never claim Git-backed recovery.
- Evidence records identify producer, actual tested/reviewed head, scope, verdict and artifact digest. Review approval requires an executed independent reviewer verdict for the current head, not merely existence of a report. Terminal feedback is derived, never hardcoded. Publication is not a prerequisite for merge.
- Only the coordinator or scoped service owning a transition can accept authoritative receipts; workers submit attributable results for verification and cannot self-approve review or privilege. OS enforcement is supplied by service executors, not by trusting role names in input.
- Reconciliation verifies process identity, head and receipts before resolving uncertain. No automatic retry of a potentially completed merge/publish/deploy. Immutable accepted history survives new attempts; terminal old attempts cannot receive new effects.

### Interface Contract

New public commands: `ace-assign attempt start --assignment ID --step STEP --project ID`; `ace-assign attempt status --assignment ID --format json`; `ace-assign attempt finish --attempt ID --receipt FILE`; `ace-assign attempt reconcile --attempt ID --receipt FILE`. Actor identity is derived from the execution boundary, never granted by flags. JSON exposes attempt ID/state/binding and references/digests, no credentials. Existing `ace-assign status` includes active attempt, base_head, candidate_head, evidence_git_ref, journal_commit and unresolved effects. Managed attempts use the configured evidence ref; missing/unwritable evidence storage blocks an external effect before submission.

### Success Criteria and Verification Plan

- [x] SC1: Commit an accepted receipt and prove candidate_head is unchanged; reject changed candidate SHA even for task-only edits. Start and inspect one real local task assignment; repeated start and concurrent start cannot create competing active attempts.
- [x] SC2: Restart after intent write, after process start and after effect completion before receipt: classify accurately and never replay automatically.
- [x] SC3: Reject wrong actor/project/attempt, stale head, fabricated report-only approval, same author/reviewer and changed artifact digest.
- [x] SC4: Run `ace-test ace-assign all`; extend existing assignment persistence/evidence tests with real filesystem crash/reload cases and one public CLI recovery scenario.

### Scope and Ownership

Owner: **ace-assign**. Consumers and boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only, not implementation or deployment.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: none. Canonical cross-repository program: lab-config:`8wl.t.gad`. External acceptance gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown identity/authority is an error, never permission or success. Executed tests plus independent current-head review gate delivery; CI is advisory. Spec readiness is not proof of installed behavior.

### Provenance and Invalidated Assumptions

New uncovered deliverable. Existing EvidenceCalculator treats a current report as a receipt and hardcodes terminal feedback; those are explicitly insufficient. This task replaces that interpretation. No new Work/W/A engine, no SQLite, no old-ID compatibility. Domain deployment remains lab-config.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. The approved 2026-09-28 specification supersedes conflicting earlier requirements. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.
