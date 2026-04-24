---
id: 8rn.t.y6j
status: skipped
priority: medium
created_at: "2026-04-24 22:47:17"
estimate: TBD
dependencies: []
tags: []
bundle:
  presets: [project]
  files: [ace-tmux/lib/ace/tmux/cli.rb, ace-tmux/lib/ace/tmux/cli/commands/list.rb, ace-tmux/lib/ace/tmux/cli/commands/start.rb, ace-tmux/lib/ace/tmux/cli/commands/window.rb, ace-tmux/docs/usage.md, .ace-tasks/8re.t.n1d-design-ace-tmux-control-integrations/8re.t.n1d-design-ace-tmux-control-integrations-for-assignment.s.md, .ace-tasks/8r6.t.u53-design-visible-tmux-backed-fork/8r6.t.u53-design-visible-tmux-backed-fork-execution-for.s.md]
  commands: [ace-tmux list, ace-tmux start --help, ace-tmux window --help, ace-task show 8rn.t.y6j --content, ace-task show 8re.t.n1d --content, ace-task show 8r6.t.u53 --content]
---

# Design ACE tmux inspectability, recording, and evidence follow-up from shipped list baseline

## Objective

Define the remaining `ace-tmux` read-side, boundary, and recording follow-up from the original tmux inspectability intent, grounded in the shipped `ace-tmux list` baseline instead of the stale `ace-tmux state` proposal.
This parent owns the generic tmux read-side and evidence problem only: reusable runtime inspection, any still-needed machine-readable/runtime additions, ACE-managed recording enablement, persisted evidence under `.ace-local/tmux/`, provenance reporting, and stable ownership boundaries with sibling tmux work.
Interactive control commands remain owned by sibling task `8re.t.n1d`.

## Behavioral Specification

### User Experience

- Operators and higher-level ACE tools can inspect ACE-managed tmux runtime state through the shipped `ace-tmux list` surface today.
- Designers and implementers can determine which parts of the original inspectability intent are already satisfied by `list` and which parts still require follow-up work.
- If tmux-native recording/evidence remains justified, the resulting contract will stay ACE-managed, opt-in, and independent of visible fork execution.
- The task family preserves the original recording/evidence intent instead of silently narrowing it away.
- Live pane-tail control flows such as `send`, `wait`, `capture`, `attach`, and `detach` are not part of this task family.

### Expected Behavior

1. The shipped `ace-tmux list` surface is treated as the current baseline for human runtime inspection.
2. The task family drafts all real remaining intentions directly as child tasks instead of hiding them behind a research-only subtask.
3. The runtime-inspection, boundary, and recording/evidence concerns stay separate so later review can narrow, split, skip, or reorder them without losing intent.
4. The family stays generic for `ace-overseer`, `ace-assign`, and direct operator use without redefining control-side semantics owned elsewhere.
5. Later `as-task-review t.y6j` is responsible for resolving uncertainty, not a special spike task.

### Interface Contract

- **Current baseline contract**
  ```bash
  ace-tmux list
  ace-tmux list --all-panes
  ace-tmux list --windows
  ace-tmux list --sessions
  ace-tmux list --session dev --window work
  ```
- **Still-open design questions for review to settle**
  - whether additive machine-readable output should extend `ace-tmux list`
  - what read-side ownership boundaries should exist with control-side and visible-fork work
  - whether tmux-native recording should exist on `ace-tmux start` / `ace-tmux window`
  - whether persisted evidence under `.ace-local/tmux/` and provenance such as `source_scope` are still the correct contract
- **Boundary contract**
  - sibling task `8re.t.n1d` owns interactive control semantics and live pane-tail operations
  - this family owns only generic read-side/runtime/evidence behavior

### Success Criteria

- [ ] The original inspectability, boundary, and recording intent is preserved in a current-implementation-grounded task family.
- [ ] Each major original intention exists as a real child task from the start.
- [ ] The task family is grounded in shipped `ace-tmux list` behavior rather than assuming `ace-tmux state` already exists.
- [ ] The child tasks separate additive runtime inspection, ownership boundaries, and recording/evidence concerns.
- [ ] The family explicitly excludes control-side `send`/`wait`/`capture`/`attach`/`detach` ownership.
- [ ] Task-local usage guidance exists for the replacement family.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: orchestrator
- **Slice outcome**: ACE gains a current-implementation-grounded tmux inspectability and recording follow-up family before implementation subtasks are reviewed
- **Advisory size**: medium
- **Context dependencies**: `ace-tmux`, sibling control task `8re.t.n1d`, visible fork task `8r6.t.u53`
- **Child task map**
  - `8rn.t.y6j.0`: define additive runtime inspectability follow-up beyond shipped `ace-tmux list`
  - `8rn.t.y6j.1`: define generic read-side ownership and consumer boundaries with sibling tmux work
  - `8rn.t.y6j.2`: define ACE-managed tmux recording, evidence, and provenance contract

## Verification Plan

### Unit / Component Validation

- Confirm the parent uses shipped `ace-tmux list` as baseline instead of presuming `ace-tmux state` exists.
- Confirm each original intention has a real child owner.
- Confirm the parent does not claim control-side behaviors owned by `8re.t.n1d`.

### Integration / E2E Validation

- Confirm the replacement family can be read end-to-end as one real parent goal with three concrete child tasks.
- Confirm later review can narrow, split, skip, or reorder children without losing the original recording intent.

### Failure / Invalid Path Validation

- Confirm the parent does not silently drop recording/evidence from scope.
- Confirm the parent does not treat current `ace-tmux list` as sufficient proof that all original goals are satisfied.
- Confirm the parent does not reintroduce stale `ace-tmux state` wording as mandatory future truth.

### Verification Commands

- `ace-task show 8rn.t.y6j --content`
- `ace-task show 8rn.t.y6j.0 --content`
- `ace-task show 8rn.t.y6j.1 --content`
- `ace-task show 8rn.t.y6j.2 --content`

## Scope of Work

- preserve the original tmux inspectability, boundary, and recording intent
- ground that intent in shipped `ace-tmux list` behavior
- separate unresolved runtime-inspection, boundary, and recording/evidence concerns
- keep control-side semantics out of this family

## Deliverables

### Behavioral Specifications

- parent goal for tmux inspectability and recording follow-up
- additive runtime-inspection child task
- read-side ownership/boundary child task
- recording/evidence child task

### Validation Artifacts

- task-local `ux/usage.md`

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| Shipped `ace-tmux list` human runtime inventory baseline | existing implementation | -- | ACCEPTED (BASELINE) |
| Additive machine-readable/runtime surface | `8rn.t.y6j.0` | -- | TO REVIEW |
| Explicit read-side ownership boundary versus control and visible-fork work | `8rn.t.y6j.1` | -- | TO REVIEW |
| ACE-managed recording enablement | `8rn.t.y6j.2` | -- | TO REVIEW |
| Persisted evidence under `.ace-local/tmux/` | `8rn.t.y6j.2` | -- | TO REVIEW |
| Recording provenance such as `source_scope` | `8rn.t.y6j.2` | -- | TO REVIEW |

## Out of Scope

- implementing tmux runtime code or tests in this drafting pass
- defining live control commands already owned by `8re.t.n1d`
- redefining visible fork execution behavior owned elsewhere

## References

- `ux/usage.md`
- sibling task `8re.t.n1d`
- sibling task `8r6.t.u53`
- `ace-tmux/docs/usage.md`
