---
id: 8xf.t.ei9.5
status: in-progress
priority: high
created_at: "2026-10-16 10:57:19"
tags: []
parent: 8xf.t.ei9
estimate: large
dependencies: [8xf.t.ei9.0, 8xf.t.ei9.4, 8xf.t.ei9.9, 8xf.t.ei9.8]
bundle:
  presets: [project]
  files: [AGENTS.md, docs/tools.md, .ace-tasks/8xf.t.ei9-wave-3/8xf.t.ei9-wave-3.s.md, .ace-tasks/8xf.t.ei9-wave-3/environment-contract.md, .ace-tasks/8xf.t.ei9-wave-3/observations-and-acceptance.md, .ace-tasks/8xf.t.ei9-wave-3/ux/usage.md, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/8wr.t.qkb-run-assignment-delivery-workflows-through-named-forge.s.md, .ace-tasks/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md, .ace-tasks/8xa.t.nh0-ace-hitlace-hitl-hermes-shared/8xa.t.nh0-ace-hitlace-hitl-hermes-shared-hermes-multi.s.md, ace-overseer/handbook/skills/as-overseer-configure-project/SKILL.md, ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md, ace-assign/.ace-defaults/assign/presets/supervise-delivery.yml, ace-assign/.ace-defaults/assign/presets/integrate-batch.yml, ace-assign/.ace-defaults/assign/presets/deliver-release.yml, ace-assign/.ace-defaults/assign/presets/close-delivery.yml]
  commands: []
title: Deliver scoped releases sync and verified installations
needs_review: false
---

# Deliver scoped releases sync and verified installations

Advisory size: **large**. Existing code owners: 8wr.t.qkb, 8xb.t.iy6, 8xa.t.nh0.
This child owns the observable program outcome; reuse/adopt their delivered work,
implement only remaining behavior there, and do not duplicate or reopen archived owners.
## Outcome and public operation contract

Project policy selects integrate-more or a release batch and its target: package,
deploy/demo or merge-only. Reuse supervise-delivery/integrate-batch/deliver-release/
close-delivery plus project adaptation; no new publication framework or one release
per worker. Implement actual authorized binding where current template is placeholder.

Release worker prepares versions/changelog/dependency closure/artifact manifest in
its OWN worktree and pane based on selected integrated cut. Tracked changes undergo
independent review and integration. Publication uses another dedicated worktree/pane
anchored to exact integrated approved release source, never dirty canonical/main
branch switching. Generated artifacts/local evidence alone are not dirty-source refusal.
Manifest binds source revision, package/version/registry, dependency order and digests.

Use existing project prepare/publisher script and authorized environment/service.
Its queue skips already published matching artifacts, checks exact revision and
idempotence; do not launch parallel pushes or replace it with ad hoc commands.
Scope publisher/deployer rights separately from role. Concrete release authorization
is required; credentials remain with executor, not task/worker output. Actual OTP
route and fresh attempt binding are child .9; manual publish is not HITL acceptance.
A prepared artifact or empty queue does not prove publication; registry readback
must match. Check follower dependency floors (a ~>0.6.2 range excludes0.7).
Partial success retains per-artifact published/uncertain sets. Reconcile registry
version/digest before any retry; dependency failure stops dependent publication.

Project command execution via existing ace-lab run owner iy6 accepts configured
project command and optional scoped services/environment with declared inputs,
executor identity and canonical result. No arbitrary privileged shell, copied
credential or legacy Work fabrication. Missing executable binding is blocked with
owner, not an unbounded wait or a reason to invent a framework.

## Current publication readiness and ownership (2026-10-16)

Verified source gap: ordinary delivery has real registration/start/results, but
canonical candidate/review ingress and fixed service/publication admission remain
protected-only. Existing publication also reads artifacts from a candidate Git
bundle; independently authorized retained build artifacts need their own canonical
transfer and staging join. A successful command or result receipt is not accepted
review or publication authority. The first complete release uses the REAL ordinary
delivery assignment/attempt; taskless secret/publish requirements remain OPEN here.

This child owns ordinary submit/export candidate, real-supervisor assign_review,
independently authenticated accept_review and their shared service/publication join.
Child [ei9.8](../8-enforce-package-ownership-and-accepted/) owns review policy,
accepted-head/convergence behavior and ig3/ig4; candidate admission does not replace
that policy or independent verdict. Review policy/evidence must be ready before a
publication permit. Leave protected launch-control request_review unchanged.

Sequence shared core extraction + executed protected regressions, ordinary native
candidate/review admission and canonical merge proof as a shared .0/.8 prerequisite
BEFORE actual two-PR merge acceptance, then exact artifact manifest retention and
same-owner service/HITL/OTP/registry acceptance. Reuse one Router/journal/exclusion;
never fake a protected origin, task or attempt. Ordinary service authorizer is
source-selected without relabelling the whole journal as protected or granting
all local journals service authority. Full design/test map:
[ordinary-publication-plan.md](ordinary-publication-plan.md).

## Code sync

Use named source/target repo IDs/URLs/refs, selected SHA and task/release scope;
never infer provider from origin or wait for all future PRs. Discover actual scoped
executor input/admission/start/status/recovery. Check ancestry and both-side
unique commits. Safe fast-forward only; divergence preserves target commits through
reviewed reconciliation, not blind cherry-pick/force/mirror/delete. Tags excluded
unless explicitly scoped and never silently overwritten. Receipt records old/new
source/target readbacks; code, issues and release are independent outcomes.
Missing legacy Work is capability mismatch, not authority to fabricate one.

## Installation and acceptance

Install exact published dependency graph into ALL actual consumers: interactive
user runtime, isolated service runtime, coordinator and project bundles, persistent
installer manifest/locks. Select actual interpreter/JSON/dependencies; inspect
configured Bundler path and CLI defaults, not merely activate a gem in one test.
Verify actual CLI, combined require and routed smoke, repeat install and preserved
legacy runtime pins. Source test or one global gem install is not full acceptance.
Deployment authority is the environment contract, not a role name; host executes
privileged install only, project owns requesting/accepting results and continuation.

Test digest/source mismatch, no grant, expired OTP, partial registry result,
lost response, missing service, stale bundle/default gem and interrupted install.
Test sync safe-FF, divergence, denied access, stale expected target, lost reply and
unchanged issues. Durable receipts precede cleanup; source done never closes failed
installation. No repeated publication of already released historical versions.

## Context and readiness

Load this child’s explicit bundle, including environment-contract.md and traceability.
Validate effective public interfaces on the selected source/runtime before effects;
missing capability is a precise readiness result, not permission to invent a route.
Use bin/ace-test or bin/ace-test-suite for focused source checks; installed proofs
are separately attributed. Captain overrides the brief; report results/conflicts to owner.
