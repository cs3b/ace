---
id: 8qp.t.18h
status: draft
priority: medium
created_at: "2026-03-26 00:49:25"
estimate: TBD
dependencies: []
tags: [workflow, task, ux]
bundle:
  presets: [project]
  files:
    - ace-task/handbook/workflow-instructions/task/work.wf.md
    - ace-task/handbook/workflow-instructions/task/document-unplanned.wf.md
    - ace-assign/handbook/workflow-instructions/assign/drive.wf.md
  commands: []
needs_review: true
---

# Auto-Recognize Pre-Completed Steps in Task Work Workflow

## Objective

When agents work on tasks that contain already-completed subtasks or pre-checked plan steps, they should recognize and skip them instead of re-executing. This prevents agents from redoing work that was already completed — a problem that surfaces when `as-task-document-unplanned` creates orchestrator tasks with mixed done/pending subtasks, or when partially-completed tasks are resumed in a new session.

## Behavioral Specification

### User Experience

- **Input**: Agent receives a task reference (e.g., `as-task-work 8qm.t.5nx`) for a task that has some subtasks already marked `status: done` or plan steps already checked `[x]`
- **Process**: Before executing any work, the workflow inspects the task's subtask statuses and plan step checkboxes. Pre-completed items are acknowledged in output and skipped. Only pending/draft items proceed through the implement → verify → commit loop.
- **Output**: Agent works only on remaining incomplete steps, producing the same quality of work as if all steps were pending — just fewer of them

### Expected Behavior

When the `task/work` workflow loads a task:

1. **Subtask status check**: For orchestrator tasks, enumerate child subtasks and their `status` field values. Subtasks with `status: done` are logged as "already complete" and excluded from the work loop. Subtasks with `status: pending`, `in-progress`, or `draft` are processed normally.

2. **Plan step checkbox check**: When loading the implementation plan, steps already marked `[x]` in the plan checklist are acknowledged as complete and skipped. Only unchecked `[ ]` steps enter the implement → verify → commit cycle.

3. **Success criteria checkbox check**: In the task spec itself, success criteria already marked `[x]` are recognized as satisfied. Only unchecked criteria require verification.

4. **Mixed-status orchestration**: An orchestrator task with 5 subtasks where 3 are done and 2 are pending should result in work on only the 2 pending subtasks. The 3 done subtasks are acknowledged but not touched.

5. **Resume semantics**: A task with `status: in-progress` and some checked plan steps is being resumed mid-work. The workflow picks up from the first unchecked step.

### Interface Contract

No CLI interface changes. This is purely a workflow instruction change affecting agent behavior.

**Affected files:**

```
# Primary — task execution workflow
ace-task/handbook/workflow-instructions/task/work.wf.md

# Secondary — assignment driver subtask iteration
ace-assign/handbook/workflow-instructions/assign/drive.wf.md
```

**Workflow behavior change in `task/work.wf.md`:**

The Primary Directive section currently reads:
```
Work through the plan checklist, step by step:
1. Mark task in-progress
2. For each plan step: implement → verify → commit → mark checkbox done
3. Mark task done
```

After this task, it should include pre-completion awareness:
```
Work through the plan checklist, step by step:
1. Mark task in-progress
2. Check for pre-completed work:
   - Subtasks with status: done → acknowledge and skip
   - Plan steps marked [x] → acknowledge and skip
   - Success criteria marked [x] → acknowledge as satisfied
3. For each REMAINING plan step: implement → verify → commit → mark checkbox done
4. Mark task done
```

**Agent output when skipping pre-completed work:**

```
# Example acknowledgment (not prescriptive format)
Subtask 8qm.t.5nx.0 (README refresh: ace root) — already done, skipping
Subtask 8qm.t.5nx.1 (README refresh: ace-bundle) — already done, skipping
Subtask 8qm.t.5nx.2 (README refresh: ace-docs) — already done, skipping
Working on subtask 8qm.t.5nx.3 (README refresh: ace-git) — pending
```

Error Handling:
- Subtask with `status: done` but no evidence of completion (empty spec, no commits referenced) → warn but still skip (trust the status field as source of truth)
- All subtasks already done → acknowledge all complete, mark orchestrator task done, no work needed
- Plan checklist entirely checked → same as above, proceed to Done section

