---
id: 8xf.t.ei9.1
status: in-progress
priority: high
created_at: "2026-10-16 10:57:17"
tags: []
parent: 8xf.t.ei9
estimate: medium
dependencies: []
bundle:
  presets: [project]
  files: [AGENTS.md, docs/tools.md, .ace-tasks/8xf.t.ei9-wave-3/8xf.t.ei9-wave-3.s.md, .ace-tasks/8xf.t.ei9-wave-3/environment-contract.md, .ace-tasks/8xf.t.ei9-wave-3/observations-and-acceptance.md, .ace-tasks/8xf.t.ei9-wave-3/ux/usage.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/8wr.t.qk0-coordinate-responsive-overseer-roles-without-the.s.md, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/8wr.t.qkb-run-assignment-delivery-workflows-through-named-forge.s.md, ace-overseer/handbook/skills/as-overseer-configure-project/SKILL.md, ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md, ace-assign/.ace-defaults/assign/presets/supervise-delivery.yml, ace-assign/.ace-defaults/assign/presets/integrate-batch.yml, ace-assign/.ace-defaults/assign/presets/deliver-release.yml, ace-assign/.ace-defaults/assign/presets/close-delivery.yml]
  commands: []
title: Bootstrap project context and truthful capability snapshots
needs_review: false
---

# Bootstrap project context and truthful capability snapshots

Advisory size: **medium**. Existing code owners: 8wr.t.qk0, 8wr.t.qkb.
This child owns the observable program outcome; reuse/adopt their delivered work,
implement only remaining behavior there, and do not duplicate or reopen archived owners.
## Outcome and interface

Cold start/resume loads effective project role, skills/context, queue, actual
attempt/ref state, grants/services, limits and release policy before delegation.
Project overseer owns its entire delivery. Lab overseer only routes/caps/pauses/
resumes projects; it does not duplicate their PR boards or become their integrator.
Both stay responsive to Captain instructions and report scope conflicts to owner.

Reuse as-overseer-configure-project and four shared presets listed in parent.
Resolve installed versions, paths/digests and project overlays; preserve
KEPT/CREATED/UPDATED/BLOCKED idempotence. Missing operation is actionable blocked,
not creation of a copied project-specific generic skill or silent fallback.

Discovery returns TWO composable dimensions:
1. workflow purpose, input/output, completion (worker/specwriter/reviewer/
   integrator/release worker/publisher);
2. operation input/evidence schema, public entrypoint, executor identity,
   readiness, authority/scope, request/result/status/recovery.
Role/model/route selection grants nothing. GitHub and Forgejo operations are
capabilities, not necessarily personas or blanket administration. Specwriter
self-check is followed by independent review/integration in its own worktree.

## Snapshot contract

Project state joins agents, actual attempts/processes, pane/tab/session IDs,
worktrees, Forgejo PRs, ace-task, GitHub issues ONLY, release/install outcomes.
Each field has source, observed_at, repository ID/URL/ref, scoped checkout,
staleness/unknown/conflict. Local HEAD, local tracking ref and fresh remote SHA
are separate; origin name does not identify a provider. No second Assign store.
Source versions, registry versions and actual consumers (interactive user,
service runtime, coordinator/project bundles, installer lock) remain separate.

Runtime profile selects actual harness/model/reasoning. Current defaults are Pi
zai/glm-5.3-flash high for workers and Pi zai/glm-5.3 high for reviewers; explicitly
authorized per-project exceptions are recorded. No silent Codex/model fallback.
Verify actual launch receipt, not only profile text. Human steering remains live.

## Verification and failure acceptance

Cold onboard and repeat adaptation: effective paths/digests match and repeat is
idempotent. Test two workflows sharing one service and one workflow under two
project scopes; role without grant denies. Stale remote, unavailable provider,
wrong origin and stale bundle yield unknown/mismatch, not ready. Update remote
main while local board is old and prove replacement with attributed truth.
A model mismatch refuses/reports the explicit exception needed, not fallback.
Bootstrap/resume adopts existing assignments before launching anything new.

## Context and readiness

Load this child’s explicit bundle, including environment-contract.md and traceability.
Validate effective public interfaces on the selected source/runtime before effects;
missing capability is a precise readiness result, not permission to invent a route.
Use bin/ace-test or bin/ace-test-suite for focused source checks; installed proofs
are separately attributed. Captain overrides the brief; report results/conflicts to owner.
