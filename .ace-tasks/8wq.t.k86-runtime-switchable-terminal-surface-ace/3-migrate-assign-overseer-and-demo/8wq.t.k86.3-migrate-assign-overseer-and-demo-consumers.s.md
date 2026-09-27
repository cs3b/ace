---
id: 8wq.t.k86.3
status: draft
priority: medium
created_at: "2026-09-27 13:29:29"
estimate: TBD
dependencies: [8wq.t.k86.1, 8wq.t.k86.2]
tags: [assign, overseer, demo, migration]
parent: 8wq.t.k86
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/molecules/tmux_control_surface_runner.rb, ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb, ace-assign/lib/ace/assign/cli/commands/fork_run.rb, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, ace-overseer/lib/ace/overseer/molecules/tmux_window_opener.rb, ace-overseer/lib/ace/overseer/organisms/work_on_orchestrator.rb, ace-overseer/lib/ace/overseer/organisms/prune_orchestrator.rb, ace-overseer/.ace-defaults/overseer/config.yml, ace-demo/lib/ace/demo/molecules/tmux_directive_executor.rb]
  commands: []
---

# Migrate assign, overseer and demo consumers

## Behavioral Specification

### User Experience

- **Input**: operators set the terminal runtime in config (assign:
  `execution.launch_mode: auto|headless|tmux|herdr`; overseer:
  `runtime: tmux|herdr`; demo: per-directive runtime or inherited); agents
  keep using the same workflows (fork run, work-on, demo record).