Edge Cases:
- `status: done` subtask with broken spec content → skip anyway; status field is authoritative
- Task with no subtasks and no plan checklist → no pre-completion logic applies; proceed normally
- `status: blocked` or `status: skipped` subtasks → do not execute these either; they are not pending work
- Inline `--` recording mode (non-file tasks) → no subtask structure; pre-completion check is a no-op

### Success Criteria

1. `task/work.wf.md` includes explicit instructions to check subtask statuses before iterating the work loop
2. Subtasks with `status: done` are acknowledged and excluded from the implement → verify → commit cycle
3. Plan steps already marked `[x]` are recognized as complete and skipped
4. Success criteria already marked `[x]` are recognized as satisfied
5. Mixed-status orchestrator tasks correctly process only incomplete subtasks
6. Resume of in-progress tasks correctly picks up from first unchecked step
7. No behavioral change for tasks where all subtasks/steps are pending (zero pre-completed items)
8. `assign/drive.wf.md` respects subtask status when iterating fork subtrees (does not re-fork done subtasks)

### Validation Questions

- Resolved: Status field is authoritative — `status: done` means done regardless of spec content completeness
- Resolved: `blocked` and `skipped` statuses are also non-executable (only `pending`, `draft`, `in-progress` are workable)

## Vertical Slice Decomposition (Task/Subtask Model)

This is a **single flat task** (one capability slice: workflow instruction update).

- **Slice Type**: Standalone task
- **Slice Outcome**: Task work workflow and assignment driver recognize and skip pre-completed steps
- **Advisory Size**: Small — two workflow markdown files to update, no code changes
- **Context Dependencies**: `task/work.wf.md`, `assign/drive.wf.md`, understanding of task status model

### Verification Plan

#### Unit/Component Validation
- Read updated `task/work.wf.md` and confirm pre-completion check instructions are present in the Primary Directive section
- Read updated `assign/drive.wf.md` and confirm subtask status checking guidance is present
- Verify no instructions suggest re-executing `status: done` subtasks

#### Integration/E2E Validation (if cross-boundary behavior exists)
- Walk through the workflow mentally with example task 8qm.t.5nx (3 done subtasks, remaining pending) and confirm the updated instructions produce the correct skip/work behavior
- Verify that a task with zero pre-completed steps follows the same path as before (no regression)

#### Failure/Invalid Path Validation
- Confirm that a task with ALL subtasks done is handled (acknowledge all, mark orchestrator done)
- Confirm that `blocked`/`skipped` subtasks are not re-executed

### Verification Commands

- Read and review `ace-task/handbook/workflow-instructions/task/work.wf.md` for pre-completion instructions
- Read and review `ace-assign/handbook/workflow-instructions/assign/drive.wf.md` for subtask status respect
- `ace-lint ace-task/handbook/workflow-instructions/task/work.wf.md` → no lint regressions
- `ace-lint ace-assign/handbook/workflow-instructions/assign/drive.wf.md` → no lint regressions

## Scope of Work

- **User experience scope**: Agent behavior when working on tasks with pre-completed subtasks or checked plan steps
- **System behavior scope**: Workflow instructions for task execution and assignment driving
- **Interface scope**: No CLI or API changes; workflow instruction text only

## Deliverables

### Behavioral Specifications
- Updated `task/work.wf.md` with pre-completion awareness in Primary Directive
- Updated `assign/drive.wf.md` with subtask status respect during iteration

### Validation Artifacts
- Manual review of updated workflow text against success criteria
- Lint pass on both updated files

## Out of Scope

- Implementation details: file structures, code organization, technical architecture
- Changes to `ace-task` CLI tool behavior (status field semantics are unchanged)
- Changes to `document-unplanned.wf.md` (it already works correctly — it creates done tasks)
- Automated detection of completion evidence (commit scanning, file diffing)
- Changes to task model or frontmatter schema
- New playback speed values or config cascade integration

## References

- Source idea: `.ace-ideas/8qm5uf-task-workflow-should-mark-already/8qm5uf-task-workflow-should-mark-already-completed-steps.idea.s.md`
- Example task with mixed statuses: 8qm.t.5nx (README refresh — 3 done subtasks for already-completed work)
- Related workflow: `ace-task/handbook/workflow-instructions/task/document-unplanned.wf.md`
