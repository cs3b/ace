---
id: 8xf.t.ei9.4
status: in-progress
priority: high
created_at: "2026-10-16 10:57:19"
tags: []
parent: 8xf.t.ei9
estimate: large
dependencies: [8xf.t.ei9.0, 8xf.t.ei9.1, 8xf.t.ei9.2, 8xf.t.ei9.3]
bundle:
  presets: [project]
  files: [AGENTS.md, docs/tools.md, .ace-tasks/8xf.t.ei9-wave-3/8xf.t.ei9-wave-3.s.md, .ace-tasks/8xf.t.ei9-wave-3/environment-contract.md, .ace-tasks/8xf.t.ei9-wave-3/observations-and-acceptance.md, .ace-tasks/8xf.t.ei9-wave-3/ux/usage.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/8wr.t.qk0-coordinate-responsive-overseer-roles-without-the.s.md, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/8wr.t.qkb-run-assignment-delivery-workflows-through-named-forge.s.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/8x3.t.xz9-execute-scoped-services-across-os-users-with.s.md, ace-overseer/handbook/skills/as-overseer-configure-project/SKILL.md, ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md, ace-assign/.ace-defaults/assign/presets/supervise-delivery.yml, ace-assign/.ace-defaults/assign/presets/integrate-batch.yml, ace-assign/.ace-defaults/assign/presets/deliver-release.yml, ace-assign/.ace-defaults/assign/presets/close-delivery.yml]
  commands: []
title: Advance serial integration through native wake cycles
needs_review: false
---

# Advance serial integration through native wake cycles

Advisory size: **large**. Existing code owners: 8wr.t.qk0, 8wr.t.qkb, 8x3.t.xz9.
This child owns the observable program outcome; reuse/adopt their delivered work,
implement only remaining behavior there, and do not duplicate or reopen archived owners.
## Outcome and interface

One responsive cycle observes → reconciles → chooses → dispatches/adopts → records
then idles. User can redirect continuously; no blocking sleep-poll loop or long
implementation/review inside coordinator. Native in-process loop/watch wakes the
agent; judgment remains with it. No external heartbeat daemon, cron or systemd timer.

Choose ONLY next eligible candidate by dependency/conflict/release cut, not finish
FIFO. Read fresh target; delegate as-git-rebase in isolated worktree preserving
CHANGELOG, run checks and accepted-head assessment (.8); publish/read back review
before integration; receive/read back merge, then prepare next candidate. Parallel
independent implementation is allowed, mass-rebasing all waiting siblings is not.

Existing loop/watch definitions are checked in the effective session and restored
on restart without duplicates. Ten-minute native progress audit compares actual
transitions/owner-wait/work metrics; coalesce unchanged wake reports. Timer firing
is not progress or executor start. File watch receipt is adopted without host chat.
Native loops wake only a live process; restarting a dead process is an overseer
decision, not an external heartbeat/watchdog added here.
Durable /goal belongs to existing cm3 future work: not present merely because a
spec exists and not a prerequisite; use current Assign/queue plus native wake.

## Recovery and continuation

No accepted attempt means dispatch or precise capability blocker, not waiting
integrator. Deadline routes to actual owner; preserve independent eligible work.
Restart adopts pending/uncertain request and reconciles remote effect before retry.
After batch exhaustion continue configured release/sync/install/cleanup, or report
its actual scoped blocker. Scope changes pause conflicting work safely; do not
lose its evidence or grant broader capabilities.

## Verification and failure acceptance

Two sequential real PRs, second rebased only after first merge, complete without
per-item host chat. Test target race→needs-rebase, lost reply→single reconciled
merge, owner restart→same attempt and repeated unchanged wakes→no report storm.
Measure transitions versus waits and review churn, not ticks alone. Test user
pause/reorder during active workers and independent project progress during denial.
Verify effective presets and adaptation no longer require blanket full new review
for every moved SHA; identity carry-forward remains evidence-based, not automatic.

## Context and readiness

Load this child’s explicit bundle, including environment-contract.md and traceability.
Validate effective public interfaces on the selected source/runtime before effects;
missing capability is a precise readiness result, not permission to invent a route.
Use bin/ace-test or bin/ace-test-suite for focused source checks; installed proofs
are separately attributed. Captain overrides the brief; report results/conflicts to owner.
