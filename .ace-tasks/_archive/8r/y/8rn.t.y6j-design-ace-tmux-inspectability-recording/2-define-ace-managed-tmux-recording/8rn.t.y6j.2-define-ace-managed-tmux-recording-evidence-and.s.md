---
id: 8rn.t.y6j.2
status: skipped
priority: medium
created_at: "2026-04-24 22:47:23"
estimate: TBD
dependencies: []
tags: []
parent: 8rn.t.y6j
bundle:
  presets: [project]
  files: [.ace-tasks/8rn.t.y6j-design-ace-tmux-inspectability-recording/8rn.t.y6j-design-ace-tmux-inspectability-recording-and-evidence.s.md, .ace-tasks/8rn.t.y6j-design-ace-tmux-inspectability-recording/1-define-read-side-ownership-boundaries/8rn.t.y6j.1-define-read-side-ownership-and-consumer-boundaries.s.md, ace-tmux/lib/ace/tmux/cli/commands/start.rb, ace-tmux/lib/ace/tmux/cli/commands/window.rb, ace-tmux/docs/usage.md]
  commands: [ace-task show 8rn.t.y6j.2 --content, ace-tmux start --help, ace-tmux window --help]
---

# Define ACE-managed tmux recording, evidence, and provenance contract

## Objective

Define whether and how ACE-managed tmux recording, persisted evidence, and provenance reporting should exist in `ace-tmux`, grounded in current implementation rather than silently dropping the original recording goal.
This child owns only the recording/evidence contract.

## Behavioral Specification

### User Experience

- If tmux-native recording remains justified, operators should be able to enable it only for ACE-managed tmux launch paths, not arbitrary foreign panes.
- Persisted evidence should remain raw evidence/provenance, not semantic interpretation.
- Recording should stay separate from live control-side pane-tail behavior.

### Expected Behavior

1. Define ACE-managed recording enablement for `ace-tmux` launch paths only if it remains justified after review.
2. Define persisted evidence under `.ace-local/tmux/` only if still justified.
3. Define provenance such as effective recording source scope only if still justified.
4. Keep recording opt-in and off by default.
5. Preserve the boundary with sibling control-side tmux commands.

### Interface Contract

- **Historical intent to reassess**
  ```bash
  ace-tmux start --record
  ace-tmux window --record
  ```
- **Open follow-up areas for review to settle**
  - recording enablement on ACE-managed launch paths
  - persisted evidence under `.ace-local/tmux/`
  - provenance/reporting such as `source_scope`

### Success Criteria

- [ ] The task preserves the original recording/evidence/provenance intent without pretending it already exists.
- [ ] The task stays separate from control-side live pane-tail behavior.
- [ ] The task can be narrowed, split, skipped, or promoted by review without losing the overall family intent.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: ACE-managed recording/evidence/provenance follow-up, if still justified after review
- **Advisory size**: medium
- **Context dependencies**: parent `8rn.t.y6j`, boundary task `8rn.t.y6j.1`, current `ace-tmux` start/window baseline

## Verification Plan

### Unit / Component Validation

- Confirm the task preserves the original recording/evidence goal.
- Confirm the task does not claim current implementation already ships this surface.

### Integration / E2E Validation

- Confirm the task can coexist with the runtime-inspection and boundary siblings without overlap.

### Failure / Invalid Path Validation

- Confirm the task can be narrowed, split, or skipped cleanly if review finds recording should not remain in this family.
- Confirm persisted evidence and live pane-tail capture are not treated as the same surface.

### Verification Commands

- `ace-task show 8rn.t.y6j.2 --content`
- `ace-tmux start --help`
- `ace-tmux window --help`

## Scope of Work

- recording/evidence/provenance follow-up only
- no live control-side pane-tail behavior
- no additive runtime-inspection work here

## Deliverables

### Behavioral Specifications

- ACE-managed recording/evidence/provenance contract, if still needed

## Out of Scope

- live control-side tmux commands
- additive runtime-inspection work that belongs in `8rn.t.y6j.0`

## References

- parent task `8rn.t.y6j`
- boundary task `8rn.t.y6j.1`
- sibling task `8re.t.n1d`
