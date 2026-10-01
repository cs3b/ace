---
id: 8wq.t.k86.2
status: in-progress
priority: medium
created_at: "2026-09-27 13:29:29"
estimate: TBD
dependencies: [8wq.t.k86.0, 8wq.t.k84]
tags: [ace-herdr, adapter]
parent: 8wq.t.k86
bundle:
  presets: [project]
  files: [ace-herdr/lib/ace/herdr/molecules/herdr_executor.rb, ace-herdr/lib/ace/herdr/organisms/dispatcher.rb, ace-herdr/docs/usage.md, .ace-tasks/_archive/8w/y/8wq.t.k84-ace-herdr-match-ace-tmux/8wq.t.k84-ace-herdr-match-ace-tmux-cli-and.s.md]
  commands: []
needs_review: false
title: Implement herdr adapter agent-aware intents
---

# Implement herdr adapter agent-aware intents

## Behavioral Specification

### User Experience

- **Input**: the shared contract (8wq.t.k86.0) invoked with runtime `herdr`.
- **Process**: the adapter maps contract intents onto the ace-herdr parity
  surface delivered by 8wq.t.k84 (list/send/capture/wait/presets) and the
  vs0 organisms (Dispatcher for ensure/create flows), preserving herdr's
  stronger native semantics instead of degrading them to tmux's.
- **Output**: contract-typed results/errors; the tmux session → herdr
  workspace mapping (contract "session" = herdr workspace; contract
  "window" = herdr tab) is invisible to consumers.

### Expected Behavior

1. All 11 contract operations implemented over the k84 surface:
   context detection (`HERDR_SESSION/HERDR_PANE`/`HERDR_*` env, `pane current`),
   ensure_window → idempotent tab create (by label, in the caller's
   workspace by default), prepare_pane → `pane split` (+ keep-alive
   semantics per herdr model), focus → `tab focus`, send → `pane run`/
   `send-text`/`send-keys`, capture → `pane read`, wait_output →
   `pane wait-output`, close_window → `tab close`, list → `tab/pane
   list`, name sanitization shared.
2. **Agent-aware where herdr is stronger**: wait_agent uses real
   `agent wait` states (idle/working/blocked/done) — no output-stability
   heuristic; send to an agent pane routes to `agent prompt` semantics
   with `agent_blocked` mapped to `SendRejectedError`.
