---
id: 8xa.t.ho4
status: in-progress
priority: high
created_at: "2026-10-11 12:05:00"
estimate: 
dependencies: []
tags: [ace-task, bug, delivery-list]
worktree:
  branch: ho4-ace-task-create-in-delivery-managermove-undefined-after-task-creation-partial-effect
  path: .ace-wt/ace-t.ho4
  created_at: "2026-10-11 12:47:45"
  updated_at: "2026-10-11 12:47:45"
  target_branch: main
---

# ace-task create --in delivery: manager.move undefined after task creation (partial effect)

## Behavioral Specification

### Defect (observed on real Lab, host-recorded + adopted)

`bin/ace-task create "<title>" --in delivery` created the task record
(8xa.t.h8x) and then crashed at `ace-task/lib/ace/task/cli/commands/create.rb:122`
with `manager.move undefined` (the list-placement move step calls an
undefined method on the manager). Effect: PARTIAL creation — task exists at
its minted path but the requested list placement never happened, with no
unreported-partial warning at failure time. The host recovered the existing
task via public `ace-task update --move-to delivery` (recovered identity
preserved). Do not retry create for 8xa.t.h8x.

### Expected Behavior

1. `create --in <list>` places the minted task in the requested list
   atomically: success exactly once, task discoverable in that list.
2. On any post-creation failure, the error is reported WITH the created
   task identity and the recovery command; recovery via public update
   leaves no duplicate and no second task.
3. Recovery path (update --move-to) converges to the same state as a
   clean create.

### Verification plan

- Regression test in ace-task: create with list placement succeeds and
  places the task; the move failure mode (simulate) reports the created
  identity + recovery path; recovery converges without duplicates.
- Executed red-before (reproduce manager.move undefined at create.rb:122
  via the regression) / green-after; full `ace-test ace-task` green.

### Acceptance criteria

- [ ] manager.move call site fixed (correct mover API or guarded invocation).
- [ ] Regression test executed: red before, green after; suite green.
- [ ] Partial-creation reporting guaranteed on any placement failure.
- [ ] Independent exact-head review; Forgejo PR via AGit; STOP at approved PR.

## Provenance

Host-recorded partial-effect defect while provisioning gad.2/8xa.t.h8x
bootstrap (2026-10-11). Adopted as tool-minted bug deliverable after owner
reconciliation found no existing ace-task bug owner covering it.
