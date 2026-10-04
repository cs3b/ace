# Non-normative earlier draft

---
id: 8wq.t.k86
status: draft
priority: high
created_at: "2026-09-27 13:29:05"
estimate: TBD
dependencies: [8wq.t.k84, 8wm.t.vs0]
tags: [ace-runtime, ace-tmux, ace-herdr, assign, overseer, demo]
bundle:
  presets: ["project"]
  files:
    - ace-assign/lib/ace/assign/molecules/tmux_control_surface_runner.rb
    - ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb
    - ace-assign/handbook/workflow-instructions/assign/drive.wf.md
    - ace-overseer/lib/ace/overseer/molecules/tmux_window_opener.rb
    - ace-overseer/lib/ace/overseer/organisms/work_on_orchestrator.rb
    - ace-overseer/lib/ace/overseer/organisms/prune_orchestrator.rb
    - ace-overseer/.ace-defaults/overseer/config.yml
    - ace-demo/lib/ace/demo/molecules/tmux_directive_executor.rb
    - ace-tmux/lib/ace/tmux/organisms/control_surface.rb
    - ace-herdr/docs/usage.md
    - .ace-tasks/8wq.t.k84-ace-herdr-match-ace-tmux/8wq.t.k84-ace-herdr-match-ace-tmux-cli-and.s.md
  commands: []
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
   not on ace-tmux directly.
4. Agent-facing workflow text follows suit: the assign Fork Callback Rule
   prescribes the runtime-neutral send command; the env contract
   (`ACE_TMUX_SESSION` today) gets a herdr counterpart derived from
   `HERDR_*`.

### Interface Contract

```bash
# Configuration (per consumer, ADR-022 cascade)
# ace-assign: execution.launch_mode: auto|headless|tmux|herdr   (auto detects)
# ace-overseer: runtime: tmux|herdr + window_presets (runtime-neutral)
# Contract gem registry: adapters registered for "tmux" and "herdr";
# selection order: explicit config > auto-detection (TMUX / HERDR_ENV)

# Agent-facing (drive.wf.md Fork Callback Rule becomes):
#   <runtime-neutral send command> --pane "$ACE_ASSIGN_CALLBACK_PANE" --msg "..." --key Enter
```

**Error Handling:**
- Unknown runtime name in config: fail closed at resolution with the available list (ace-hitl provider parity).
- Requested runtime unavailable (binary/socket missing): explicit error naming the runtime and the fallback rule (`auto` falls back to headless for assign, matching today's tmux behavior).
- Contract operations raise typed contract errors; adapters map runtime-native errors into them.

**Edge Cases:**
- `auto` with both runtimes live: tmux wins today (existing behavior); explicit config overrides — documented default.
- Idempotent ensure-window under both runtimes: same name → same target, no duplicates.
- herdr pane ids are opaque handles; the contract never predicts them (tmux `%id` habit must not leak into the contract).

### Success Criteria

- [ ] **Equal partnership**: with `runtime: herdr`, fork-run-with-callback, overseer work-on window opening, and demo wait/send directives all function against herdr end-to-end.
- [ ] **Zero tmux regression**: with `runtime: tmux` (and for assign, `launch_mode: tmux|auto`), existing behavior is unchanged — the full existing consumer test suites stay green.
- [ ] **Decoupled gemspecs**: ace-assign, ace-overseer, and ace-demo no longer depend on `ace-tmux` directly; they depend on the contract (+ adapters as appropriate).
- [ ] **Neutral contract**: neither adapter gem depends on the other; contract tests run against BOTH adapters (shared examples, ace-hitl provider-test pattern).
- [ ] **Workflow text updated**: the Fork Callback Rule prescribes no runtime-specific command.

### Validation Questions

- [ ] **Requirement Clarity**: contract home confirmed as new gem `ace-runtime` (decision record in draft; veto window open until review).
- [ ] **Consumer set**: ace-git-worktree (binary-probe, `start`/`window` shell-outs) and e2e runners (raw tmux) — migrate now or follow-up? Default: follow-up.
- [ ] **Selection key**: one shared `runtime:` key across consumers vs per-consumer keys (`execution.launch_mode` for assign)? Default: per-consumer keys preserved, mapping onto the shared registry.
- [ ] **Success Definition**: does "equal partner" require the overseer status-pane phrase ("Herdr status pane") to become config-driven?

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
- [ ] herdr selected but binary unavailable: explicit error (assign `auto` falls back headless, documented).
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

- ❌ **e2e runner raw tmux** (`ace-test-runner-e2e` setup_executor) and overseer e2e scenario updates — follow-up once runtime selection lands.
- ❌ **ace-git-worktree migration** (currently binary-probes `ace-tmux start/window`) — follow-up; default stays tmux.
- ❌ **HITL delivery/queue concerns** — 8wm.t.y23 / 8wm.t.vs2 own those (coordinate, do not supersede).
- ❌ **Intent parity work itself** — 8wq.t.k84 delivers the herdr surface this family builds on.

## References

- Usage documentation: `ux/usage.md` (draft usage scenarios)
- Consumer operation inventory + config key map (research 2026-09-27, this session)
- Precedent: ace-hitl provider registry (`ace-hitl/lib/ace/hitl/providers/providers.rb`)
- Layer-ownership doctrine: docs/tools.md#agent-engineering-practices
