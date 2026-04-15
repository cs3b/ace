---
id: 8re.t.n1d.0
status: draft
priority: medium
created_at: "2026-04-15 15:21:37"
estimate: TBD
dependencies: []
tags: [ace-tmux, tmux]
parent: 8re.t.n1d
bundle:
  presets: [project]
  files:
    - ace-tmux/lib/ace/tmux/cli.rb
    - ace-tmux/lib/ace/tmux/models/session.rb
    - ace-tmux/lib/ace/tmux/models/window.rb
    - ace-tmux/lib/ace/tmux/models/pane.rb
    - .ace-tasks/8r6.t.xeu-design-ace-tmux-inspectability-and/8r6.t.xeu-design-ace-tmux-inspectability-and-recording-surfaces.s.md
  commands:
    - ace-task show 8re.t.n1d.0 --content
    - ace-task show 8r6.t.xeu --content
---

# Specify ace-tmux runtime control surface

## Objective

Define the shared `ace-tmux` runtime/control contract that higher-level ACE tools can reuse for tmux interaction, while keeping state inventory and recording provenance in sibling task `8r6.t.xeu`.

## Behavioral Specification

### User Experience

- Operators and higher-level tools can rely on `ace-tmux` for tmux interaction tasks instead of raw `tmux`.
- The public control surface covers the actions needed to direct, observe, and synchronize tmux activity in ACE-managed sessions.
- Direct CLI use and package-level reuse share the same semantics instead of diverging into separate private wrappers.

### Expected Behavior

1. `ace-tmux` defines a control-side surface for send, capture, wait, attach, and detach operations.
2. The shared behavior is available through a reusable Ruby runtime API and mirrored public CLI commands.
3. The control surface defaults to ACE-managed sessions and supports explicit `session`, `window`, and `pane` targeting where needed.
4. The control surface covers dynamic tmux interactions needed by consumers, including ensuring or selecting windows and panes, command dispatch, and recent-output capture.
5. Runtime control models are treated separately from preset/config models to avoid conflating planned config with live runtime state.
6. This subtask does not redefine the read-side `ace-tmux state` and recording provenance contract owned by `8r6.t.xeu`.

### Interface Contract

```bash
ace-tmux send --pane <target> --command "<text>"
ace-tmux capture --pane <target> --lines 40
ace-tmux wait --for output --pane <target> --pattern "Task context:"
ace-tmux attach --session <name>
ace-tmux detach --session <name>
```

Error Handling:
- explicit targets that cannot be resolved return a clear target-resolution failure
- wait operations return a clear timeout outcome when the requested condition is not met

Edge Cases:
- ACE-managed default targeting and explicit targeting must be described as one coherent contract
- quiet or exited panes remain capturable as evidence when the runtime can still observe them

### Success Criteria

- [ ] The draft defines the shared `ace-tmux` control commands and their behavior-level contracts.
- [ ] Ruby API first plus CLI wrapper behavior is explicit.
- [ ] ACE-managed default plus explicit targeting behavior is explicit.
- [ ] Dynamic window/pane interaction needs for consumers are covered without consumer-specific drift.
- [ ] The boundary with sibling `8r6.t.xeu` is explicit and stable.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: reusable public `ace-tmux` control contract
- **Advisory size**: medium
- **Context dependencies**: current `ace-tmux` CLI surface, sibling read-side task `8r6.t.xeu`

## Verification Plan

### Unit / Component Validation

- Validate that the command set and API reuse boundaries cover send, capture, wait, attach, and detach coherently.
- Validate that the draft does not mix runtime-control semantics with read-side provenance/state semantics.

### Integration / E2E Validation

- Trace an operator flow that uses `ace-tmux` directly to send a command, wait for output, capture pane text, and detach.
- Confirm the subtask gives enough control coverage for both `ace-assign` and `ace-demo` to reuse without redefining tmux behavior.

### Failure / Invalid Path Validation

- Confirm unresolved targets and wait timeouts have explicit user-visible behavior.
- Confirm the subtask does not promise arbitrary foreign-session control as the primary model.

### Verification Commands

- `ace-task show 8re.t.n1d.0 --content`
- `ace-task show 8r6.t.xeu --content`

## Scope of Work

- Define public control commands and shared runtime API behavior
- Define target-resolution and wait/capture expectations
- Define separation from read-side state/provenance behavior

## Deliverables

### Behavioral Specifications

- direct `ace-tmux` control command behavior
- shared runtime API reuse contract
- ACE-managed default with explicit-target override behavior

### Validation Artifacts

- parent usage scenarios that demonstrate direct operator control flows

## Out of Scope

- consumer-specific `ace-assign` or `ace-demo` behavior beyond what the shared control surface must expose
- recording provenance/state inventory semantics already covered by `8r6.t.xeu`
- implementation details such as class names or internal command-builder structure

## References

- parent task `8re.t.n1d`
- sibling task `8r6.t.xeu`
