---
name: overseer-queue
description: Run the private overseer queue in .ace-tasks/_overseer with ace-task --in _overseer - record work as managing tasks with lifecycle subtasks, gate starts on integrated results, keep one active executor per worktree, and process ace-hitl reports
allowed-tools: Bash, Read
doc-type: workflow
title: Overseer Queue Workflow
purpose: Binding process contract for the L6 private overseer queue on the file-based lab model (ADR-034, docs/lab-flow.md) without a second queue engine, journal, lease registry, or role guards in delegation tools.
ace-docs:
  last-updated: '2026-10-18'
  last-checked: '2026-10-18'
---

# Overseer Queue Workflow

## Goal

Coordinate delegated work exclusively through the overseer's private task tree
in `.ace-tasks/_overseer/` (gitignored, managed via `ace-task --in _overseer`),
existing subtasks/dependencies, and `ace-hitl` reports tied to a concrete step.
The tree decides order, dependencies, and assignments. There is no second queue
engine: no daemon, no journal, no state cache, no lease registry, and no
role/name guards inside `ace-task`, `ace-assign`, or `ace-git-worktree`. Every
policy below is executed by the overseer role reading and writing the ordinary
task files.

## Contract rules (non-negotiable)

1. **One list, one owner.** The overseer's coordination state lives only in
   `.ace-tasks/_overseer/`. A coworker reports through messages (ace-hitl) and
   never writes the overseer's list. Reading or writing any other location
   must not create a hidden second list.
2. **Merge is modeled by integration steps.** A dependent step waits for the
   predecessor's *integration* subtask, never for "worker finished". Error,
   no result, or cancellation of a required predecessor is not satisfaction;
   an archived or skipped dependency without proof of the required result is
   not satisfaction either, even if a generic task sorter displays it as ready.
3. **One active executor per worktree.** Roles (planner → worker → reviewer →
   integrator) work sequentially in the same task worktree. The next role
   starts only after the previous assignment finished and handed over. A busy
   worktree gets no second executor; missing data or a lost session means
   investigate or resume, never launch a second agent.
4. **Implementation completion does not close the managing task.** While
   review, integration, or another required step remains, the managing task
   stays open.
5. **Reports are matched, then recorded, then acted on.** Match the message ID
   and task/assignment/step references against the current order before
   accepting a report. Record the result and the processed report ID in the
   existing managing task (no separate dedup table). A repeated report checks
   the recorded result and the existing assignment instead of re-running a
   role. A non-matching report or an escalation stays open for clarification
   and is never treated as success.

## Instructions

Run the loaded workflow as the source of truth and execute it end-to-end
instead of only summarizing it.

### 1) Ensure the private list

Prepare (once) and re-verify on resume:

```bash
mkdir -p .ace-tasks/_overseer
git check-ignore .ace-tasks/_overseer && echo ignored
git status --short -- .ace-tasks/_overseer   # must print nothing
ace-task list --in _overseer
```

Folder creation and the `.gitignore` entry (`/.ace-tasks/_overseer/`) belong
to project configuration; the installer consumes this in L8. If the folder is
missing, create it before any `--in _overseer` call. If git shows files there
as trackable, stop and fix the ignore rule -- do not commit overseer state.

### 2) Record received work as a managing task

For each received scope of work, create an ordinary managing task and its
lifecycle subtasks with explicit dependencies and a reference to the project
task:

```bash
ace-task create "Manage: <scope>" --in _overseer --tags queue
ace-task create "Prepare <scope>" --child-of <manager-ref>
ace-task create "Implement <scope>" --child-of <manager-ref>
ace-task create "Review <scope>" --child-of <manager-ref>
ace-task create "Integrate <scope>" --child-of <manager-ref>
ace-task update <manager-ref> --set project_task=<project-task-ref>
ace-task update <impl-ref> --set dependencies=<prep-ref>
ace-task update <review-ref> --set dependencies=<impl-ref>
ace-task update <integrate-ref> --set dependencies=<review-ref>
```

