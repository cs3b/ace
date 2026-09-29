---
id: 8ws.t.lq1
status: pending
priority: high
created_at: "2026-09-29 14:28:56"
estimate: large
dependencies: [8wr.t.uj0, 8wr.t.t8j, 8wq.t.k86.1, 8wq.t.k86.2, 8wr.t.qjx, 8wm.t.y23, 8wr.t.qk1.1, 8wr.t.qk1.2]
tags: [lab-readiness, umbrella]
title: Close foundation gaps and integrate the second ACE Lab wave
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8wr.t.uj0-bind-forgejo-provider-commands-to/8wr.t.uj0-bind-forgejo-provider-commands-to-the-selected.s.md, .ace-tasks/8wr.t.t8j-enforce-prune-safety-workflow-contract/8wr.t.t8j-enforce-prune-safety-workflow-contract-in-overseer.s.md, .ace-tasks/8ws.t.lq1-close-foundation-gaps-and-integrate/evidence/release-proof-2026-09-29.md, .ace-tasks/8ws.t.lq1-close-foundation-gaps-and-integrate/evidence/install-observations.json]
  commands: []
---

# Close foundation gaps and integrate the second ACE Lab wave

## Purpose and tracking contract
This is the ACE integration tracker replacing the planning role of the loose lab-wave-2-2026-09-29.md. The historical audit moved to .ace-local/lab-readiness/lab-wave-2-2026-09-29.md; it is temporary context, not a second backlog. The cross-repository master remains lab-config 8wl.t.gad.

This task owns sequencing and acceptance receipts, not duplicate implementations. Existing tasks stay at their canonical IDs; new uncovered outcomes are actual children. Check a task checkbox only after its owning record is done and linked evidence establishes the listed result. Reopen this checklist item if receipt is invalidated; do not silently expand a historical done task. `bin/ace-task show 8ws.t.lq1 --content` displays the checklist; updates are explicit, not automatic synchronization.

Current Captain instruction: specifications/checklists first; no implementation, publishing or dispatch in this turn. All counts/checkmarks below are a 2026-09-29 snapshot, not permission to execute.

## First wave — delivered scopes
- [x] ACE 8wq.t.1w2 — hermetic test infrastructure, main PR344; tp0 consumer fixes also delivered, with later runner source loading fix 96c445b8a. This does not close new fixture defects.
- [x] ACE 8wq.t.k86.0 — shared runtime contract, PR343; adapters remain separate below.
- [x] ACE 8wr.t.qjl — durable attempts/execution evidence, PR346; not yet complete dependent services/recovery.
- [x] ACE 8wq.t.1w4 — stable topology/identity, PR341; not domain privileged execution.
- [x] ACE 8wr.t.qjy — live Pi wake, PR345; not recovery of dead processes or once-only business effects.
- [x] ACE 8wr.t.qk1.0 — neutral worktree/provider foundation, PR347; not every consumer or full Forgejo delivery.
- [x] ACE 8wj.t.ocz — installed workflow packaging/probe, PR342; actual prune enforcement belongs to t8j.

Historical source audit: dbb9bde1e; current spec inspection: e45679c1e. Completed scope evidence lives with the original task records. Status/PR identity alone must not establish later broader guarantees.

## Foundation closure — do this before resuming the feature wave
- [ ] ACE 8wr.t.uj0 — selected-repository Forgejo calls and authoritative cleanup evidence; accepted code + actual supported fj surface + tests + independent verdict.
- [ ] ACE 8wr.t.t8j — force-proof preservation/no-writer checks on actual prune paths; destructive boundary tests + independent verdict.
- [ ] ACE 8ws.t.lq1.0 — correctly classified long CLI execution; verified cause, no false timeout or replay of uncertain effects.
- [ ] ACE 8ws.t.lq1.1 — coherent published dependency graph and completed TS-MONO-001 verdict for exact intended versions.

These are parallel scopes until lq1.1's final acceptance, which waits for lq1.0. They do not share a requirement to merge simultaneously. The Captain has chosen to close this group first; that sequencing preference does not invent technical dependencies for every adapter.

