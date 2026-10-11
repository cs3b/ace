---
id: 8xa.t.ega
status: in-progress
priority: low
created_at: "2026-10-11 01:55:00"
estimate: 
dependencies: []
tags: [gad2, closure, records]
worktree:
  branch: ega-deliver-gad2-closure-records-via-reviewed-pr-and-demonstrate-repaired-task-aware-worktree-path
  path: .ace-wt/ace-t.ega
  created_at: "2026-10-11 10:38:35"
  updated_at: "2026-10-11 10:38:35"
  target_branch: main
---

# Deliver gad.2 closure records via reviewed PR and demonstrate repaired task-aware worktree path

## Behavioral Specification

### Purpose

Combined closure delivery ordered by the Captain (gad.2 full-lifecycle):
(a) closure records for the gad.2 pilot and prerequisite repair are delivered
via a reviewed PR, and (b) the REPAIRED public task-aware worktree path
(`ace-git-worktree create --task`) is demonstrated on real Lab by using it to
create this delivery's own worktree.

### Deliverables

1. Task-record closures on the branch, based on origin/main:
   - pilot archival commit `43e7644f1` (task 8wj.t.vle done+archive),
     cherry-picked from preserve branch
     `preserve/local-main-43e7644f1-pilot-archival`;
   - repair archival commit `7b268023f` (task 8x9.t.x3o done+archive),
     already on local main lineage;
   - this task's own mint + lifecycle records.
2. `gad2-closure-summary.md` in this task directory: truthful gad.2 record —
   pilot delivered+integrated (PR35, b97e7b75f), repair delivered+integrated
   (PR36, 1a8fa820), closeout records, corrections (fullsuite UNRESOLVED),
   HITL topology gap -> gad.8, RC status (0.35.1/0.26.1 versioned records,
   validation evidence listed, publication NOT authorized), NO gad.2 PASS
   claim (system acceptance gates: drills + observed gates pending).
3. Demonstration evidence: command + full output of the repaired
   `ace-git-worktree create --task 8xa.t.ega` recorded in the evidence dir
   and referenced here.

### Interface Contract

Task records and closure documents only. No gem behavior, CLI, or test
semantics change. Handbook/test suites stay green.

### Verification plan

- Repaired tool demonstration executed on real Lab; worktree created;
  bookkeeping commit present (the exact path that crashed before the fix).
- Branch contains both archival commits + this spec + summary + correction.
- PR via AGit flow; independent review per standing template with mandatory
  completion callback; STOP at approved PR for host integrator.

### Acceptance criteria

- [ ] Repaired task-aware create demonstrated on real Lab (evidence recorded).
- [ ] Closure records PR opened via AGit with both archival commits + docs.
- [ ] Independent exact-head review APPROVED with mandatory callback.
- [ ] STOP at approved PR; no merge, no publication, no direct main push.

## Provenance

Captain full-lifecycle order (relayed by lab coordinator) after PR36
integration (1a8fa820). Stage B of the staged closeout.
