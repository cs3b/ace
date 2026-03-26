---
id: 8qp.t.18h
status: draft
priority: medium
created_at: "2026-03-26 00:49:25"
estimate: TBD
dependencies: []
tags: [assign, workflow, ux]
bundle:
  presets: [project]
  files:
    - ace-assign/handbook/workflow-instructions/assign/prepare.wf.md
    - ace-assign/handbook/workflow-instructions/assign/create.wf.md
    - ace-assign/.ace-defaults/assign/presets/work-on-task.yml
    - ace-assign/lib/ace/assign/atoms/preset_expander.rb
    - ace-task/lib/ace/task/organisms/task_manager.rb
  commands: []
needs_review: true
---

# Filter Done Tasks from work-on-task Assignment Creation

## Objective

Prevent already-completed tasks from entering newly created `work-on-task` assignments. When users prepare or create an assignment from `--taskref` or `--taskrefs`, any requested task already marked `status: done` should be excluded before queue expansion so the resulting assignment contains only remaining work.

## Behavioral Specification

### User Experience

- **Input**: User runs `/as-assign-prepare` or `/as-assign-create` for the `work-on-task` preset with one or more task refs, including direct refs, ranges, or patterns
- **Process**: The assignment creation flow normalizes and resolves the requested refs, checks each task's current `status`, filters out refs whose status is `done`, then renders the job/assignment from the remaining refs only
- **Output**: The created or prepared assignment contains only non-done task refs, and the user is told which requested refs were skipped because they were already done

### Expected Behavior

When assignment creation receives task refs for the `work-on-task` preset:

1. **Resolve requested refs first**: Expand `--taskref`, comma-separated `--taskrefs`, ranges like `148-152`, and patterns like `240.*` into concrete task refs before any filtering.

2. **Filter only `status: done`**: For each resolved ref, inspect the current task status. Refs with `status: done` are excluded from the effective `taskrefs` list. This task does not change handling for `pending`, `draft`, `in-progress`, `blocked`, `skipped`, or `cancelled`.

3. **Mixed requested set**: If some requested refs are done and others are not, continue assignment preparation/creation with the remaining non-done refs and report the skipped done refs to the user.

4. **All requested refs already done**: If filtering removes every resolved ref, stop before creating the assignment queue. Report that all requested tasks are already done and do not create an empty assignment.

5. **Filtered refs drive the queue**: The filtered `taskrefs` list becomes the source of truth for preset expansion, hidden spec rendering, batch child generation, and downstream steps such as `mark-tasks-done`.

### Interface Contract

Public commands and flags do not change:

- `/as-assign-prepare work-on-task --taskref 148`
- `/as-assign-prepare work-on-task --taskrefs 148,149,150`
- `/as-assign-create work-on-task --taskrefs 148-152`
- `/as-assign-create work-on-task --taskrefs "240.*"`

Behavior change:

Mixed refs, one task already done:

`/as-assign-create work-on-task --taskrefs 148,149,150`

Expected output includes:

- warning/report that `149` was skipped because it is already done
- generated assignment based only on `148` and `150`

All requested refs already done:

`/as-assign-create work-on-task --taskrefs 148,149`

Expected output includes:

- `All requested tasks are already done: 148,149`
- `No assignment created.`

Underlying deterministic runtime boundary remains unchanged:

`ace-assign create <hidden-spec-path>`

The new behavior happens before that call, during taskref resolution and hidden spec preparation.

Error Handling:

- Requested ref does not exist -> existing task-not-found behavior remains unchanged
- Requested ref exists and has `status: done` while other refs remain -> skip it and report it
- All resolved refs have `status: done` -> abort before assignment creation with a clear actionable message

Edge Cases:

- Single `--taskref` already done -> fail with "already done" message; no assignment created
- Range or pattern input -> resolve to concrete refs first, then filter done refs
- Zero done refs in the requested set -> behavior is unchanged from today
- Duplicate ref handling stays with existing assignment/taskref normalization rules; this task only adds done-status filtering

### Success Criteria

