---
id: 8wq.t.k86.0
status: in-progress
priority: medium
created_at: "2026-09-27 13:29:29"
estimate: TBD
dependencies: []
tags: [ace-runtime, contract]
parent: 8wq.t.k86
bundle:
  presets: [project]
  files: [ace-tmux/lib/ace/tmux/organisms/control_surface.rb, ace-assign/lib/ace/assign/molecules/tmux_control_surface_runner.rb, ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb, ace-overseer/lib/ace/overseer/molecules/tmux_window_opener.rb, ace-hitl/lib/ace/hitl/providers/providers.rb]
  commands: []
needs_review: false
title: Define shared runtime intent contract (ace-runtime gem)
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
5. send: `send(pane:, command: nil, items: [])` where `items` is an
   ORDERED list of `{message: String} | {key: String}` — the only shape
   that preserves message/key interleaving. `command` is the submit-once
   shape (`--cmd`) and MUST be declared before every key: when `command`
   is present, `items` holds exclusively post-command keys; leading keys
   (`--key Esc --cmd run`) are a usage error before any transport call.
   One normative matrix for ALL adapters:
   - Plain-pane adapters deliver items in order: messages are raw text
     (no implicit submission), keys are keystrokes, each Enter submits
     pending text; trailing keys after `command` are post-submission
     keystrokes. Guaranteed shapes: `command` alone and
     `messages + single trailing Enter` (exactly one submission).
   - Agent-aware adapters (herdr) map text to agent-prompt semantics:
     `command` or the concatenated messages become ONE prompt that
     submits itself (so message-only input DOES submit once on agent
     panes — intended divergence from plain panes); at most one trailing
     Enter is dropped+reported; keys-only sequences go to agent keys;
     every other interleaving (keys between messages, multiple Enters,
     `command` with non-Enter keys, `command` mixed with messages) is
     rejected before any transport call.
   - An invocation with no send content at all is a usage error on both.
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
(`TMUX` / `HERDR_SESSION/HERDR_PANE`); both live → tmux (existing default), documented.
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
runtime.send(pane:, command: nil, items: [])
                                       # items: ORDERED {message:}|{key:}
                                       # entries — preserves interleaving;
                                       # when command is present, items are
                                       # exclusively trailing (post-command)
                                       # keys; leading keys are invalid.
                                       # The granular ops below are
                                       # convenience shapes of it.
runtime.send_command(pane:, command:)  # == send(command:)
runtime.send_text(pane:, text:)        # == send(items: [{message: text}])
runtime.send_keys(pane:, keys:)        # == send(items: keys.map { {key: _1} })
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

**Contract CLI:** the gem ships one thin agent-facing passthrough — `ace-runtime send [--runtime tmux|herdr] [--cmd TEXT] [--msg TEXT...] [--key NAME...] --pane TARGET`, at least one input required (keys-only valid; none = usage error before transport) — resolving the configured runtime and delegating to `runtime.send` with the matrix semantics above (plain-pane ordered delivery; agent-pane single-prompt shapes). This is the runtime-neutral callback command (decision 2026-09-27, Captain: assign's Fork Callback Rule prescribes it instead of `ace-tmux send`). No other CLI surface. The contract test suite MUST include: the callback form (`--msg ... --key Enter`) submits exactly once on BOTH adapters; interleaved items (`msg, key, msg`) deliver distinctly on plain panes and are rejected before any send on agent panes.

**Edge Cases:** `detect` inside neither runtime returns nil (assign auto selects headless; overseer reports missing runtime context); ensure_window with an existing name is idempotent by name.

### Success Criteria

- [ ] Contract gem publishes the 11-op API (op 7 covering output, agent, and the four lifecycle conditions) + error model incl. `WaitTimeoutError`/`SendStalledError` + the `ace-runtime send` passthrough; adapters are duck-typed (no dependency on either adapter gem).
- [ ] Shared contract-test suite exists and is documented as the acceptance bar for any adapter (shared-examples pattern), covering all wait conditions and the send error triad (rejected / stalled / timeout).
- [ ] Resolution: explicit name, unknown name (fail closed, available list), auto-detection both-runtimes (tmux wins, documented).

### Reviewed Decisions (2026-09-28)

- Contract package is ace-runtime. Adapters live inside existing ace-tmux/ace-herdr; no renamed adapter gems. Consumer gemspecs install those wrappers as adapter dependencies; neutral code must not call runtime-native APIs directly. This corrects the contradictory earlier demand for installed in-wrapper adapters but no wrapper dependency.
- Callback is ace-runtime send. Per-consumer configuration keys are retained except tmux_window_presets becomes window_presets with no legacy alias. Explicit runtime wins; auto detects tmux first if both are live; Lab configuration explicitly chooses herdr.
- Auto-detection is side-effect-free and uses TMUX/ACE_TMUX_SESSION or HERDR_SESSION plus HERDR_PANE (HERDR_WORKSPACE_ID may refine context). The earlier HERDR_ENV assumption was unsupported. Adapter operations verify runtime availability/current context; explicit unavailable herdr errors, never silently becomes headless. Only assign auto outside any runtime selects headless.
- Tmux readiness uses documented output-stability heuristic; Herdr uses native agent state. Generic status text names the selected runtime. Demo attach/detach stays tmux-local with explicit unsupported error under herdr.
- k86.3 owns terminal paths in ace-git-worktree and E2E runners before Lab acceptance. qk0 separately removes the old runtime=lab engine and changes role coordination.
- Pane-exited is a runtime observation, not assignment success or safe prune evidence: disappearance satisfies that wait, but accepted outcome/process-tree termination still require separate receipts. Positive preservation gates remain mandatory.
- Pane preparation must yield a writable live shell/agent target retained after a submitted command exits; adapter may create/prepare that target using native APIs. Bare command panes may disappear and do not satisfy preparation. Installed tests must verify both runtimes; no assertion of untested Herdr behavior.

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
- Decisions (Captain, 2026-09-27; re-confirmed same day): adapters live
  INSIDE the wrapper gems (ace-tmux/ace-herdr gain a dependency on
  ace-runtime; no gem renames — wrapper product identity stays, ADR-033
  stability rationale); the contract ships the `ace-runtime send` neutral
  passthrough for the Fork Callback Rule.

## Lab-readiness review scope (2026-09-28)

This draft retains the existing detailed send/wait contract and the Captain's adapter-location and callback decisions. No runtime code is changed in this spec pass. Review must check all four child specs before parent promotion. Executed tests and independent current-head verdict gate implementation delivery; CI is advisory. Earlier text is preserved in history/pre-lab-spec-review.md only for provenance.

### Callback resolution and wait observations

The neutral CLI accepts optional --runtime tmux|herdr. Resolution: explicit flag > inherited ACE_RUNTIME > configured runtime > detect. Consumer forks set ACE_RUNTIME and target context to the caller backend. Missing explicit backend/adapter fails clearly without resend or silent switch. Runtime objects remain backend-specific while their return identity is opaque.

ensure_window identity is scoped by the resolved session/workspace plus normalized name; same-name windows in another workspace are not reused. Conflicting existing root/preset is an explicit conflict rather than silently returning the wrong worktree. wait_lifecycle reports the condition only, never authorizes completion/prune.
