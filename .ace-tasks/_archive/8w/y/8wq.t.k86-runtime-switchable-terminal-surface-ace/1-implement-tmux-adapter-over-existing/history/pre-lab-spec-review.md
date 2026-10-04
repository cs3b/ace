# Non-normative earlier draft

---
id: 8wq.t.k86.1
status: draft
priority: medium
created_at: "2026-09-27 13:29:29"
estimate: TBD
dependencies: 8wq.t.k86.0
tags: [ace-tmux, adapter]
parent: 8wq.t.k86
bundle:
  presets: [project]
  files: [ace-tmux/lib/ace/tmux/organisms/control_surface.rb, ace-tmux/lib/ace/tmux/molecules/tmux_executor.rb, ace-tmux/lib/ace/tmux/molecules/runtime_target_resolver.rb, ace-tmux/lib/ace/tmux/atoms/window_name_sanitizer.rb]
  commands: []
---

# Implement tmux adapter over existing APIs

## Behavioral Specification

### User Experience

- **Input**: the shared contract (8wq.t.k86.0) invoked with runtime `tmux`.
- **Process**: the adapter delegates to ace-tmux's existing public surface
  (ControlSurface, TmuxExecutor, RuntimeTargetResolver,
  WindowNameSanitizer) — thin delegation, no re-implementation, no
  behavior changes to ace-tmux itself.
- **Output**: contract-typed results/errors; every existing tmux consumer
  path behaves exactly as today when routed through the adapter.

### Expected Behavior

1. All 11 contract operations map onto existing ace-tmux capabilities
   (send → ControlSurface.send_command/send_text/send_key with the
   interactive-CLI heuristics preserved; wait_agent → the output-stability
   + settle heuristic; ensure_window → list-then-create idempotency as
   used by TmuxControlSurfaceRunner/TmuxWindowOpener today).
2. tmux-specific knowledge stays inside the adapter: `%pane`/`@id` target
   syntax, `TMUX`/`ACE_TMUX_SESSION` env handling, submit-delay
   heuristics, `remain-on-exit`/`tiled` pane preparation.
3. Native tmux errors map into the contract error model
   (TargetNotFound, RuntimeUnavailable).
4. The shared contract-test suite (8wq.t.k86.0) passes against this
   adapter using the existing fake-executor test seams.

### Interface Contract

```
Ace::Runtime.resolve("tmux")
# => adapter satisfying the 8wq.t.k86.0 contract, backed by Ace::Tmux
```

**Error Handling:** tmux target resolution failures → `TargetNotFoundError`; tmux binary missing → `RuntimeUnavailableError`. No new error text invents tmux internals (contract-neutral messages).

**Edge Cases:** `auto`-detected tmux context flows through unchanged (env overrides like `ACE_TMUX_SESSION` honored inside the adapter, invisible to the contract).

### Success Criteria

- [ ] Contract suite green against the tmux adapter (fake executor).
- [ ] ace-tmux's own suite unchanged/green (adapter adds, does not modify).
- [ ] No contract operation falls back to "not supported" (all 11 mapped).

### Validation Questions

- [ ] wait_agent fidelity: is ace-tmux's output-stability heuristic an acceptable contract implementation of "agent readiness" (vs declaring it tmux-limited)? Default: acceptable, documented limitation.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask of 8wq.t.k86 (second slice — proves the contract against the incumbent runtime)
- **Slice Outcome**: `tmux` runtime fully usable through the contract
- **Advisory Size**: small
- **Context Dependencies**: 8wq.t.k86.0 contract; bundle.files (ace-tmux surface).

### Verification Plan

#### Unit / Component Validation
- [ ] Shared contract tests vs tmux adapter (existing fake-executor seams).
- [ ] Error mapping matrix (target/binary failures).

#### Failure / Invalid-Path Validation
- [ ] tmux unavailable → RuntimeUnavailableError via contract.

#### Verification Commands
- [ ] `ace-test ace-tmux` green; contract suite green against adapter.

## Objective

Prove the contract is implementable over the incumbent runtime with pure
delegation — the reference adapter, and the regression baseline for
consumer migration (8wq.t.k86.3).

## Scope of Work

- **User Experience Scope**: contract behavior when runtime=tmux, identical to today's direct ace-tmux usage.
- **System Behavior Scope**: delegation mapping for all 11 ops; error mapping.
- **Interface Scope**: adapter registration; no ace-tmux API changes.

### Deliverables
- tmux adapter implementing the contract
- Contract-suite pass evidence

## Out of Scope

- ❌ Changes to ace-tmux internals beyond registration glue
- ❌ herdr adapter (8wq.t.k86.2), consumers (8wq.t.k86.3)

## References

- Parent: 8wq.t.k86; contract: 8wq.t.k86.0
