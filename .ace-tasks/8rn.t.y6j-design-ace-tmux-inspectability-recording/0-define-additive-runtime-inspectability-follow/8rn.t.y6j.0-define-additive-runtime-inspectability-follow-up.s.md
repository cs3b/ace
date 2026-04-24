---
id: 8rn.t.y6j.0
status: draft
priority: medium
created_at: "2026-04-24 22:47:23"
estimate: TBD
dependencies: []
tags: []
parent: 8rn.t.y6j
bundle:
  presets: [project]
  files: [.ace-tasks/8rn.t.y6j-design-ace-tmux-inspectability-recording/8rn.t.y6j-design-ace-tmux-inspectability-recording-and-evidence.s.md, .ace-tasks/8rn.t.y6j-design-ace-tmux-inspectability-recording/1-define-read-side-ownership-boundaries/8rn.t.y6j.1-define-read-side-ownership-and-consumer-boundaries.s.md, ace-tmux/lib/ace/tmux/cli/commands/list.rb, ace-tmux/docs/usage.md]
  commands: [ace-task show 8rn.t.y6j.0 --content, ace-tmux list]
---

# Define additive runtime inspectability follow-up beyond shipped ace-tmux list

## Objective

Define any remaining additive runtime-inspection follow-up beyond shipped `ace-tmux list`, grounded in current implementation rather than the stale `ace-tmux state` proposal.
This child owns only generic read-side/runtime follow-up.

## Behavioral Specification

### User Experience

- If current `ace-tmux list` does not cover the full original read-side intent, this task defines the additive contract on top of `list`.
- Operators and higher-level ACE tools should gain any still-needed reusable runtime output without losing the shipped human `list` baseline.
- This task does not own tmux-native recording, persisted evidence, or control-side operations.

### Expected Behavior

1. Treat shipped `ace-tmux list` as the human runtime-inspection baseline.
2. Define only additive runtime-inspection follow-up that remains unmet after review.
3. Prefer extension of current `list` semantics over reviving stale `ace-tmux state` wording unless review proves a distinct command boundary is necessary.
4. Stay generic for `ace-overseer`, `ace-assign`, and direct operator use.

### Interface Contract

- **Current baseline**
  ```bash
  ace-tmux list
  ace-tmux list --windows
  ace-tmux list --sessions
  ```
- **Possible follow-up areas for review to settle**
  - additive machine-readable output
  - richer reusable metadata or liveness reporting
  - any missing ACE-managed scoping/reporting not already satisfied by current list output

### Success Criteria

- [ ] The task is explicitly grounded in current `ace-tmux list` behavior.
- [ ] The task defines only read-side/runtime follow-up, not recording or control behavior.
- [ ] The task can be narrowed, split, skipped, or promoted by review without losing the overall family intent.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: additive runtime-inspection follow-up, if still justified after review
- **Advisory size**: medium
- **Context dependencies**: parent `8rn.t.y6j`, read-side boundary task `8rn.t.y6j.1`, shipped `ace-tmux list`

## Verification Plan

### Unit / Component Validation

- Confirm the task does not assume `ace-tmux state` already exists.
- Confirm the task excludes recording/evidence scope.

### Integration / E2E Validation

- Confirm the task can be read as additive to shipped `list` output.

### Failure / Invalid Path Validation

- Confirm the task can be skipped or narrowed cleanly if review finds no unmet runtime follow-up.

### Verification Commands

- `ace-task show 8rn.t.y6j.0 --content`
- `ace-tmux list`

## Scope of Work

- additive runtime-inspection follow-up only
- no recording/evidence contract here
- no control-side tmux behavior here

## Deliverables

### Behavioral Specifications

- additive read-side/runtime contract, if still needed

## Out of Scope

- tmux-native recording/evidence/provenance
- control-side `send`/`wait`/`capture`/`attach`/`detach`

## References

- parent task `8rn.t.y6j`
- boundary task `8rn.t.y6j.1`
