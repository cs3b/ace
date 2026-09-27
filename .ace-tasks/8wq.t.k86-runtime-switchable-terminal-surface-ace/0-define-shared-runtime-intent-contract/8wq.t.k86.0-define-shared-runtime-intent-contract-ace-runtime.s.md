---
id: 8wq.t.k86.0
status: draft
priority: medium
created_at: "2026-09-27 13:29:29"
estimate: TBD
dependencies: []
tags: [ace-runtime, contract]
parent: 8wq.t.k86
bundle:
  presets: ["project"]
  files:
    - ace-tmux/lib/ace/tmux/organisms/control_surface.rb
    - ace-assign/lib/ace/assign/molecules/tmux_control_surface_runner.rb
    - ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb
    - ace-overseer/lib/ace/overseer/molecules/tmux_window_opener.rb
    - ace-hitl/lib/ace/hitl/providers/providers.rb
  commands: []
---

# Define shared runtime intent contract (ace-runtime gem)

## Behavioral Specification

### User Experience

- **Input**: adapter implementers and consumers program against one
  published intent API; runtime choice arrives as a name (`tmux`, `herdr`)
  from config or auto-detection.
- **Process**: the contract gem resolves a runtime name to a registered
  adapter (unknown name fails closed with the available list — ace-hitl
  provider-registry behavior) and exposes the shared intent operations.
- **Output**: typed results and typed errors, runtime-agnostic; a shared
  contract-test suite any adapter must pass.

### Expected Behavior

The contract covers exactly the operation set consumers use today (no
speculative operations):

1. context detection: in-runtime?, current session-or-workspace,
   window-or-tab, pane (honoring existing env overrides)
2. ensure named window/tab rooted at a path, with layout preset (idempotent)
3. prepare pane (split when needed, stays alive after command exit)
4. select/focus window/tab
5. send: command text (submit), raw text, named keys — to a pane target
6. capture recent pane output (lines-bounded)
7. wait: output pattern (timeout), agent readiness, or lifecycle condition
   — the full set ace-tmux consumers rely on today: `window-exists`,
   `window-active` (focused), `pane-exists`, `pane-exited` (the pane's
   process has exited; demo directives depend on all four)
8. close/kill window/tab by name
9. list windows/tabs and panes
10. window/tab name sanitization (shared naming policy)
11. typed error model (target-not-found, runtime-unavailable, send-rejected)

Selection behavior: explicit config name > auto-detection from environment
(`TMUX` / `HERDR_ENV`); both live → tmux (existing default), documented.
Target identity: opaque handles only — the contract never predicts or
formats pane ids (tmux `%id` and herdr `w1:p1` stay adapter-internal).

### Interface Contract

```
# Registry + resolution (duck-typed adapters, no base class — ace-hitl pattern)
runtime = Ace::Runtime.resolve(name)          # raises UnknownRuntimeError (available: ...)
runtime_name = Ace::Runtime.detect(env: ENV)  # :tmux | :herdr | nil, no side effects

# Intent operations (keyword-arg surfaces mirroring today's consumer calls)
runtime.context                        # => {in_runtime:, session:, window:, pane:}
runtime.ensure_window(name:, root:, preset: nil)  # idempotent; returns target
runtime.prepare_pane(window:)          # returns pane handle
runtime.focus(window:)
runtime.send_command(pane:, command:)
runtime.send_text(pane:, text:)
runtime.send_keys(pane:, keys:)
runtime.capture(pane:, lines: 40)      # => text
runtime.wait_output(pane:, pattern:, timeout:)
runtime.wait_agent(pane:, states:, timeout:)
runtime.wait_lifecycle(condition:, target:, timeout:)
                                       # window-exists|window-active|pane-exists|pane-exited
runtime.close_window(window:)
runtime.list_windows / runtime.list_panes(window:)
Ace::Runtime.sanitize_name(name)       # shared naming policy
```