- **Process**: consumers express intents through the contract
  (8wq.t.k86.0); runtime adapters (k86.1/k86.2) execute. `auto` detects
  the live runtime and, for assign, falls back to headless outside any
  runtime (today's behavior).
- **Output**: identical observable workflows on either runtime; callbacks
  land in the caller's pane; gemspecs no longer hard-depend on ace-tmux.

### Expected Behavior

1. **ace-assign**: `TmuxControlSurfaceRunner` becomes a contract-backed
   runtime runner; launch mode resolution gains `herdr` (explicit) and
   `auto` detects herdr when `HERDR_ENV` is live; fork-window naming,
   pane preparation, invocation send, capture, and metadata merge
   (launch_mode + runtime-neutral pane/session fields) work on both
   runtimes; `--callback` works under herdr (callback pane from the
   contract context).
2. **ace-overseer**: `TmuxWindowOpener` → contract ensure_window;
   `tmux_window_presets` config key replaced by a runtime-neutral preset
   key (tmux presets keep working unchanged); prune closes windows/tabs
   via the contract; the work-on flow text stops saying "tmux window"
   where it means "terminal window".
3. **ace-demo**: demo YAML directives (`wait`, `send`) resolve through the
   contract — including the four lifecycle wait conditions demo uses
   today (`window-exists`, `window-active`, `pane-exists`, `pane-exited`),
   which must behave identically on both adapters; `attach`/`detach` stay
   tmux-local (human-facing, per k86.0 validation default).
4. **Fork Callback Rule** (`assign/drive.wf.md`): the prescribed literal
   `ace-tmux send ...` becomes the contract's neutral passthrough
   `ace-runtime send --pane "$ACE_ASSIGN_CALLBACK_PANE" --msg "..." --key Enter`
   (decision 2026-09-27, Captain); the rule keeps its "use the tool
   directly, don't invent wrappers" intent.
5. **Env propagation**: `ACE_TMUX_SESSION`-style propagation becomes
   runtime-neutral (contract context carries it; herdr children already
   receive `HERDR_*`).
6. **Gemspecs**: ace-assign, ace-overseer, ace-demo depend on the
   contract (+ adapters), not on `ace-tmux` directly.

### Interface Contract

```bash
# Config (ADR-022 cascade), e.g.:
# .ace/assign/config.yml:  execution.launch_mode: herdr
# .ace/overseer/config.yml: runtime: herdr + window_presets: {"work-on-task": work-on-task}

# Agent-facing callback rule becomes ONE neutral command (contract CLI):
#   ace-runtime send --pane "$ACE_ASSIGN_CALLBACK_PANE" --msg "..." --key Enter
#   (routes to the configured runtime; mixed --msg/--key sequencing and
#    agent-pane semantics per the k84 send contract)
```

**Error Handling:** requested runtime unavailable → explicit error (assign `auto` → headless fallback, unchanged); unknown runtime value → fail closed at config resolution with the available list.

**Edge Cases:** existing `launch_mode: tmux` configs keep working verbatim (no rename forced); overseer `tmux_window_presets` legacy key still read during transition? — pre-1.0 policy says remove, not compat-shim (ADR-024): replace the key and update docs/presets in the same change.

### Success Criteria

- [ ] `runtime: herdr` end-to-end: assign fork-run with `--callback` delivers the callback to the caller's herdr pane; overseer work-on opens a herdr tab rooted at the worktree; prune closes it.
- [ ] `runtime: tmux` / `launch_mode: tmux|auto`: all existing consumer test suites green — zero behavior change (regression gate).
- [ ] No consumer gemspec depends on `ace-tmux` directly.
- [ ] drive.wf.md prescribes no runtime-specific command.
- [ ] Overseer config uses the runtime-neutral preset key.

### Validation Questions

- [ ] Should `auto` prefer herdr when both runtimes are live (lab reality) instead of tmux? Default: tmux first (existing behavior), explicit config overrides.
- [ ] Callback rollout: switch drive.wf.md to `ace-runtime send` in this task (chosen default) — confirm the neutral command is acceptable for every fork context (headless forks have no pane; rule already conditions on callback being requested).

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask of 8wq.t.k86 (final slice — consumer-visible outcome)
- **Slice Outcome**: runtime switch is a config change for real workflows
- **Advisory Size**: large
- **Context Dependencies**: 8wq.t.k86.0 (contract), k86.1 (tmux adapter), k86.2 (herdr adapter); bundle.files above.

### Verification Plan

#### Unit / Component Validation
- [ ] Launch-mode resolution matrix: auto/headless/tmux/herdr × detected runtime (existing assign tests extended).
- [ ] Overseer window-open/prune via contract on both runtimes (fake adapters).
- [ ] Demo wait directives: all four lifecycle conditions pass against BOTH adapters (shared contract examples — regression preservation).

#### Integration / E2E Validation (if cross-boundary behavior exists)
- [ ] `runtime: herdr`: fork run --callback round-trip on live herdr (or scripted equivalent); overseer work-on opens herdr tab.
- [ ] `runtime: tmux` regression: existing suites green.

#### Failure / Invalid-Path Validation
- [ ] herdr configured but unavailable: explicit error; assign `auto` → headless fallback message.
- [ ] Unknown runtime value in config: fail closed with available list.

#### Verification Commands
- [ ] `ace-test ace-assign` / `ace-test ace-overseer` / `ace-test ace-demo` — all green.

## Objective

Make "switch to herdr" a configuration change for the workflows agents
actually run — fork execution, work-on, demos — instead of a structural
rewrite. This is where the equal-partner promise becomes observable.

## Scope of Work

- **User Experience Scope**: assign fork launches + callbacks, overseer work-on/prune, demo wait/send directives; config surface for runtime choice.
- **System Behavior Scope**: consumer call sites route through the contract; env propagation runtime-neutral; gemspec decoupling.
- **Interface Scope**: consumer config keys, drive.wf.md callback rule, gemspecs.

### Deliverables
- Migrated consumers (assign, overseer, demo)
- Updated workflow text + config defaults/docs
- Regression evidence on tmux path

## Out of Scope

- ❌ e2e runner raw tmux + overseer e2e scenario updates (follow-up)
- ❌ ace-git-worktree shell-outs (follow-up; stays tmux-default)
- ❌ Contract/adapter work (earlier subtasks)

## References

- Parent: 8wq.t.k86; contract: 8wq.t.k86.0; adapters: k86.1, k86.2
