---
id: 8re.t.mh0.1
status: draft
priority: medium
created_at: "2026-04-15 14:59:00"
estimate: TBD
dependencies: []
tags: []
parent: 8re.t.mh0
bundle:
  presets: [project]
  files: [docs/decisions/ADR-034-assignment-watch-and-callback-contract.md, ace-assign/lib/ace/assign/cli/commands/watch.rb, ace-assign/handbook/workflow-instructions/assign/drive.wf.md]
  commands: [ace-task show 8re.t.mh0.1 --content, ace-task show 8re.t.mh0 --content]
needs_review: false
---

# Specify tmux callback notification contract for assignment watch

## Objective

Define a notification-only callback contract that lets `ace-assign watch` wake parent operators or agents through tmux targets without changing status authority or mutating assignment state.

## Behavioral Specification

### User Experience

- A parent operator or agent can reserve a tmux callback target and get a wake-up signal when meaningful watcher events occur.
- Callback delivery never becomes the authoritative record of assignment progress; it is only a prompt to re-check status.
- If callback delivery fails, assignment watching still behaves correctly and the underlying assignment state remains intact.

### Expected Behavior

1. The callback surface is expressed as an optional watcher argument using the shape `tmux:<target>`.
2. The target accepts standard tmux targets, including pane identifiers such as `%42`.
3. The watcher may emit callbacks for subtree completion, subtree failure, assignment blocked, and assignment completed events.
4. Callback payloads are single-line, machine-readable wake-up messages rather than full status replacements.
5. Callback consumers must re-run `ace-assign status` before taking action.
6. Callback delivery failure is non-fatal and must not corrupt assignment state or watcher progress.

### Interface Contract

- **Reserved interface**
  ```bash
  ace-assign watch --assignment 8rddnp --callback tmux:%42
  ```
- **Reserved events**
  - `subtree_completed`
  - `subtree_failed`
  - `assignment_blocked`
  - `assignment_completed`
- **Payload contract**
  - Prefix: `ACE_ASSIGN_EVENT `
  - JSON object keys:
    - `assignment_id`
    - `scope`
    - `event`
    - `current_step`
    - `next_step`
    - `session_id`
    - `report_path_or_dir`
    - `resume_command`
    - `timestamp`
- **Behavioral rules**
  - Callback delivery is best-effort.
  - Status remains the source of truth.
  - Callback failure does not fail the assignment.

### Success Criteria

- [ ] The callback contract has one clear interface shape for tmux targets.
- [ ] Reserved events and payload fields are explicit enough for future implementation.
- [ ] The draft leaves no ambiguity that callbacks are wake-up notifications only.
- [ ] The draft defines non-fatal behavior for callback delivery failures.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask design slice
- **Slice outcome**: stable notification contract layered on `ace-assign watch`
- **Advisory size**: small
- **Context dependencies**: watcher contract, ADR for continuation behavior, tmux target semantics

## Verification Plan

### Unit / Component Validation

- Confirm the callback surface is expressed entirely as a watcher-facing interface contract.
- Confirm the payload fields are enough to let a parent re-check state and decide whether to resume.
- Confirm the design does not imply callback-led state transitions.

### Integration / E2E Validation

- Walk through a parent-wake-up scenario where a child subtree completes and the parent receives a tmux callback, then re-checks `ace-assign status`.
- Walk through an assignment-completed scenario and confirm the callback payload carries enough context for a parent closeout step.

### Failure / Invalid Path Validation

- Confirm the design specifies non-fatal behavior for unreachable tmux targets.
- Confirm the design specifies that malformed or dropped callback deliveries do not alter assignment state.
- Confirm the design requires consumers to re-check status before acting.

### Verification Commands

- `ace-task show 8re.t.mh0.1 --content`
- `ace-task show 8re.t.mh0 --content`

## Scope of Work

- Define tmux callback address shape
- Define reserved events and payload fields
- Define notification-only semantics and failure handling

## Deliverables

### Behavioral Specifications

- reserved `--callback tmux:<target>` interface contract
- watcher event vocabulary
- notification-only callback rules

### Validation Artifacts

- payload field inventory
- consumer-behavior expectations for re-checking status

## Out of Scope

- implementing callback delivery in this drafting step
- designing non-tmux callback transports
- redefining watcher continuation semantics already covered by `8re.t.mh0.0`

## References

- parent task `8re.t.mh0`
- `docs/decisions/ADR-034-assignment-watch-and-callback-contract.md`
- `ace-assign/lib/ace/assign/cli/commands/watch.rb`
- `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`