**Error Handling:** `UnknownRuntimeError` (with available list), `TargetNotFoundError`, `RuntimeUnavailableError`, `SendRejectedError` (pre-send rejection, e.g. agent blocked — terminal), `SendStalledError` (submission accepted but the target did not start processing — OUTCOME UNCERTAIN, callers must not auto-resend), `WaitTimeoutError` (a wait exceeded its deadline) — all subclass one contract error. Timeout units at the contract level are SECONDS (adapters convert to native units).

**Contract CLI:** the gem ships one thin agent-facing passthrough — `ace-runtime send (--cmd TEXT | --msg TEXT... | --key NAME...) --pane TARGET` — resolving the configured runtime and delegating with exactly the send semantics above. This is the runtime-neutral callback command (decision 2026-09-27, Captain: assign's Fork Callback Rule prescribes it instead of `ace-tmux send`). No other CLI surface.

**Edge Cases:** `detect` inside neither runtime returns nil (callers fall back headless, matching assign's `auto` today); ensure_window with an existing name is idempotent by name.

### Success Criteria

- [ ] Contract gem publishes the 11-op API (op 7 covering output, agent, and the four lifecycle conditions) + error model incl. `WaitTimeoutError`/`SendStalledError` + the `ace-runtime send` passthrough; adapters are duck-typed (no dependency on either adapter gem).
- [ ] Shared contract-test suite exists and is documented as the acceptance bar for any adapter (shared-examples pattern), covering all wait conditions and the send error triad (rejected / stalled / timeout).
- [ ] Resolution: explicit name, unknown name (fail closed, available list), auto-detection both-runtimes (tmux wins, documented).

### Validation Questions

- [ ] Gem name `ace-runtime` (vs `ace-support-runtime`) — default `ace-runtime` per ADR-015 focused-gem precedent.
- [ ] Do demo `attach`/`detach` directives belong in the contract (human-facing, tmux-only today)? Default: out — demo keeps them tmux-local until needed.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask of 8wq.t.k86 (first slice — validates the riskiest path: the contract shape against real consumer call sites)
- **Slice Outcome**: registry + 11-op contract + shared tests, no adapters yet (tmux adapter follows in 8wq.t.k86.1)
- **Advisory Size**: medium
- **Context Dependencies**: bundle.files above (consumer call sites are the requirements oracle).

### Verification Plan

#### Unit / Component Validation
- [ ] Registry: resolve/detect/unknown-name matrix.
- [ ] Contract tests compile and run against a reference fake adapter.

#### Failure / Invalid-Path Validation
- [ ] Unknown runtime name → fail closed with available list.
- [ ] detect in neither runtime → nil, no exception.

#### Verification Commands
- [ ] `ace-test ace-runtime` green.

## Objective

Give both terminal runtimes one neutral contract to implement and all
consumers one API to call — the structural change that makes herdr an
equal partner instead of a side gem.

## Scope of Work

- **User Experience Scope**: developer/agent-facing intent API; runtime selection semantics.
- **System Behavior Scope**: registry, resolution, detection, error model, shared contract tests.
- **Interface Scope**: the contract gem's public API only (adapters: sibling subtasks).

### Deliverables
- Contract API + error model
- Shared adapter contract-test suite
- Selection/fallback documentation

## Out of Scope

- ❌ Adapter implementations (8wq.t.k86.1 / 8wq.t.k86.2)
- ❌ Consumer migrations (8wq.t.k86.3)
- ❌ HITL delivery intents (stay in ace-hitl/ace-herdr contracts)

## References

- Parent: 8wq.t.k86
- Precedent: ace-hitl provider registry
- Requirements oracle: consumer call sites in bundle.files
- Decisions (Captain, 2026-09-27): adapters live INSIDE the wrapper gems
  (ace-tmux/ace-herdr gain a dependency on ace-runtime; no gem renames —
  wrapper product identity stays, ADR-033 stability rationale); the
  contract ships the `ace-runtime send` neutral passthrough for the Fork
  Callback Rule.
