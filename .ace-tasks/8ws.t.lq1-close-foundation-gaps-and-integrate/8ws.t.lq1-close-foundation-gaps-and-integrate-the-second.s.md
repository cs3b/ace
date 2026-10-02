---
id: 8ws.t.lq1
status: in-progress
priority: high
created_at: "2026-09-29 14:28:56"
estimate: large
dependencies: [8wr.t.uj0, 8wr.t.t8j, 8wq.t.k86.1, 8wq.t.k86.2, 8wr.t.qjx, 8wm.t.y23, 8wr.t.qk1.1, 8wr.t.qk1.2]
tags: [lab-readiness, umbrella]
title: Close foundation gaps and integrate the second ACE Lab wave
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8wr.t.uj0-bind-forgejo-provider-commands-to/8wr.t.uj0-bind-forgejo-provider-commands-to-the-selected.s.md, .ace-tasks/_archive/8x/v/8wr.t.t8j-enforce-prune-safety-workflow-contract/8wr.t.t8j-enforce-prune-safety-workflow-contract-in-overseer.s.md, .ace-tasks/8ws.t.lq1-close-foundation-gaps-and-integrate/evidence/release-proof-2026-09-29.md, .ace-tasks/8ws.t.lq1-close-foundation-gaps-and-integrate/evidence/install-observations.json]
  commands: []
---

# Close foundation gaps and integrate the second ACE Lab wave

## Purpose and tracking contract
This is the ACE integration tracker replacing the planning role of the loose lab-wave-2-2026-09-29.md. The historical audit moved to .ace-local/lab-readiness/lab-wave-2-2026-09-29.md; it is temporary context, not a second backlog. The cross-repository master remains lab-config 8wl.t.gad.

This task owns sequencing and acceptance receipts, not duplicate implementations. Existing tasks stay at their canonical IDs; new uncovered outcomes are actual children. Check a task checkbox only after its owning record is done and linked evidence establishes the listed result. Reopen this checklist item if receipt is invalidated; do not silently expand a historical done task. `bin/ace-task show 8ws.t.lq1 --content` displays the checklist; updates are explicit, not automatic synchronization.

Current phase (2026-10-02): Captain confirms foundation closure; implementation receipts below verified against stored records and main history. This update reconciles task state and selects the next feature wave; it does not dispatch implementation.

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
- [x] ACE 8wr.t.uj0 — selected-repository Forgejo calls and authoritative cleanup evidence; accepted code + actual supported fj surface + tests + independent verdict.
- [x] ACE 8wr.t.t8j — force-proof preservation/no-writer checks on actual prune paths; destructive boundary tests + independent verdict.
- [x] ACE 8ws.t.lq1.0 — correctly classified long CLI execution; verified cause, no false timeout or replay of uncertain effects.
- [x] ACE 8ws.t.lq1.1 — coherent published dependency graph and completed TS-MONO-001 verdict for exact intended versions.

Foundation group accepted on 2026-10-02 by the Captain. Source receipts: uj0 f823c6572/f30f5bf7f/54ea07be4 plus task review/test records; t8j PR #352 (38c6515cb); lq1.0 PR #351 (1e5d6ac46); lq1.1 PR #353 (8bc108f21) with final installed acceptance 4ab68e8eb. uj0's current-Lab fj smoke proof was not present in its receipt: retain it explicitly as a required qkc endpoint row, not as a performed check.

Release acceptance: [2026-10-01 final receipt](evidence/installation-acceptance-2026-10-01.md), [machine receipt](evidence/installation-acceptance.json) and [frozen manifest](evidence/installation-manifest.json) supersede the historical partial September proof. TS-MONO-001 run 8x0f3w4: PASS 4/4, SAFE, 20 exact manifest package versions, zero findings, both install modes and consumer dependency edges verified. This is the frozen tested graph, not proof that every later release or Lab installation is current. No installation rerun was performed in this status update.

## Second feature wave — existing task owners, no duplicate scopes
- [ ] ACE 8wq.t.k86.1 — tmux adapter satisfies runtime contract.
- [ ] ACE 8wq.t.k86.2 — Herdr adapter satisfies runtime contract.
- [ ] ACE 8wr.t.qjx — scoped service request/receipt seam consumes qjl/1w4.
- [ ] ACE 8wm.t.y23 — durable inbox once-or-uncertain semantics consume qjl.
- [ ] ACE 8wr.t.qk1.1 — review consumers use named providers.
- [ ] ACE 8wr.t.qk1.2 — task issue consumers use named providers.

Foundation closure is accepted; these six pending scopes are now the next parallel implementation wave. Merge Herdr adapter before y23 as shared-package coordination, then rerun both; this is not an invented hard API dependency. Merge uj0 before accepting either Forgejo consumer; prefer qk1.1 before qk1.2 when both edit common provider surfaces. qjx and tmux adapter integrate independently. Every integration records exact merged candidate, executed relevant checks, independent verdict and separately accounted historical red results. CI is advisory.

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

One large tracking/acceptance task with two new outcome children and references to existing owners. No product CLI/API change in this tracker, so no ux/usage.md is needed here. Specification review is accepted. The umbrella remains in-progress until the six feature outcomes, integration receipts and repair dispositions are complete; two done children alone cannot close it. Task checklists are the durable planning surface; local audit logs remain temporary.

## Status reconciliation — 2026-10-02
- Corrected uj0 and archived t8j metadata from in-progress to done using ace-task update, following Captain closure and stored delivery evidence.
- lq1.0/.1 were already done, but their split archived directories were invisible to ace-task show. Reunited those existing records and evidence with this active parent; no duplicate tasks or history removal.
- Restored this tracker bundle's t8j path.
- Repair lane needs evidence reconciliation before dispatching duplicate fixes: main already contains docs fixture fix 7c043ebd2 and cleanup test fix a656b47de. ibl/lq8 remain open until their acceptance is mapped to those deliveries; this update does not claim fresh test runs or close them.
- Next integration order: k86.2 before y23 (shared Herdr changes), qk1.1 before qk1.2 where provider edits overlap; k86.1 and qjx independently. ibk fixture isolation remains a verification concern for qjx/y23, not a reason to stop writing all six scopes.
