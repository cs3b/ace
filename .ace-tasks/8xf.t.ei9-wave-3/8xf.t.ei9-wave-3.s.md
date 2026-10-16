---
id: 8xf.t.ei9
status: draft
priority: high
created_at: "2026-10-16 09:40:17"
estimate: TBD
dependencies: []
tags: [overseer, autonomy, program]
bundle:
  presets: [project]
  files: [AGENTS.md, docs/tools.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/8wr.t.qk0-coordinate-responsive-overseer-roles-without-the.s.md, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/8wr.t.qkb-run-assignment-delivery-workflows-through-named-forge.s.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/8x3.t.xz9-execute-scoped-services-across-os-users-with.s.md, .ace-tasks/8xb.t.iy6-run-project-commands-with-explicitly/8xb.t.iy6-run-project-commands-with-explicitly-authorized.s.md, .ace-tasks/8xa.t.nh0-ace-hitlace-hitl-hermes-shared/8xa.t.nh0-ace-hitlace-hitl-hermes-shared-hermes-multi.s.md, .ace-tasks/8x0.t.ig3-unify-review-loop-ownership-and/8x0.t.ig3-unify-review-loop-ownership-and-effective-policy.s.md, ace-overseer/handbook/skills/as-overseer-configure-project/SKILL.md, ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md, ace-assign/.ace-defaults/assign/presets/supervise-delivery.yml, ace-assign/.ace-defaults/assign/presets/integrate-batch.yml, ace-assign/.ace-defaults/assign/presets/deliver-release.yml, ace-assign/.ace-defaults/assign/presets/close-delivery.yml, .ace-tasks/8xf.t.ei9-wave-3/ux/usage.md]
  commands: []
title: Wave 3
---

# Wave 3

## Objective and execution boundary

One canonical ACE coordination task for the next iteration: each project has
an overseer that stays responsive, loads its skills/context, owns a high-level
queue and delegates actual execution through scoped services through delivery.
Captain explicitly requested ONE task, not a duplicate child implementation
tree. The six milestones below refer to existing source owners. Advisory size:
large; each milestone has an independently observable acceptance boundary.

Implementation is HOST-SIDE in isolated worktrees of /home/mo/Projects/ace,
not dispatched to Lab agents. Lab remains the install/acceptance receiver.
The merged PR60 cut a6c0d14d and its current release are PRECEDING work, not
new Wave 3 deliverables. Finish that release first; do not duplicate it here.
This draft authorizes no publication, credential grant, or real deployment.
Captain commands override briefs; report scope conflicts and results to main.
Host environment interface: /home/mo/lab-config/docs/lab-interface.md.

## Ownership and existing work

| Area | Existing source owners | Host responsibility |
|---|---|---|
| Role/context, bootstrap/resume, queue, lifecycle | qk0; qkb/qkb.1; ace-overseer/ace-assign/handbook | gad.5/nfe install project mappings |
| Admission, identity, forge integration, canonical results | xz9/xz9.4 and current xz9.5 work; qjx/Assign; ace-git-forgejo | gad.8/gad.b identities/configuration/executors |
| Project commands and HITL/Hermes | iy6, nh0 and existing scoped service owners | gad.8/gad.b actual runtime transport/authority |
| Review and boundary evidence | ig3, qkb.1, ace-review/handbook; qk1 provider contracts | configure effective workflow; no host review engine |
| Sync/release | qkb.1, ace-git-github/forgejo, existing publisher workflows | accepted bindings, install manifest and consumers |
| Installed acceptance | this task coordinates evidence, not another store | gad.2 single checklist; w9b deployment/acceptance map |

At source baseline qk0/xz9/iy6/nh0 are draft, qkb blocked; these are not proof
of installed capability. Discover their current state before execution. Do not
reopen archived owners automatically. xz9.5 execution is referenced by owner/PR
provenance; its task file is not present at this baseline, so reconcile rather
than mint a replacement or pretend a missing path exists.

