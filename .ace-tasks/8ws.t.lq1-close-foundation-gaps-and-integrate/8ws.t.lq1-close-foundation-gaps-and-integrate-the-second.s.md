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
position: 6o000l
---

# Close foundation gaps and integrate the second ACE Lab wave

## Purpose and tracking contract
This is the ACE integration tracker replacing the planning role of the loose lab-wave-2-2026-09-29.md. The historical audit moved to .ace-local/lab-readiness/lab-wave-2-2026-09-29.md; it is temporary context, not a second backlog. The cross-repository master remains lab-config 8wl.t.gad.

This task owns sequencing and acceptance receipts, not duplicate implementations. Existing tasks stay at their canonical IDs; new uncovered outcomes are actual children. Check a task checkbox only after its owning record is done and linked evidence establishes the listed result. Reopen this checklist item if receipt is invalidated; do not silently expand a historical done task. `bin/ace-task show 8ws.t.lq1 --content` displays the checklist; updates are explicit, not automatic synchronization.

Current phase (2026-10-04 post-delivery review): foundation, prior feature wave, hym, 34i, z78 and ibk are delivered in source; k86.3 is merged but acceptance remains open. This tracker remains open for combined integration and explicit repair dispositions; specifications below select the next work, not authorize dispatch.

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
- [x] ACE 8wq.t.k86.1 — tmux adapter satisfies runtime contract.
- [x] ACE 8wq.t.k86.2 — Herdr adapter satisfies runtime contract.
- [x] ACE 8wr.t.qjx — scoped service request/receipt seam consumes qjl/1w4.
- [x] ACE 8wm.t.y23 — durable inbox once-or-uncertain semantics consume qjl.
- [x] ACE 8wr.t.qk1.1 — review consumers use named providers.
- [x] ACE 8wr.t.qk1.2 — task issue consumers use named providers.

All six are done with code in main. Their historical receipts remain with their owners; [the reconciliation record](evidence/program-reconciliation-2026-10-04.md) links revisions and limits. This is not proof of one frozen installed Lab. k86.3, service deployment and HITL/recovery still need integration.

## Repair lane — tracked separately, not hidden blockers
- [x] ACE 8ws.t.ibk — fixture-owned evidence, attribution/sentinel/stale-state proof and independent delivery receipt verified; closed and archived after source reconciliation.
- [ ] ACE 8ws.t.ibl — GC fixture repair delivered in 7c043ebd2; remaining bulk persistence/mixed-input proof stays here.
- [ ] ACE 8ws.t.lq8 — bounded observation repair delivered in a656b47de; controlled contention and independent criterion closure still required.
- [x] ACE 8wr.t.v3k — duplicate of delivered tp0/e7986bff4, reconciled as skipped; current fixture explicitly disables remote comments.

These items do not globally block unrelated coding. This tracker can finish only when each required receipt is accepted or its owning task has an explicitly reviewed disposition; an unresolved red test is never hidden as green.

## Later gates — references, not additional acceptance scope here
k86.1 + .2 precede k86.3; full k86 plus qjl/y23 precedes 1w5. qjx precedes 34i then y24; 34i/y23/y24/qjy precede vs2. qk1 completion precedes qkb.0; qkb.1 waits qk0/qjx/qjz. 8x2.t.z78 owns required Forgejo fork/draft/ready/atomic expected-head capabilities before qkb.0 acceptance; uj0 does not supply them. Existing refusals remain visible. qkc/vs3 remain later, with vs3 also requiring lab-config gad.b executors and actual release authority.

lab-config 8wl.t.gad owns installed topology/services/Pi/roles and artifact manifest (gad.b/.8/.9/.5/.a, nfe), installed acceptance with legacy disabled (gad.2), removal/retest (gad.3), cold start (gad.4). No new Lab deployment task is duplicated here.

## Acceptance / verification
- [ ] All foundation and feature checklist task receipts are accepted; repair lane has explicit reviewed disposition.
- [ ] Producer/consumer integration has been verified on the combined source; per-branch reports alone do not close this gate.
- [ ] Each released/installed claim cites exact evidence and version; public registry availability, resolved graph, E2E verdict and Lab deployment remain distinct.
- [ ] `bin/ace-task show/list/doctor` resolve owners/dependencies; no new cycles/dangling IDs. Historical doctor errors are reported separately.

One large tracking/acceptance task with two new outcome children and references to existing owners. No product CLI/API change in this tracker, so no ux/usage.md is needed here. Specification review of this reconciliation is recorded with the task. The umbrella remains in-progress until the six feature outcomes, integration receipts and repair dispositions are complete; two done children alone cannot close it. Task checklists are the durable planning surface; local audit logs remain temporary.

