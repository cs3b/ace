---
id: 8wq.t.k86
status: in-progress
priority: high
created_at: "2026-09-27 13:29:05"
estimate: TBD
dependencies: [8wq.t.k84, 8wm.t.vs0]
tags: [ace-runtime, ace-tmux, ace-herdr, assign, overseer, demo]
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/molecules/runtime_control_surface_runner.rb, ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, ace-overseer/lib/ace/overseer/molecules/window_opener.rb, ace-overseer/lib/ace/overseer/organisms/work_on_orchestrator.rb, ace-overseer/lib/ace/overseer/organisms/prune_orchestrator.rb, ace-overseer/.ace-defaults/overseer/config.yml, ace-demo/lib/ace/demo/molecules/runtime_directive_executor.rb, ace-tmux/lib/ace/tmux/organisms/control_surface.rb, ace-herdr/docs/usage.md, .ace-tasks/_archive/8w/y/8wq.t.k84-ace-herdr-match-ace-tmux/8wq.t.k84-ace-herdr-match-ace-tmux-cli-and.s.md]
  commands: []
needs_review: false
title: "Runtime-switchable terminal surface: ace-herdr equal partner to ace-tmux"
position: 6o0002
---

# Runtime-switchable terminal surface: ace-herdr equal partner to ace-tmux

## Behavioral Specification

### User Experience

- **Input**: ACE consumers (ace-assign fork launches, ace-overseer work-on
  window opening and pruning, ace-demo directives) express terminal intents
  through ONE contract; the active terminal runtime is chosen by
  configuration (`runtime: tmux | herdr | auto` via the ADR-022 cascade,
  `auto` detecting the live runtime from the environment), not by which gem
  the consumer happens to depend on.
- **Process**: with `runtime: herdr`, the same `ace-assign fork run
  --callback`, overseer work-on flow, and demo directives operate against
  herdr workspaces/tabs/panes instead of tmux sessions/windows/panes —
  no workflow relearning, no per-consumer forks of logic.
- **Output**: observable behavior per intent is identical modulo the
  runtime's native model (e.g. callbacks arrive at the caller's pane;
  windows open rooted at the worktree; agent panes get herdr's stronger
  agent semantics). `runtime: tmux` behavior is unchanged (regression gate).

### Expected Behavior

Today ace-assign, ace-overseer, and ace-demo hard-depend on `ace-tmux ~> 0.17`
and call its Ruby APIs directly; the assign Fork Callback Rule in
`drive.wf.md` even prescribes the literal command `ace-tmux send`. After this
task family:

1. A neutral contract (new gem `ace-runtime`, equal-partner home following
   the ace-hitl provider-registry precedent) defines the shared intent API
   — the exact operation set consumers use today: context detection
   (in-runtime? current session/workspace/window/tab/pane), ensure
   named window/tab rooted at a path (idempotent), prepare pane, select/
   focus, send command text / keystrokes, capture recent output, wait for
   output pattern / agent readiness, close/kill window/tab, list
   windows/panes, window-name sanitization, and a typed error model.
2. `ace-tmux` and `ace-herdr` each ship an adapter implementing the
   contract over their existing surfaces (tmux: ControlSurface/TmuxExecutor
   delegation; herdr: the 8wq.t.k84 parity surface with agent-aware send
   and the tmux session → herdr workspace mapping).
3. Consumers select the runtime via config: ace-assign's
   `execution.launch_mode` gains `herdr` (with `auto` preferring the
   detected live runtime), overseer's `tmux_window_presets` becomes a
   runtime-neutral preset key, demo directives resolve through the
   contract. Consumer gemspecs depend on the contract gem + adapters,
   using adapter registration only, never direct tmux APIs.
4. Agent-facing workflow text follows suit: the assign Fork Callback Rule
   prescribes the runtime-neutral send command; the env contract
   (`ACE_TMUX_SESSION` today) gets a herdr counterpart derived from
   `HERDR_*`.

### Interface Contract