Host plan: lab-config task 8xd.t.w9b, directory
/home/mo/lab-config/.ace-tasks/8xd.t.w9b-autonomiczne-dostarczanie-projekt-w-przez/.
It retains host deployment/acceptance obligations and detailed historical
findings. This ACE task owns the ordered generic implementation plan. Existing
source tasks are referenced, not reparented, duplicated or silently closed.

## Six ordered milestones

### 0 — Minimal shared contract and effective context (medium)

Reuse as-overseer-configure-project → wfi://overseer/configure-project and
existing supervise-delivery, integrate-batch, deliver-release, close-delivery
presets. Verify effective resolution/versions/paths/digests, including project
overrides, and retain idempotent KEPT/CREATED/UPDATED/BLOCKED adaptation.
Bootstrap/start/resume loads role, project context, skills, queue, actual
attempt/ref state, scoped services/grants, concurrency limits and release policy.
No new parallel skill/template framework. This minimal contract may progress
alongside bounded integrator fixes, without gating all work on a full review project.

Role purpose/workflow inputs, outputs and completion are separate from scoped
capability/executor identity/readiness. Worker, specwriter, reviewer, integrator
and publisher are purposes, not automatic privileges; GitHub/Forgejo operations
can be capabilities shared by multiple workflows. Test same workflow under two
project scopes and two workflows sharing one permitted service; deny missing grants.

Review maps changed responsibilities to owning packages using actual contracts,
imports/calls and existing APIs. Reject duplicated Forgejo provider logic in
runtime, allow useful thin delegation. Small security/architecture diffs are
not trivial by line count. Specwriter self-check remains distinct from initial
independent review. Integrator may carry approval through verified identical
rebase or assess a minor correction with tests; substantive/uncertain delta
requires independent review. Always bind accepted head and server-side guard.
Migrate stale blanket-new-SHA-review rules in effective presets/adaptation, not
only this task text. Success: cold session selects the right workflow and
scoped service and demonstrates correct risk-based review decisions.

### 1 — Callable installed integrator, snapshot and local queue (large)

Complete existing xz9 owner route through actual Forgejo adapter, not local
update-ref or synthetic remote observation. Admission returns a canonical
request/attempt, executor identity, actual start and terminal result/uncertain.
Accepted-head POST guard prevents GET→POST races. After attempted mutation,
nil/404 is uncertain, not no-effect. Reconcile provider truth before any retry.
Receiver must coherently adopt trusted config/authorization digests; revocation
and expiry remain effective. Admit a newly authorized second candidate after
first merge without per-PR host policy edits or receiver restart.

In parallel, deliver authoritative snapshot and local .ace-tasks/overseer queue:
objective/criteria/dependencies/next action/blocker and Assign references only,
not duplicate steps/receipts. This future runtime queue is gitignored; durable
plans/decisions/results are versioned. Resolve the exact path/public selector,
never silently write another list. Snapshot records repo IDs/URLs/named refs,
checkout and remote SHAs, observation times/unknown and source versus installed
versions. GitHub is the issue source; Forgejo PRs are a distinct provider scope.
Host gad.b installs the bounded accepted route; whole gad completion is not a gate.
Success: real authorized merge and readback; denied/stale-head/expired decision
paths have no effect; missing runtime configuration is a precise blocker.

### 2 — Autonomous queue and Herdr discipline (large)

One short cycle: observe → reconcile → choose → dispatch/adopt → record → idle.
Keep user steering responsive. No accepted attempt means ready-not-dispatched,
not waiting integrator. Distinguish accepted-not-started/running/uncertain;
ack/start deadlines target the actual owner, never fabricated all-lanes-hold.
Coalesce unchanged wake reports and continue independent eligible work.
Restart adopts existing attempts before new dispatch; no sleep-polling.

Select only next eligible integration by dependencies/conflicts/release cut,
not worker-finish FIFO. Fresh main → isolated rebase/tests → risk-based
accepted-head review/evidence attached and read back → merge/receipt → next.
Implementation roots may finish PR-ready; separate delivery list references
producers without reparenting or artificial blocking children.

