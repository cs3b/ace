---
id: 8rn.t.y6j.1
status: draft
priority: medium
created_at: "2026-04-24 22:47:23"
estimate: TBD
dependencies: []
tags: []
parent: 8rn.t.y6j
bundle:
  presets: [project]
  files: [.ace-tasks/8rn.t.y6j-design-ace-tmux-inspectability-recording/8rn.t.y6j-design-ace-tmux-inspectability-recording-and-evidence.s.md, .ace-tasks/8re.t.n1d-design-ace-tmux-control-integrations/8re.t.n1d-design-ace-tmux-control-integrations-for-assignment.s.md, .ace-tasks/8r6.t.u53-design-visible-tmux-backed-fork/8r6.t.u53-design-visible-tmux-backed-fork-execution-for.s.md, ace-tmux/docs/usage.md]
  commands: [ace-task show 8rn.t.y6j.1 --content, ace-task show 8re.t.n1d --content, ace-task show 8r6.t.u53 --content, ace-tmux list]
---

# Define read-side ownership and consumer boundaries for shared tmux surfaces

## Objective

Define the generic read-side ownership boundaries between `ace-tmux`, sibling control work, and visible-fork consumers so follow-up runtime and recording work lands in the right task and package.
This child owns the contract boundary only; it does not define new control commands.

## Behavioral Specification

### User Experience

- Designers and implementers can tell which shared tmux concerns belong in `ace-tmux` versus sibling control or consumer tasks.
- Generic read-side contracts remain reusable for `ace-overseer`, `ace-assign`, and direct operator use.
- Control-side pane-tail behavior does not drift back into this family.

### Expected Behavior

1. Preserve `ace-tmux` ownership for shared read-side/runtime/evidence surfaces.
2. Preserve `8re.t.n1d` ownership for interactive control semantics and live pane-tail operations.
3. Clarify any visible-fork consumer assumptions that depend on generic read-side behavior without making this family own fork execution itself.
4. Give later review enough boundary clarity to split or skip sibling tasks without losing layer ownership.

### Interface Contract

- **Shared read-side baseline**
  ```bash
  ace-tmux list
  ```
- **Boundary expectations**
  - `ace-tmux` owns generic runtime inspection and any shared evidence/provenance surface
  - `8re.t.n1d` owns `send`, `wait`, `capture`, `attach`, and `detach`
  - `8r6.t.u53` remains a consumer of generic tmux behavior, not the owner of shared read-side contracts

### Success Criteria

- [ ] The task clearly separates shared read-side ownership from sibling control behavior.
- [ ] The task keeps visible-fork consumers in a consumer role rather than an owner role.
- [ ] The task can be revised by review without reintroducing spike semantics or stale `ace-tmux state` assumptions.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: stable ownership boundary for shared tmux read-side and evidence surfaces
- **Advisory size**: small
- **Context dependencies**: parent `8rn.t.y6j`, sibling tasks `8re.t.n1d` and `8r6.t.u53`

## Verification Plan

### Unit / Component Validation

- Confirm the task assigns shared read-side behavior to `ace-tmux`.
- Confirm the task assigns live control behavior to `8re.t.n1d`.

### Integration / E2E Validation

- Confirm the boundary can be read together with `8rn.t.y6j.0` and `8rn.t.y6j.2` without overlap.

### Failure / Invalid Path Validation

- Confirm the task does not make visible-fork work the owner of shared tmux primitives.
- Confirm the task does not pull `send`/`wait`/`capture`/`attach`/`detach` back into this family.

### Verification Commands

- `ace-task show 8rn.t.y6j.1 --content`
- `ace-task show 8re.t.n1d --content`
- `ace-task show 8r6.t.u53 --content`

## Scope of Work

- shared read-side ownership and consumer boundaries
- no runtime feature implementation
- no control-side command semantics

## Deliverables

### Behavioral Specifications

- boundary contract for shared tmux read-side and evidence surfaces

## Out of Scope

- additive runtime-inspection behavior details owned by `8rn.t.y6j.0`
- recording/evidence feature details owned by `8rn.t.y6j.2`
- live control-side tmux commands

## References

- parent task `8rn.t.y6j`
- sibling task `8re.t.n1d`
- sibling task `8r6.t.u53`
