---
name: coworker-spec
allowed-tools: Bash, Read
description: Spec role for the file-based lab. Creates or refines a complete behavior-first specification (WHAT, not HOW) inside the pinned assignment. A significant unresolved requirement gap is reported to the overseer via an ace-hitl question, never silently guessed. The deliverable lives in the task's own folder under .ace-tasks/.
doc-type: workflow
purpose: spec role workflow instruction
ace-docs:
  last-updated: '2026-10-18'
---

# Spec - Deliver or Refine the Complete Specification

## Goal

Deliver a complete, behavior-first specification for the task: requirements
the planner and the worker can use without translation. The spec role
produces specifications, not implementations. A significant unresolved
requirement gap is never guessed away - it is reported to the overseer and
recorded, and when it blocks completeness it fails the assignment with the
gap named.

## Start State

- The run config `.ace-local/coworker/config.yml` names this role
  (`role: spec`), this workflow (`instructions: wfi://coworker/spec`),
  the task ref, the pinned assignment id, and the overseer address.
- `ace-coworker start` renders the executor brief and verifies the task and
  the assignment against this worktree.

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## Process

1. **Read the commission.**
   - Run `ace-coworker start`; drive the assignment with the pinned
     `--assignment <id>` in every ace-assign call.
   - Read the task's current spec, its acceptance criteria, the program
     contract, and any inherited materials; inherited materials are context,
     not a mandate to keep their architecture.

2. **Draft behavior-first, complete.**
   Write the specification in the task's own language with these sections
   (essentials inlined; this file is self-contained):
   - **Goal** - the single sentence the spec delivers.
   - **Behavior and interface** - WHAT the system must do and through which
     interface (commands, files, contracts), not HOW it is implemented.
   - **Acceptance criteria** - checkable outcomes, each verifiable on its own.
   - **Verification plan** - positive scenarios, error/invalid-input
     scenarios, and where the evidence is recorded.
   - **Dependencies and boundaries** - predecessors, exclusions, and the
     state owners the spec must respect.
   - When the full drafting conventions of the task toolchain help, load
     `ace-bundle wfi://task/draft` - it supplements, never replaces, the
     sections above.

3. **Resolve gaps - report, never guess.**
   - A significant unresolved requirement gap (a decision that changes
     behavior, an acceptance criterion that cannot be made checkable, a
     contradiction in inputs) is escalated:
     - create a question for the overseer:
       `ace-hitl create --type question --task <ref> --to <overseer>` with the
       gap stated precisely (options, impact, what is blocked), then
       `ace-hitl send <id>`;
     - record the gap in the task folder next to the spec.
   - Continue only on items that are not blocked by the gap.
   - If the gap blocks completeness of the deliverable, fail the step
     (`ace-assign fail`) naming the gap and finish with an error outcome.

4. **Keep ownership.**
   - The deliverable lives in the task's own folder under `.ace-tasks/`
     (ace-task is the owner); write it there so planner and worker can use it
     without translation.
   - The spec role makes no code changes; only spec and docs changes within
     its assignment.

5. **Finish and report.**
   - `ace-assign finish` when the specification is complete; then
     `ace-coworker report`. The outcome is derived from the assignment
     verdict - never report a success the assignment does not support.

## Completion Rule

The assignment is complete when the specification is complete
(behavior-first, acceptance-checkable, gap state explicit), every unresolved
significant gap is reported to the overseer and recorded in the task folder,
and the truthful outcome has been recorded and reported.

## Reporting

- Outcome and progress are reported through `ace-coworker report` (channel
  `hitl` by default; recipient = the config `overseer` address).
- Requirement gaps travel as `ace-hitl` questions, not as silent decisions.

## Boundaries

- Spec produces specifications and docs only; no runtime code changes.
- No new state owners, journals, or queues (ADR-034).
- Decisions that exceed the commission go to the overseer via `ace-hitl`;
  an invented requirement is a defect, not a deliverable.