Project workspace is separate from Lab workspace. Short labels show
project/task/role-attempt (e.g. ace/xz95/worker-1), never secrets. Control by
fresh stable IDs/session, not names. Fresh tab per active attempt, max4 panes;
verify actual cwd/worktree/start, not malformed parsing or startup sleep.
Close accepted preserved-result pane and its last tab; retain worktree separately.
Hourly native and restart sweep protect live/uncertain writers. No canonical
branch switch/stash/destructive cleanup; prove skeleton supersession before
removing untracked files and preserve valuable WIP.
Success: two sequential PRs advance without per-item host chat; second prepared
on new main, with real request/start/effect and restart/lost-reply safety.

### 3 — Project delivery bindings: release, HITL, sync, install (large)

Preparation can run in parallel, activation waits for the relevant route's
readiness. Reuse project prepare/publisher script in a dedicated worktree/pane;
version/changelog/dependency/manifest changes use reviewed PR and integration.
Publish from approved integrated source, preserve digests/provenance and one
idempotent queue. Roles do not grant publisher/deployer permissions. Use existing
authorized environment credentials; no secret values in records. Validate actual
HITL provider/socket/authorization/reply binding, not helptext or legacy CLI
presence. Unknown/orphan requests reconcile; manual publication is not native HITL PASS.

Sync uses configured source/target IDs/URLs/refs and selected task/release SHA,
not origin inference or waiting for future PRs. Safe ancestry/divergence checks;
no force/mirror/deletes; tags excluded unless explicitly scoped. Read back old/new
remote SHAs; code/issues/releases have separate outcomes. Missing legacy Work
means capability gap, never fake records. Correlate PR create/update intended and
returned identities; preserve existing PRs on conflict, no broad AGit force.

Install all actual consumers: global user, isolated service runtime, coordinator
and project bundles, persistent installer manifest/locks. Verify dependency closure,
actual CLI/require/route smoke and reinstall behavior without legacy pin regression.
Success: scoped project delivery reaches its configured target with actual receipts;
blocked routes stay open instead of paper-closing source/installed obligations.

### 4 — Real installed acceptance (large)

Use the existing Lab, one gad.2 evidence checklist: two parallel workers, two PRs
prepared/merged serially without host chat, authorized release/install/smoke and
cleanup. Second scoped decision is created AFTER first merge while receiver stays
running; preloaded two grants cannot hide the authority bottleneck. Execute restart,
lost reply, stale-head race, denied grants and config revocation/expiry. Show
source-complete versus installed-failed states honestly; host rescue is recorded,
not autonomy PASS. No new artificial Lab or unapproved real publication/deploy.

### 5 — Cold onboarding a second project (medium)

Reuse the SAME generic ACE skills/templates with project configuration only:
repo/context, permissions, limits and a different release policy. An explicitly
authorized demo/test delivery is sufficient for the second release type; do not
infer real deploy permission. Cold start and restart preserve independent queues,
workspaces and scoped rights; one project cannot mutate or block the other's
eligible work. No copies of generic overseer logic in project repositories.
Success: effective configuration resolves correctly in both projects, operations
are attributable, and acceptance survives independent steering/restarts.

## Readiness, verification and closure

Before each milestone, review existing owner/source state and identify remaining
behavior; do not rebuild delivered capabilities. Use existing ace-test/ace-test-suite
for relevant source regression and separate real installed tests. Verify invalid
routes as well as happy paths; source versions, prompts and local verdicts are
not execution proof. Defects route to existing owners; no automatic archived reopen.
Boundary regression rejects wrong-layer provider logic, accepts thin adapters,
and verifies effective workflow loading. Missing credentials/configuration are
reported precisely without broadening grants or inventing host mechanisms.

This task completes only when all six milestone outcomes have attributable
reviewed source and configured/installed evidence, including second-project reuse.
Current release is a preceding cut; no repeated publication of already published
versions is required. Host-only development remains binding during implementation.
Source owners retain their tasks; no auto-completion of this delivery umbrella
merely because workers are PR-ready. This is a draft specification, not execution.