Release evidence: evidence/release-proof-2026-09-29.md preserves the supplied SAFE proof; evidence/install-observations.json records hashes/excerpts of both existing install logs. Both show successful bundle completion with ace-git-github 0.1.2 and older pre-afternoon runner/wrapper packages. Publication of 17 artifacts is reported by the Captain, not independently re-queried here. SAFE installation for that graph is accepted partial evidence; full final scenario completion and latest graph are still unchecked. Lab-ready is not inferred.

## Second feature wave — existing task owners, no duplicate scopes
- [ ] ACE 8wq.t.k86.1 — tmux adapter satisfies runtime contract.
- [ ] ACE 8wq.t.k86.2 — Herdr adapter satisfies runtime contract.
- [ ] ACE 8wr.t.qjx — scoped service request/receipt seam consumes qjl/1w4.
- [ ] ACE 8wm.t.y23 — durable inbox once-or-uncertain semantics consume qjl.
- [ ] ACE 8wr.t.qk1.1 — review consumers use named providers.
- [ ] ACE 8wr.t.qk1.2 — task issue consumers use named providers.

After foundation closure these six scopes can be written concurrently. Merge Herdr adapter before y23 as shared-package coordination, then rerun both; this is not an invented hard API dependency. Merge uj0 before accepting either Forgejo consumer; prefer qk1.1 before qk1.2 when both edit common provider surfaces. qjx and tmux adapter integrate independently. Every integration records exact merged candidate, executed relevant checks, independent verdict and separately accounted historical red results. CI is advisory.

## Repair lane — tracked separately, not hidden blockers
- [ ] ACE 8ws.t.ibk — managed assignment test isolation; close before trusting those fixtures for qjx/y23 acceptance.
- [ ] ACE 8ws.t.ibl — intermittent docs update-count assertion; standalone pass did not close it.
- [ ] ACE 8ws.t.lq8 — SafeCapture descendant verification under load; do not assume reported flake means harmless.
- [ ] ACE 8wr.t.v3k — reconcile likely duplicate gh-auth test scope with e7986bff4/tp0 evidence; verify before closure, do not implement twice.

These items do not globally block unrelated coding. This tracker can finish only when each required receipt is accepted or its owning task has an explicitly reviewed disposition; an unresolved red test is never hidden as green.

## Later gates — references, not additional acceptance scope here
k86.1 + .2 precede k86.3; full k86 plus qjl/y23 precedes 1w5. qjx precedes 34i then y24; 34i/y23/y24/qjy precede vs2. qk1 completion precedes qkb.0; qkb.1 waits qk0/qjx/qjz. qkb.0 owns reconciliation of required Forgejo ready/atomic expected-head capabilities before full delivery acceptance: uj0 does not supply them. Existing refusals remain visible; spec review must give any missing provider implementation a real scope before qkb dispatch. qkc/vs3 remain later, with vs3 also requiring lab-config gad.b executors and actual release authority.

lab-config 8wl.t.gad owns installed topology/services/Pi/roles and artifact manifest (gad.b/.8/.9/.5/.a, nfe), installed acceptance with legacy disabled (gad.2), removal/retest (gad.3), cold start (gad.4). No new Lab deployment task is duplicated here.

## Acceptance / verification
- [ ] All foundation and feature checklist task receipts are accepted; repair lane has explicit reviewed disposition.
- [ ] Producer/consumer integration has been verified on the combined source; per-branch reports alone do not close this gate.
- [ ] Each released/installed claim cites exact evidence and version; public registry availability, resolved graph, E2E verdict and Lab deployment remain distinct.
- [ ] `bin/ace-task show/list/doctor` resolve owners/dependencies; no new cycles/dangling IDs. Historical doctor errors are reported separately.

One large tracking/acceptance task with two new outcome children and references to existing owners. No product CLI/API change in this tracker, so no ux/usage.md is needed here. Status stays draft until child specs and tracker review are accepted. Task checklists are the durable planning surface; local audit logs remain temporary.
