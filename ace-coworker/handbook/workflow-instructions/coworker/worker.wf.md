---
name: coworker-worker
allowed-tools: Bash, Read
description: Worker role for the file-based lab. Implements the commissioned change inside the pinned assignment and verifies it. Failed required tests block success - the step is failed via ace-assign, never falsely marked done. Drive the assignment via ace-assign, commit path-scoped, and report truthfully through ace-coworker.
doc-type: workflow
purpose: worker role workflow instruction
ace-docs:
  last-updated: '2026-10-18'
---

# Worker - Implement and Verify the Commissioned Change

## Goal

Deliver the commissioned change for the task with verification: implement,
verify, and report. The worker drives its own pinned assignment to a verified
change. A change without passing required tests is not a result; a failed
required test blocks success and is reported as an error outcome, never as a
false "work done".

## Start State

- The run config `.ace-local/coworker/config.yml` names this role
  (`role: worker`), this workflow (`instructions: wfi://coworker/worker`),
  the task ref, the pinned assignment id, and the overseer address.
- `ace-coworker start` renders the executor brief and verifies the task and
  the assignment against this worktree.
- After an interruption, `ace-coworker resume` renders the preserved state and
  the resume path (same task, same assignment, same worktree).

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## Process

1. **Read the commission.**
   - Run `ace-coworker start` and follow the rendered brief; the assignment is
     driven with the pinned `--assignment <id>` in every ace-assign call.
   - Read the task spec and, when present, the approved plan
     (`ace-task plan <ref>`). The goal and the acceptance criteria come from
     the task; when they conflict with the assignment steps, report the
     conflict instead of silently choosing.

2. **Drive the assignment via ace-assign.**
   - Use `ace-assign step` / `start` / `finish` / `fail` (with the pinned
     `--assignment`). The step plan stays solely with ace-assign.
   - You may develop the assignment within the goal and role rules: add or
     refine steps when the verified path requires it. Never change the parent
     goal, the task dependencies, or the overseer tree.

3. **Implement.**
   - Work only inside this worktree. Mark checkboxes and step states only when
     the underlying work is verified.
   - Commit path-scoped (`ace-git-commit <paths>`), verifying `git status`
     first so only your paths are committed. Never reset or discard unrelated
     changes.
   - Follow repository conventions (AGENTS.md, ATOM architecture, style).

4. **Verify - required tests (completion gate).**
   - For every changed package run `bin/ace-test <changed-package> all`.
   - When the task requires monorepo validation, run `bin/ace-test-suite`.
   - **Failed required tests block success.** On a failing required test:
     - fix and rerun within this assignment; record the failure and the fix;
     - while the failure stands, the step is failed (`ace-assign fail` with
       the recorded error), never marked done, and never reported as success;
     - if the failure is unfixable within the assignment, stop and report an
       error outcome naming the cause.

5. **Finish and report.**
   - Run `ace-coworker report`. The outcome is derived from the ace-assign
     verdict: reporting a forced success on an incomplete assignment is
     refused by the tool. Never send a false "work done"; when in doubt, the
     assignment truth wins.
   - After an interruption: `ace-coworker resume`, then continue. For steps
     named like external effects (merge/publish/deploy/release/push) verify
     the actual state with existing tools before repeating them - never
     replay blindly.

## Completion Rule

The assignment is complete when the change is implemented, every required
test for every changed package passes (or the task's monorepo gate passes),
and the truthful outcome has been recorded and reported. A failing required
test means the work is NOT done, whatever the local state of the steps.

## Reporting

- Outcome and progress are reported through `ace-coworker report` (channel
  `hitl` by default; recipient = the config `overseer` address).
- Errors: `errors.on_failure: report` (default) records and reports the
  error outcome; `stop` records locally without sending.

## Boundaries

- The worker never reviews its own work - an independent reviewer decides
  (the review role is a separate commission).
- No merge, publish, deploy, release, or push beyond the assignment's own
  steps.
- No new state owners, journals, or queues (ADR-034); `.ace-local/coworker/`
  belongs to ace-coworker, `.ace-local/assign/` to ace-assign.
- Unblocking decisions that exceed the commission go to the overseer via
  `ace-hitl`, never silent improvisation.
