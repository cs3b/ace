---
id: 8wr.t.qjy
status: in-progress
priority: high
created_at: "2026-09-28 17:42:11"
estimate: TBD
dependencies: []
tags: [lab-readiness]
bundle:
  presets: [project]
  files: [ace-handbook-integration-pi/handbook/prompts/loop.md, ace-handbook-integration-pi/.ace-defaults/handbook/providers/pi.yml, ace-handbook-integration-pi/ace-handbook-integration-pi.gemspec]
  commands: []
needs_review: false
title: Wake Pi agents through in-process loops and file watches
position: 6o000a
worktree:
  branch: qjy-wake-pi-agents-through-in-process-loops-and-file-watches
  path: .ace-wt/ace-t.qjy
  created_at: "2026-09-28 20:02:48"
  updated_at: "2026-09-28 20:02:48"
  target_branch: main
---

# Wake Pi agents through in-process loops and file watches

## Behavioral Specification

### User Experience

An overseer sleeps while idle, remains available for conversation, and receives a bounded wake message when a timer or watched state changes.

### Expected Behavior

- Ship an actual Pi extension through the existing integration package/projection. The completed 1vz prompt remains evidence of a prompt only; it cannot satisfy timer/watch acceptance.
- Provide multiple named per-agent loops and watches inside the live Pi process. Commands /loop add NAME --interval SECONDS --message TEXT, /loop list, /loop remove NAME; /watch add NAME --path PATH --message TEXT, /watch list, /watch remove NAME. Invalid/nonpositive intervals and unknown names fail clearly.
- Wake means queue/sendUserMessage only. No scripted non-deterministic judgment, automatic task execution, cron/systemd timer or external heartbeat service. The agent decides what to do after waking.
- Coalesce repeated wakes for the same source while one is queued; preserve different sources. Busy agents receive a queued follow-up, not injected text interrupting an in-flight tool operation. User conversation remains responsive.
- Session reload/compaction re-registers each configured live-session subscription once. Show active subscriptions in plugin UI; removal stops future wakes. A restart performs one state reconciliation rather than flooding all missed timer ticks.
- No claim to wake a dead process: parent overseer/liveness layer in 1w5 owns detection/restart decisions. Unreadable watched path reports a visible error and does not silently spin.

### Interface Contract

The slash command forms above are the Pi agent API. Loop IDs are scoped to the agent session; watcher paths are explicitly configured and validated. Replace the colliding backlog-running /loop prompt with a separately named /work-backlog prompt during implementation; preserve its existing behavior under that name, no alias masking the new extension.

### Success Criteria and Verification Plan

- [ ] SC1: With a fake clock/event source prove wake-only behavior, coalescing, distinct sources, invalid intervals, unsubscribe and no backlog flood.
- [ ] SC2: Installed Pi test: timer and file update wake idle and busy agent; conversation interrupts normally; extension reload does not duplicate timers.
- [ ] SC3: Run `ace-test ace-handbook-integration-pi all` and the installed extension acceptance scenario; prove no external timer/service dependency.

### Scope and Ownership

Owner: **ace-handbook-integration-pi**. Consumers and boundaries are named above. Code layout belongs to JIT planning. This review pass authorizes specification changes only, not implementation or deployment.

### Vertical Slice Decomposition

Single end-to-end capability slice; size: large. Prerequisites: none. Canonical cross-repository program: lab-config:`8wl.t.gad`. External acceptance gates are explicit references, not unresolved local dependency IDs.

### Decisions and Defaults

No unresolved product choice is delegated to the implementer. Unknown identity/authority is an error, never permission or success. Executed tests plus independent current-head review gate delivery; CI is advisory. Spec readiness is not proof of installed behavior.

### Provenance and Invalidated Assumptions

New missing capability after completed ace:8wq.t.1vz, not a retroactive claim that prompt delivery failed.

Earlier text is retained in `history/pre-lab-spec-review.md` as non-normative history. The approved 2026-09-28 specification supersedes conflicting earlier requirements. Draft until independent review accepts this revision.

### Usage and Review Evidence

Public scenarios: `ux/usage.md`. Record independent review before promotion.
