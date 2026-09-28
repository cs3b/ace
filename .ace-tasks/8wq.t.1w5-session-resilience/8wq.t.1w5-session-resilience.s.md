---
id: 8wq.t.1w5
status: pending
priority: medium
created_at: "2026-09-27 01:15:43"
estimate: TBD
dependencies: [8wr.t.qjl, 8wq.t.k86, 8wm.t.y23]
tags: [session, resilience]
position: 6o000c
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb, ace-herdr/lib/ace/herdr/organisms/tidy.rb, ace-overseer/lib/ace/overseer/organisms/status_collector.rb]
  commands: []
needs_review: false
title: Resume attributable agent work after process or session failure
---

# Resume attributable agent work after process or session failure

## Behavioral Specification

### User Experience

After compaction, terminal loss or agent death, the supervisor explains what remains active and resumes from accepted assignment state without duplicated work.

### Expected Behavior

- Recovery loads task goal, assignment checkpoint, latest attempt identity, pending HITL and unresolved effects. Old pane IDs are hints, not authority; compare the live process/session identity before adoption.
- A surviving valid process is adopted, not relaunched. A dead process produces a failed/stopped/uncertain attempt according to its evidence; the overseer explicitly decides whether to start a new attempt. Routine authorized recovery does not require a fresh Captain permission.
- Pi compaction/reload must preserve or restore the delivery/wake bindings exactly once. An external process being dead is distinct from a live idle agent; /loop cannot resurrect it.
- Positive termination checks include descendants that could still write into the worktree. Stop/close leaves checkpoint, worktree and commits intact. Unknown liveness preserves resources and reports uncertainty.
- Do not replay accepted external effects during resume. Reconcile them through their receipts; pending HITL remains tied to exact proposal/attempt and is deliberately rebound only with audited recovery evidence.
- Core process-tree defects in native Herdr must be reproduced and fixed in the owning runtime if found; ACE acceptance remains blocked until installed regression proves no orphan writers. Do not hide defects with repeated broad kills.

### Interface Contract

`ace-assign resume --assignment ID [--dry-run]` reports adopt/restart-required/reconcile-required and accepts a restart only through a new attributable attempt. `ace-overseer status --format json` includes liveness, last verified observation and recovery reason; stale/unreadable is unknown, never green.

### Success Criteria and Verification Plan

- [ ] SC1: Inject compaction, supervisor restart, agent death, stale pane reuse and crash around external effect receipt; require deterministic continuation decision.
- [ ] SC2: Run installed close/stop against a process with a writing child and assert no survivors; verify worktree files and unmerged commits remain.
- [ ] SC3: Run `ace-test ace-assign all`, `ace-test ace-herdr all`, `ace-test ace-overseer all`; live Herdr/Pi failure drill is required before lab cutover.

### Scope and Ownership

Owner: **ace-assign and ace-overseer**. Consumers and boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only, not implementation or deployment.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: `8wr.t.qjl`, `8wq.t.k86`, `8wm.t.y23`. Canonical cross-repository program: lab-config:`8wl.t.gad`. External acceptance gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown identity/authority is an error, never permission or success. Executed tests plus independent current-head review gate delivery; CI is advisory. Spec readiness is not proof of installed behavior.

### Provenance and Invalidated Assumptions

Replaces title-only 1w5; historical missing 1cc reference is not a second task. Tidy 1w0 is existing functionality, not proof of native process-tree termination.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. The approved 2026-09-28 specification supersedes conflicting earlier requirements. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.