3. **Lifecycle waits map onto herdr probes** (contract op 7):
   `window-exists` → `tab get` succeeds; `window-active` → the tab is
   the focused one (`tab get`/`api snapshot` state); `pane-exists` →
   `pane get` succeeds; `pane-exited` → positive process-exit evidence
   (`pane process-info`) or the pane is gone. Polling is adapter-side
   within the contract timeout (s → ms). **`pane_not_found` is
   condition-specific, never a blanket error inside waits**:
   - `pane-exists` + initially absent → keep polling until timeout
     (supports wait-for-creation), then `WaitTimeoutError`;
   - `pane-exited` + absent → SUCCESS (the target state "no live
     process in that pane" is already true), whether initially or after
     being observed open;
   - `pane_not_found` outside waits (send/capture/context) →
     `TargetNotFoundError` as usual.
4. **Send/wait error mapping** (contract error model): `agent_blocked` →
   `SendRejectedError` (terminal); `agent_prompt_stalled` →
   `SendStalledError` (outcome uncertain — never auto-resend);
   `timeout`/deadline expiry → `WaitTimeoutError`; `pane_not_found` →
   `TargetNotFoundError`; binary/socket unavailable →
   `RuntimeUnavailableError`.
5. Opaque pane handles only: ids parsed from herdr JSON, never predicted;
   workspace≈session mapping documented in adapter docs.
4. The shared contract-test suite passes against this adapter (fake
   executor, vs0 test pattern).

### Interface Contract

```
Ace::Runtime.resolve("herdr")
# => adapter satisfying the 8wq.t.k86.0 contract, backed by ace-herdr
# Contract session ≡ herdr workspace; contract window ≡ herdr tab.
```

**Error Handling:** per the mapping above (`agent_blocked` → `SendRejectedError`; `agent_prompt_stalled` → `SendStalledError`, no auto-resend; `timeout` → `WaitTimeoutError`; `pane_not_found` → condition-specific per lifecycle waits, else `TargetNotFoundError`; unavailable → `RuntimeUnavailableError`). Contract timeouts are seconds; the adapter converts to herdr milliseconds.

**Edge Cases:** caller outside herdr + explicit `runtime: herdr` → context detection reports not-in-runtime; explicit selection fails with missing-context/unavailable error; only assign auto outside all runtimes may choose headless. Both-runtimes live: contract detection order (tmux first) already decided in 8wq.t.k86.0.

### Success Criteria

- [x] Contract suite green against the herdr adapter (fake executor), including all four lifecycle wait conditions and the send error triad (rejected/stalled/timeout).
- [x] Agent-aware behavior preserved: wait_agent uses native states; blocked sends rejected — asserted in tests.
- [x] No tmux-ism leaks: no `%`-style targets, no TMUX env reads in the adapter.

### Reviewed Decisions (2026-09-28)

- Contract package is ace-runtime. Adapters live inside existing ace-tmux/ace-herdr; no renamed adapter gems. Consumer gemspecs install those wrappers as adapter dependencies; neutral code must not call runtime-native APIs directly. This corrects the contradictory earlier demand for installed in-wrapper adapters but no wrapper dependency.
- Callback is ace-runtime send. Per-consumer configuration keys are retained except tmux_window_presets becomes window_presets with no legacy alias. Explicit runtime wins; auto detects tmux first if both are live; Lab configuration explicitly chooses herdr.
- Auto-detection is side-effect-free and uses TMUX/ACE_TMUX_SESSION or HERDR_SESSION plus HERDR_PANE (HERDR_WORKSPACE_ID may refine context). The earlier HERDR_ENV assumption was unsupported. Adapter operations verify runtime availability/current context; explicit unavailable herdr errors, never silently becomes headless. Only assign auto outside any runtime selects headless.
- Tmux readiness uses documented output-stability heuristic; Herdr uses native agent state. Generic status text names the selected runtime. Demo attach/detach stays tmux-local with explicit unsupported error under herdr.
- k86.3 owns terminal paths in ace-git-worktree and E2E runners before Lab acceptance. qk0 separately removes the old runtime=lab engine and changes role coordination.
- Pane-exited is a runtime observation, not assignment success or safe prune evidence: disappearance satisfies that wait, but accepted outcome/process-tree termination still require separate receipts. Positive preservation gates remain mandatory.
- Pane preparation must yield a writable live shell/agent target retained after a submitted command exits; adapter may create/prepare that target using native APIs. Bare command panes may disappear and do not satisfy preparation. Installed tests must verify both runtimes; no assertion of untested Herdr behavior.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask of 8wq.t.k86 (third slice — the new runtime reaches contract parity)
- **Slice Outcome**: `herdr` runtime fully usable through the contract
- **Advisory Size**: medium
- **Context Dependencies**: 8wq.t.k84 (parity surface — hard prerequisite), 8wq.t.k86.0 (contract).

### Verification Plan

#### Unit / Component Validation
- [x] Shared contract tests vs herdr adapter (fake executor).
- [x] Agent-aware routing + error mapping matrix (blocked/stalled/timeout).
- [x] Lifecycle transition tests: pane absent→appears (pane-exists poll-then-success); open→gone (pane-exited success); absent at start (pane-exited immediate success; pane-exists polls to WaitTimeoutError).

#### Integration / E2E Validation (if cross-boundary behavior exists)
- [ ] Manual live-herdr smoke: ensure_window + send_command + wait_agent round-trip.

#### Failure / Invalid-Path Validation
- [x] herdr unavailable → RuntimeUnavailableError; unknown pane → TargetNotFoundError.

#### Verification Commands
- [ ] `ace-test ace-herdr` green; contract suite green against adapter.

## Objective

Deliver the second full implementation of the contract — the proof that
herdr is an equal partner, and the enabler for consumer migration
(8wq.t.k86.3).

## Scope of Work

- **User Experience Scope**: contract behavior when runtime=herdr, with herdr-native semantics preserved.
- **System Behavior Scope**: all 11 ops over the k84/vs0 surface; mapping table session→workspace, window→tab.
- **Interface Scope**: adapter registration; no ace-herdr CLI changes.

### Deliverables
- herdr adapter implementing the contract
- Session/workspace mapping documentation

## Out of Scope

- ❌ New ace-herdr CLI commands (that is 8wq.t.k84)
- ❌ Consumer migrations (8wq.t.k86.3)
- ❌ HITL deliver/dispatch changes (vs0 semantics frozen)

## References

- Parent: 8wq.t.k86; contract: 8wq.t.k86.0; parity surface: 8wq.t.k84

## Lab-readiness review scope (2026-09-28)

This draft retains the existing detailed send/wait contract and the Captain's adapter-location and callback decisions. No runtime code is changed in this spec pass. Review must check all four child specs before parent promotion. Executed tests and independent current-head verdict gate implementation delivery; CI is advisory. Earlier text is preserved in history/pre-lab-spec-review.md only for provenance.