```bash
# Configuration (per consumer, ADR-022 cascade)
# ace-assign: execution.launch_mode: auto|headless|tmux|herdr   (auto detects)
# ace-overseer: runtime: tmux|herdr|auto + window_presets (runtime-neutral)
# Contract gem registry: adapters registered for "tmux" and "herdr";
# selection order: explicit config > auto-detection (TMUX / HERDR_SESSION/HERDR_PANE)

# Agent-facing (drive.wf.md Fork Callback Rule becomes):
#   <runtime-neutral send command> --pane "$ACE_ASSIGN_CALLBACK_PANE" --msg "..." --key Enter
```

**Error Handling:**
- Unknown runtime name in config: fail closed at resolution with the available list (ace-hitl provider parity).
- Requested runtime unavailable (binary/socket missing): explicit error naming the runtime; a detected-but-unavailable backend never falls back. Only assign auto with no detected runtime selects headless.
- Contract operations raise typed contract errors; adapters map runtime-native errors into them.

**Edge Cases:**
- `auto` with both runtimes live: tmux wins today (existing behavior); explicit config overrides — documented default.
- Idempotent ensure-window under both runtimes: same normalized name within the resolved session/workspace → same target, no duplicates; conflicting root/preset errors.
- herdr pane ids are opaque handles; the contract never predicts them (tmux `%id` habit must not leak into the contract).

### Success Criteria

- [ ] **Equal partnership**: with `runtime: herdr`, fork-run-with-callback, overseer work-on window opening, and demo wait/send directives all function against herdr end-to-end.
- [ ] **Zero tmux regression**: with `runtime: tmux` (and for assign, `launch_mode: tmux|auto`), existing behavior is unchanged — the full existing consumer test suites stay green.
- [ ] **Decoupled gemspecs**: ace-assign, ace-overseer, and ace-demo depend on ace-runtime plus existing wrapper gems for installed adapters; no direct tmux API calls remain.
- [ ] **Neutral contract**: neither adapter gem depends on the other; contract tests run against BOTH adapters (shared examples, ace-hitl provider-test pattern).
- [ ] **Workflow text updated**: the Fork Callback Rule prescribes no runtime-specific command.

### Reviewed Decisions (2026-09-28)

- Contract package is ace-runtime. Adapters live inside existing ace-tmux/ace-herdr; no renamed adapter gems. Consumer gemspecs install those wrappers as adapter dependencies; neutral code must not call runtime-native APIs directly. This corrects the contradictory earlier demand for installed in-wrapper adapters but no wrapper dependency.
- Callback is ace-runtime send. Per-consumer configuration keys are retained except tmux_window_presets becomes window_presets with no legacy alias. Explicit runtime wins; auto detects tmux first if both are live; Lab configuration explicitly chooses herdr.
- Auto-detection is side-effect-free and uses TMUX/ACE_TMUX_SESSION or HERDR_SESSION plus HERDR_PANE (HERDR_WORKSPACE_ID may refine context). The earlier HERDR_ENV assumption was unsupported. Adapter operations verify runtime availability/current context; explicit unavailable herdr errors, never silently becomes headless. Only assign auto outside any runtime selects headless.
- Tmux readiness uses documented output-stability heuristic; Herdr uses native agent state. Generic status text names the selected runtime. Demo attach/detach stays tmux-local with explicit unsupported error under herdr.
- k86.3 owns terminal paths in ace-git-worktree and E2E runners before Lab acceptance. qk0 separately removes the old runtime=lab engine and changes role coordination.
- Pane-exited is a runtime observation, not assignment success or safe prune evidence: disappearance satisfies that wait, but accepted outcome/process-tree termination still require separate receipts. Positive preservation gates remain mandatory.
- Pane preparation must yield a writable live shell/agent target retained after a submitted command exits; adapter may create/prepare that target using native APIs. Bare command panes may disappear and do not satisfy preparation. Installed tests must verify both runtimes; no assertion of untested Herdr behavior.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Orchestrator (4 subtasks)
- **Slice Outcome**: any ACE consumer operates either terminal runtime through one contract.
- **Advisory Size**: large
- **Context Dependencies**: bundle.files above; subtasks list their own explicitly (no implicit inheritance).

### Verification Plan

#### Unit / Component Validation
- [ ] Shared contract examples pass against both adapters (tmux fake executor + herdr fake executor).
- [ ] Runtime resolution: explicit config, auto-detection, unknown name, unavailable runtime.

