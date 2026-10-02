---
id: 8wq.t.k86.1
status: done
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
needs_review: false
title: Implement tmux adapter over existing APIs
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

- [x] Contract suite green against the tmux adapter (fake executor).
- [x] ace-tmux's own suite unchanged/green (adapter adds, does not modify).
- [x] No contract operation falls back to "not supported" (all 11 mapped).

### Reviewed Decisions (2026-09-28)

- Contract package is ace-runtime. Adapters live inside existing ace-tmux/ace-herdr; no renamed adapter gems. Consumer gemspecs install those wrappers as adapter dependencies; neutral code must not call runtime-native APIs directly. This corrects the contradictory earlier demand for installed in-wrapper adapters but no wrapper dependency.
- Callback is ace-runtime send. Per-consumer configuration keys are retained except tmux_window_presets becomes window_presets with no legacy alias. Explicit runtime wins; auto detects tmux first if both are live; Lab configuration explicitly chooses herdr.
- Auto-detection is side-effect-free and uses TMUX/ACE_TMUX_SESSION or HERDR_SESSION plus HERDR_PANE (HERDR_WORKSPACE_ID may refine context). The earlier HERDR_ENV assumption was unsupported. Adapter operations verify runtime availability/current context; explicit unavailable herdr errors, never silently becomes headless. Only assign auto outside any runtime selects headless.
- Tmux readiness uses documented output-stability heuristic; Herdr uses native agent state. Generic status text names the selected runtime. Demo attach/detach stays tmux-local with explicit unsupported error under herdr.
- k86.3 owns terminal paths in ace-git-worktree and E2E runners before Lab acceptance. qk0 separately removes the old runtime=lab engine and changes role coordination.
- Pane-exited is a runtime observation, not assignment success or safe prune evidence: disappearance satisfies that wait, but accepted outcome/process-tree termination still require separate receipts. Positive preservation gates remain mandatory.
- Pane preparation must yield a writable live shell/agent target retained after a submitted command exits; adapter may create/prepare that target using native APIs. Bare command panes may disappear and do not satisfy preparation. Installed tests must verify both runtimes; no assertion of untested Herdr behavior.

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

## Lab-readiness review scope (2026-09-28)

This draft retains the existing detailed send/wait contract and the Captain's adapter-location and callback decisions. No runtime code is changed in this spec pass. Review must check all four child specs before parent promotion. Executed tests and independent current-head verdict gate implementation delivery; CI is advisory. Earlier text is preserved in history/pre-lab-spec-review.md only for provenance.