1. `work-on-task` assignment creation filters requested task refs with `status: done` before preset expansion
2. Mixed requested sets create assignments from remaining non-done refs only
3. Assignment creation reports which requested refs were skipped because they were already done
4. If every requested ref is already done, assignment creation aborts without creating an empty queue
5. Filtering applies after range/pattern resolution and before hidden spec rendering / batch child generation
6. `ace-assign create FILE` remains unchanged as the deterministic runtime boundary
7. No checkbox-based reuse or `task/work` resume behavior is introduced by this task

### Validation Questions

- Resolved: The owning layer is assignment preparation/creation, not `task/work.wf.md` or `assign/drive.wf.md`
- Resolved: Only `status: done` is filtered by this task
- Resolved: Mixed sets should skip done refs and continue with a warning
- Resolved: If all requested refs are done, assignment creation should fail instead of creating an empty assignment
- Resolved: Plan/success-criteria checkboxes are out of scope

## Vertical Slice Decomposition (Task/Subtask Model)

This is a **single standalone task**.

- **Slice Type**: Standalone task
- **Slice Outcome**: `work-on-task` assignment preparation/creation excludes already-done task refs from the queue
- **Advisory Size**: Medium -- workflow/spec updates plus implementation in the assignment preparation path
- **Context Dependencies**: `assign/prepare`, `assign/create`, `work-on-task` preset expansion, task status lookup

## Verification Plan

### Unit / Component Validation

- Taskref normalization/resolution path filters out refs whose current task status is `done`
- Prepared effective `taskrefs` list preserves non-done refs unchanged
- `work-on-task` preset expansion uses the filtered `taskrefs` list only
- Hidden spec / rendered assignment metadata reports skipped done refs clearly

### Integration / E2E Validation

- Single pending taskref -> assignment output unchanged from current behavior
- Mixed taskrefs (`done` + non-done) -> assignment created only for remaining refs and reports skipped done refs
- All-done taskrefs -> no assignment created; actionable message returned
- Range/pattern input -> resolves first, then filters done refs before batch queue generation

### Failure / Invalid Path Validation

- Nonexistent taskref -> existing error path preserved
- `blocked`, `skipped`, `cancelled`, `draft`, `pending`, and `in-progress` refs are not filtered by this task
- Empty effective queue due only to done-task filtering -> explicit no-assignment outcome, not silent success

### Verification Commands

- `ace-test ace-assign` -> assignment preparation / creation tests pass
- `ace-test ace-task` -> task lookup/status behavior relied on by filtering remains green
- Review prepared/create workflow docs and `work-on-task` preset examples for skipped-done-task language

## Scope of Work

- **User experience scope**: Assignment preparation and creation for `work-on-task`
- **System behavior scope**: Taskref resolution, filtering, hidden spec rendering, and queue generation
- **Interface scope**: Existing `--taskref` / `--taskrefs` inputs with new done-task filtering semantics

## Deliverables

### Behavioral Specifications

- `work-on-task` assignment creation filters `status: done` refs before queue generation
- Mixed requested sets continue with warning and remaining refs
- All-done requested sets fail without creating an empty assignment

### Validation Artifacts

- Tests covering single, mixed, all-done, and range/pattern taskref cases
- Updated workflow/docs text describing skipped done refs during assignment creation

## Out of Scope

- Changes to `task/work.wf.md` resume behavior
- Changes to `assign/drive.wf.md` subtree execution behavior
- Success-criteria or plan-checkbox reuse semantics
- New task status semantics beyond filtering `status: done`
- Auto-detecting completion from commits, file diffs, or other evidence

## References

- Source idea: `.ace-ideas/8qm5uf-task-workflow-should-mark-already/8qm5uf-task-workflow-should-mark-already-completed-steps.idea.s.md`
- Assignment prep workflow: `ace-assign/handbook/workflow-instructions/assign/prepare.wf.md`
- Assignment create workflow: `ace-assign/handbook/workflow-instructions/assign/create.wf.md`
- Preset expansion: `ace-assign/.ace-defaults/assign/presets/work-on-task.yml`