#### Integration / E2E Validation (if cross-boundary behavior exists)
- [ ] `runtime: herdr` end-to-end: assign fork-run with callback delivered to the caller's pane; overseer work-on opens a herdr tab rooted at the worktree.
- [ ] `runtime: tmux` regression: existing consumer suites green.

#### Failure / Invalid-Path Validation
- [ ] herdr selected but binary unavailable: explicit error, including auto when that backend was detected; headless only when no backend was detected.
- [ ] Unknown runtime key: fail closed with available list.

#### Verification Commands
- [ ] `ace-test ace-runtime` / `ace-test ace-tmux` / `ace-test ace-herdr` / `ace-test ace-assign` / `ace-test ace-overseer` / `ace-test ace-demo` — all green.

## Objective

Today tmux is structurally privileged in ACE: three gems hard-depend on
ace-tmux and one workflow prescribes its literal CLI. This task family makes
ace-herdr an equal partner — one shared intent API, two adapters, config-
driven selection — so the toolkit follows whichever terminal runtime the
operator actually runs (the lab already runs Herdr; the Herdr status pane
is referenced in ace-overseer today).

## Scope of Work

- **User Experience Scope**: assign fork launches (+callbacks), overseer work-on/prune window lifecycle, demo tmux directives — each runtime-neutral.
- **System Behavior Scope**: shared intent contract + registry + selection; tmux and herdr adapters; consumer migration incl. config keys and workflow text.
- **Interface Scope**: the contract gem's public API, consumer config keys, the Fork Callback Rule command.

### Deliverables

#### Behavioral Specifications
- Intent contract definitions (11-op inventory, above)
- Runtime selection + fallback rules
- Per-consumer migration contracts

#### Validation Artifacts
- Shared adapter contract tests
- Draft usage scenarios in `ux/usage.md`

### Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| ace-runtime contract gem | 8wq.t.k86.0 | -- | KEPT |
| runtime selection (config+auto) | 8wq.t.k86.0 | -- | KEPT |
| tmux adapter | 8wq.t.k86.1 | -- | KEPT |
| herdr adapter | 8wq.t.k86.2 | -- | KEPT |
| launch_mode `herdr` value | 8wq.t.k86.3 | -- | KEPT |
| runtime-neutral callback rule | 8wq.t.k86.3 | -- | KEPT |
| `tmux_window_presets` key | (pre-existing) | 8wq.t.k86.3 | REPLACED by runtime-neutral preset key |

**Churn threshold**: if >30% of introduced concepts get removed by later subtasks, consolidate.

## Out of Scope

- Included before Lab acceptance: terminal setup in ace-test-runner-e2e, retained overseer/runtime scenarios and ace-git-worktree terminal shell-outs migrate in k86.3. Human-only demo attach/detach remains explicitly tmux-local.
- ❌ **HITL delivery/queue concerns** — 8wm.t.y23 / 8wm.t.vs2 own those (coordinate, do not supersede).
- ❌ **Intent parity work itself** — 8wq.t.k84 delivers the herdr surface this family builds on.

## References

- Usage documentation: `ux/usage.md` (draft usage scenarios)
- Consumer operation inventory + config key map (research 2026-09-27, this session)
- Precedent: ace-hitl provider registry (`ace-hitl/lib/ace/hitl/providers/providers.rb`)
- Layer-ownership doctrine: docs/tools.md#agent-engineering-practices

## Lab-readiness review scope (2026-09-28)

This draft retains the existing detailed send/wait contract and the Captain's adapter-location and callback decisions. No runtime code is changed in this spec pass. Review must check all four child specs before parent promotion. Executed tests and independent current-head verdict gate implementation delivery; CI is advisory. Earlier text is preserved in history/pre-lab-spec-review.md only for provenance.

## Progress reconciliation — 2026-10-04, post-PR364

Contract and both adapters are delivered; consumer migration code is merged. k86.3 retains its original clean-install/retained-pane/live Herdr acceptance. The current dependency direction needs an acyclic resolution before all consumer installations include Herdr. Do not mark this parent done or dispatch 1w5 as prerequisite-complete merely because PR364 is merged. The remaining work is explicit in k86.3, not hidden in this umbrella.