Rules:

- Add worktree/assignment references only after they really exist (the
  planner prepares them); never fabricate references ahead of preparation.
  Record them on the step that owns them, e.g.
  `ace-task update <step-ref> --set worktree=.ace-wt/<task>/`.

- Cross-task ordering goes through the integration step: a step of task B
  that requires A's merge depends on A's *integrate* subtask, not on A's
  implement subtask:
  `ace-task update <B-step-ref> --set dependencies=<A-integrate-ref>`.

- Read the tree back with `ace-task show <manager-ref>` and
  `ace-task list --in _overseer` after every structural change. The root view
  (`ace-task list`) must stay free of overseer tasks.

### 3) Start only unblocked steps

Before starting any step:

1. Resolve its `dependencies` refs and inspect each predecessor's *status
   and evidence*: the required result must be produced by the predecessor's
   integration (merge) step, verified by tests/review records -- not merely
   announced.
2. Treat error, missing result, cancelled, skipped, or archived-without-proof
   predecessors as unsatisfied.
3. Check the step's worktree is free: the previous assignment on it must be
   finished and the current state read back from the task tree, worktree, and
   assignment files. Unknown state is not a free resource and never permits
   overwriting changes.
4. Only then dispatch the role for that step and mark it
   `ace-task update <step-ref> --set status=progress`.

The start decision belongs to the overseer; this is reading dependencies and
real state, not a new runtime scheduler. `ace-overseer work-on` enforces the
same gate mechanically: it refuses to provision a worktree or assignment for
a step whose recorded dependencies are not satisfied (predecessor status
`done` = accepted and integrated), and reports the blocking reasons.

### 4) Hand the worktree to the next role

Worker finishes → reviewer starts → integrator starts, in the same worktree:

- The previous assignment's completion (and handover of any fixes) ends the
  previous allocation; only then does the next role begin there.

- Two different tasks may run in parallel in two different worktrees; one
  worktree never has two active executors.

- Reviewer fixes belong to the reviewer's own assignment and stay inside its
  bounds; they do not rewrite the parent goal or the private-tree
  dependencies.

### 5) Process reports and continue

When a report arrives (ace-hitl event or message):

1. Match its message ID plus task/assignment/step references to the current
   order. A report that fits no open allocation is kept for clarification,
   not counted as success.
2. Record the outcome and the processed report ID in the managing task /
   step (task-folder notes), then update statuses:
   `ace-task update <step-ref> --set status=done` (or keep open / escalate).
3. For success: end the current allocation, then continue with the next
   unblocked step per rule 3. For a repeated report: check the recorded
   result and the existing allocation; do not start the next step twice.
   For error/escalation: keep the step open, escalate via ace-hitl.
4. After an interruption between recording a result and the next allocation,
   resume by re-reading the task tree and the real worktree/assignment state.

### 6) Close

A managing task closes only when every required subtask (preparation,
implementation, review, integration, and any project-required step) is
terminal with verified results. Implementation completion alone never closes
it. Closing a step family updates the owning project task with the results.

## Worked example

Two features, B needing A's merge:

```text
8xh.t.grm Manage: deliver feature A   (project_task: <A-ref>)
  8xh.t.grm.0 Prepare A               (done)
  8xh.t.grm.1 Implement A             (done, depends: grm.0)
  8xh.t.grm.2 Review A                (done, depends: grm.1)
  8xh.t.grm.3 Integrate A             (done, depends: grm.2)
8xh.t.grn Manage: deliver feature B   (project_task: <B-ref>)
  8xh.t.grn.0 Implement B             (depends: 8xh.t.grm.3)  <-- integration, not impl
  8xh.t.grn.1 Integrate B             (depends: grn.0)
```

While `grm.1` is done but `grm.3` is not, `grn.0` stays blocked. After
`grm.3` is confirmed done (merge verified), `grn.0` becomes startable. While
`grm.2`/`grm.3` remain open, `8xh.t.grm` itself is not closed.
