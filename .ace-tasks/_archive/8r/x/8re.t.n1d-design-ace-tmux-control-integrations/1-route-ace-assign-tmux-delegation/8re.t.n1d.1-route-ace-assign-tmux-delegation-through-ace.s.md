---
id: 8re.t.n1d.1
status: done
priority: medium
created_at: "2026-04-15 15:21:37"
estimate: TBD
dependencies: [8re.t.n1d.0]
tags: [ace-assign, ace-tmux, tmux]
parent: 8re.t.n1d
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/molecules/tmux_fork_runner.rb, ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb, .ace-tasks/8r6.t.xeu-design-ace-tmux-inspectability-and/8r6.t.xeu-design-ace-tmux-inspectability-and-recording-surfaces.s.md]
  commands: [ace-task show 8re.t.n1d.1 --content, ace-task show 8r6.t.xeu --content]
needs_review: false
---

# Route ace-assign tmux delegation through ace-tmux

## Objective

Define how `ace-assign` reuses the shared `ace-tmux` runtime/control surface for tmux-backed delegation behavior without privately owning a parallel tmux orchestration contract.

## Behavioral Specification

### User Experience

- `ace-assign` tmux-backed fork execution behaves as one consumer of the shared `ace-tmux` control surface.
- Operators still experience assignment state as the source of truth for subtree completion and failure.
- When tmux-backed forks stall or fail, `ace-assign` can surface pane-tail or runtime-control diagnostics through the shared tmux interaction layer instead of private raw-tmux logic.

### Expected Behavior

1. `ace-assign` consumes the shared `ace-tmux` control surface defined by `8re.t.n1d.0` and does not lock a second tmux contract before that shared surface is ready.
2. `ace-assign` resolves tmux sessions, windows, and panes through the shared `ace-tmux` control surface.
3. `ace-assign` uses the shared control contract for behaviors such as current session/window resolution, `work-fs` ensure-or-reuse, pane creation or reuse, focus or selection, command dispatch, and bounded named-key dispatch where the shared surface requires it.
4. `ace-assign` continues to use assignment state as the authoritative completion/failure signal for delegated subtree work.
5. `ace-assign` may use tmux output capture as diagnostics, not as the primary source of truth for assignment state.
6. The consumer contract does not redefine `ace-tmux` command shapes or runtime models privately inside `ace-assign`.

### Interface Contract

```bash
ace-assign fork-run --assignment <id>@<root> --launch-mode tmux
ace-assign fork-run --assignment <id> --root <root> --launch-mode tmux
```

Expected `ace-tmux` consumer behaviors:
- resolve the target session/window for the current assignment-driving context
- ensure or reuse the `work-fs` style target window
- start or reuse a target pane for the delegated agent
- capture recent pane output for failure or stall diagnostics when needed
- preserve existing public `ace-assign fork-run` argument semantics rather than inventing a positional subtree argument

Error Handling:
- when tmux targets cannot be resolved, `ace-assign` reports a clear tmux-launch failure without redefining low-level tmux errors
- when pane diagnostics are unavailable, assignment-state failure reporting remains authoritative

Edge Cases:
- detached-session flows still work through explicit targeting
- nested or repeated forks reuse the same control surface semantics rather than ad hoc raw-tmux branches

### Success Criteria

- [x] `ace-assign` is specified as a consumer of shared `ace-tmux` control behavior rather than a private tmux wrapper owner.
- [x] The draft covers session/window resolution, `work-fs` reuse, pane creation or reuse, dispatch, focus, and diagnostics.
- [x] Assignment state remains the source of truth for subtree completion and failure.
- [x] Diagnostic pane capture is specified as supportive evidence, not primary state.
- [x] All public examples use the current shipped `ace-assign fork-run` CLI shape.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: behavior-first `ace-assign` consumer contract for tmux delegation
- **Advisory size**: medium
- **Context dependencies**: shared `ace-tmux` control contract, current `ace-assign` tmux delegation behavior

## Verification Plan

### Unit / Component Validation

- Validate that all tmux-touching `ace-assign` behaviors are expressed as reuse of the shared control surface.
- Validate that assignment state is preserved as the authoritative completion/failure source.

### Integration / E2E Validation

- Walk through `ace-assign fork-run --launch-mode tmux` from current context to delegated pane startup and subtree completion.
- Walk through both supported invocation shapes: `--assignment <id>@<root>` and `--assignment <id> --root <root>`.
- Walk through a stalled or failed delegated run where pane capture supports diagnostics but does not replace assignment-state truth.

### Failure / Invalid Path Validation

- Confirm detached-session or explicit-target launches are covered.
- Confirm the draft does not invent a second private tmux schema inside `ace-assign`.

### Verification Commands

- `ace-task show 8re.t.n1d.1 --content`
- `ace-task show 8re.t.n1d.0 --content`

## Scope of Work

- Define `ace-assign` consumption of shared tmux control
- Preserve current `ace-assign fork-run` public CLI syntax while changing only tmux-consumer behavior
- Define `work-fs` and pane-management behavior at the contract level
- Define diagnostic use of pane capture while preserving assignment-state truth

## Deliverables

### Behavioral Specifications

- `ace-assign` tmux consumer behavior
- assignment-state versus tmux-diagnostic ownership boundary
- explicit delegated-pane lifecycle expectations

### Validation Artifacts

- parent usage scenario for visible tmux delegation through `ace-tmux`

## Out of Scope

- low-level `ace-tmux` control command design owned by subtask `8re.t.n1d.0`
- tape/directive behavior specific to `ace-demo`
- implementation details such as concrete wrapper classes or polling loops

## References

- parent task `8re.t.n1d`
- sibling task `8r6.t.xeu`