## Historical status reconciliation — 2026-10-02 (superseded scheduling)
- Corrected uj0 and archived t8j metadata from in-progress to done using ace-task update, following Captain closure and stored delivery evidence.
- lq1.0/.1 were already done, but their split archived directories were invisible to ace-task show. Reunited those existing records and evidence with this active parent; no duplicate tasks or history removal.
- Restored this tracker bundle's t8j path.
- Repair lane needs evidence reconciliation before dispatching duplicate fixes: main already contains docs fixture fix 7c043ebd2 and cleanup test fix a656b47de. ibl/lq8 remain open until their acceptance is mapped to those deliveries; this update does not claim fresh test runs or close them.
- Next integration order: k86.2 before y23 (shared Herdr changes), qk1.1 before qk1.2 where provider edits overlap; k86.1 and qjx independently. ibk fixture isolation remains a verification concern for qjx/y23, not a reason to stop writing all six scopes.

## Earlier wave plan — 2026-10-04 (superseded by the post-delivery checklist below)

- [ ] Runtime: hym repair and k86.3 consumer development can proceed in parallel; merge/accept hym first, then k86.3 → k86 → 1w5.
- [ ] HITL: 34i → y24 → vs2 → qjz; vs2/recovery consume y23 signed proof, not generic settled/dead.
- [ ] Provider: z78 → qkb.0; qkb.0/.1 ship atomically after qk0/qjx/qjz prerequisites.
- [ ] Domain (lab-config): gad.8, gad.9 and first executable gad.b service may proceed against delivered qjx/1w4/y23; expand by available ACE contracts.
- [ ] Reliability: ibk implementation; ibl and lq8 only remaining explicit verification above. These do not globally block unrelated coding.
- [x] R1 8x0.t.ig2 — durable campaign/evidence foundation, delivered; no claim of R2/R3 limits.
- [ ] R2 8x0.t.ig3 — after qkb and R1; one stage owner, effective policy and session binding.
- [ ] R3 8x0.t.ig4 — after R2; bounded rounds/retries and explicit escalation.
- [ ] qkc and lab-config:gad.2 require R3 plus exact installed manifest, real users/runtime restart/uncertain effects and independent acceptance with legacy disabled. Then gad.3 removal → gad.4 cold start. ig5 is experimental and not a gate.

There is no single current blocker of every lane. The final join is qk0 → completed qkb → R2 → R3 → qkc/gad.2. Authorization by sixteen-hour silence applies only to a precisely presented and delivered qjz proposal; it never replaces receipt, scope, test, reviewer or OTP requirements. vs3 additionally needs the installed publication executor and specific release authorization.

## Next series — post-delivery code review, 2026-10-04

The authoritative review/evidence map is [wave-3-review-2026-10-04.md](wave-3-review-2026-10-04.md). Independent code review found gaps not exercised by the green default suite. Historical done scopes stay intact; new repairs have real task IDs.

- [x] hym: pointer-only provenance and public materialization error translation landed.
- [x] 34i: scoped authenticated HITL IPC source landed; installed multi-UID proof still required by domain acceptance. vft/vfv own newly identified defects.
- [x] z78: API-based fork/draft/ready/atomic merge landed, with retained disposable Forgejo 8.0.3 evidence. vfw owns create provenance/uncertainty repair; live response-loss gap remains explicit.
- [x] ibk: accepted fixture-isolation source/receipts reconciled, status done and archived.
- [ ] k86.3: finish acyclic adapter installation, retained writable pane proof and actual live Herdr scenarios. This keeps k86/1w5 formally open.
- [ ] ACE 8x3.t.vft: preserve the original HITL listener on rejected/failed startup; first independent repair lane.
- [ ] ACE 8x3.t.vfv: enforce the challenge expiry at actual OTP handoff; independent repair lane in the same package (coordinate integration with vft).
- [ ] ACE 8x3.t.vfw: prove full Forgejo create provenance and retain uncertainty after accepted mutation; independent provider lane.
- [ ] lab-config:gad.8: prepare/install topology and trusted boundary; listener acceptance waits vft and real-user proof. Domain signer/authorization is not supplied by code existence.
- [ ] lab-config:gad.9: installed Pi wake extension proof; independent of the new HITL/Forgejo repairs.
- [ ] lab-config:gad.b: begin its existing setup-project service slice; integrate after gad.8 identity/grants, expand by available contracts. OTP/publisher acceptance waits vfv and exact release authority.
- [ ] y24: optional development alongside vft/vfv; accept only after both repairs. qkb.0: optional development alongside vfw; accept only after vfw and ship atomically with qkb.1.
- [ ] l2d.3/.4/.5: reconcile already-delivered consumer evidence; no duplicate implementation. ibl/lq8 remaining verification and 3zi/4gy hygiene remain separate, not global Lab blockers.

Recommended initial dispatch is the three repairs plus k86.3 closure and the three domain scopes above. Parallel development is not permission for parallel mutation of one primary checkout: use isolated worktrees, one owner per changed file, and serially merge shared HITL/installer/assign changes. Integrate vft/vfv before y24; vfw before qkb.0 acceptance; k86.3 before 1w5. qkb.0/.1 keep one installed vocabulary. Later join is 1w5 + vs2/qjz → qk0 → completed qkb → R2 → R3 → qkc/gad.2. ig5 remains optional.
