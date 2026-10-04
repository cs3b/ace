---
id: 8wq.t.k86.3
status: in-progress
priority: medium
created_at: "2026-09-27 13:29:29"
estimate: TBD
dependencies: [8wq.t.k86.1, 8wq.t.k86.2, 8x1.t.hym]
tags: [assign, overseer, demo, migration]
parent: 8wq.t.k86
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/molecules/tmux_control_surface_runner.rb, ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb, ace-assign/lib/ace/assign/cli/commands/fork_run.rb, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, ace-overseer/lib/ace/overseer/molecules/tmux_window_opener.rb, ace-overseer/lib/ace/overseer/organisms/work_on_orchestrator.rb, ace-overseer/lib/ace/overseer/organisms/prune_orchestrator.rb, ace-overseer/.ace-defaults/overseer/config.yml, ace-demo/lib/ace/demo/molecules/tmux_directive_executor.rb, ace-git-worktree/lib/ace/git/worktree/commands/create_command.rb, ace-test-runner-e2e/lib/ace/test/end_to_end_runner/molecules/setup_executor.rb, ace-test-runner-e2e/test/feat/setup_executor_tmux_test.rb, ace-overseer/test/e2e, .ace-tasks/8x1.t.hym-fix-astra-follow-ups-pointer/8x1.t.hym-fix-astra-follow-ups-pointer-only-record.s.md, .ace-tasks/8x1.t.hym-fix-astra-follow-ups-pointer/ux/usage.md]
  commands: []
needs_review: false
title: Migrate assign overseer and demo consumers
worktree:
  branch: k86.3-consumer-runtime-migration
  path: .ace-wt/k86-3-consumer-runtime-migration
  target_branch: main
---

# Migrate assign, overseer and demo consumers

## Behavioral Specification

### User Experience

- **Input**: operators set the terminal runtime in config (assign:
  `execution.launch_mode: auto|headless|tmux|herdr`; overseer:
  `runtime: tmux|herdr|auto`; demo: per-directive runtime or inherited); agents
  keep using the same workflows (fork run, work-on, demo record).
- **Process**: consumers express intents through the contract
  (8wq.t.k86.0); runtime adapters (k86.1/k86.2) execute. `auto` detects
  the live runtime and, for assign, falls back to headless outside any
  runtime (today's behavior).
- **Output**: identical observable workflows on either runtime; callbacks
  land in the caller's pane; gemspecs install the neutral contract and existing wrapper gems containing the adapters.

### Expected Behavior

1. **ace-assign**: `TmuxControlSurfaceRunner` becomes a contract-backed
   runtime runner; launch mode resolution gains `herdr` (explicit) and
   `auto` detects herdr when `HERDR_SESSION/HERDR_PANE` is live; fork-window naming,
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
   contract (+ adapters), using adapter registration only, never direct tmux APIs.

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

**Error Handling:** requested runtime unavailable → explicit error; assign auto selects headless only when no backend is detected; unknown runtime value → fail closed at config resolution with the available list.

**Edge Cases:** existing `launch_mode: tmux` configs keep working verbatim (no rename forced); overseer `tmux_window_presets` legacy key still read during transition? — pre-1.0 policy says remove, not compat-shim (ADR-024): replace the key and update docs/presets in the same change.

### Success Criteria

- [ ] `runtime: herdr` end-to-end: assign fork-run with `--callback` delivers the callback to the caller's herdr pane; overseer work-on opens a herdr tab rooted at the worktree; prune closes it.
- [x] `runtime: tmux` / `launch_mode: tmux|auto`: all existing consumer test suites green — zero behavior change (regression gate).
- [x] Consumer code depends on the contract; gemspecs may depend on the existing wrapper gems to install their adapters.
- [x] drive.wf.md prescribes no runtime-specific command.
- [x] Overseer config uses the runtime-neutral preset key.

### Reviewed Decisions (2026-09-28)

- Contract package is ace-runtime. Adapters live inside existing ace-tmux/ace-herdr; no renamed adapter gems. Consumer gemspecs install those wrappers as adapter dependencies; neutral code must not call runtime-native APIs directly. This corrects the contradictory earlier demand for installed in-wrapper adapters but no wrapper dependency.
- Callback is ace-runtime send. Per-consumer configuration keys are retained except tmux_window_presets becomes window_presets with no legacy alias. Explicit runtime wins; auto detects tmux first if both are live; Lab configuration explicitly chooses herdr.
- Auto-detection is side-effect-free and uses TMUX/ACE_TMUX_SESSION or HERDR_SESSION plus HERDR_PANE (HERDR_WORKSPACE_ID may refine context). The earlier HERDR_ENV assumption was unsupported. Adapter operations verify runtime availability/current context; explicit unavailable herdr errors, never silently becomes headless. Only assign auto outside any runtime selects headless.
- Tmux readiness uses documented output-stability heuristic; Herdr uses native agent state. Generic status text names the selected runtime. Demo attach/detach stays tmux-local with explicit unsupported error under herdr.
- k86.3 owns terminal paths in ace-git-worktree and E2E runners before Lab acceptance. qk0 separately removes the old runtime=lab engine and changes role coordination.
- Pane-exited is a runtime observation, not assignment success or safe prune evidence: disappearance satisfies that wait, but accepted outcome/process-tree termination still require separate receipts. Positive preservation gates remain mandatory.
- Pane preparation must yield a writable live shell/agent target retained after a submitted command exits; adapter may create/prepare that target using native APIs. Bare command panes may disappear and do not satisfy preparation. Installed tests must verify both runtimes; no assertion of untested Herdr behavior.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask of 8wq.t.k86 (final slice — consumer-visible outcome)
- **Slice Outcome**: runtime switch is a config change for real workflows
- **Advisory Size**: large
- **Context Dependencies**: 8wq.t.k86.0 (contract), k86.1 (tmux adapter), k86.2 (herdr adapter); bundle.files above.

### Verification Plan

#### Unit / Component Validation
- [x] Launch-mode resolution matrix: auto/headless/tmux/herdr × detected runtime (existing assign tests extended).
- [x] Overseer window-open/prune via contract on both runtimes (fake adapters).
- [x] Demo wait directives: all four lifecycle conditions pass against BOTH adapters (shared contract examples — regression preservation).

#### Integration / E2E Validation (if cross-boundary behavior exists)
- [ ] `runtime: herdr`: fork run --callback round-trip on live herdr (scripted mocks are component tests, not a substitute for installed acceptance); overseer work-on opens herdr tab.
- [x] `runtime: tmux` regression: existing suites green.

#### Failure / Invalid-Path Validation
- [x] herdr configured but unavailable: explicit error; detected unavailable backend remains an error even in auto. Auto with no backend reports headless.
- [x] Unknown runtime value in config: fail closed with available list.

#### Verification Commands
- [x] `ace-test ace-assign` / `ace-test ace-overseer` / `ace-test ace-demo` — all green.

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

- Included: migrate runtime-dependent E2E setup and retained overseer scenarios.
- Included: migrate ace-git-worktree terminal creation/probes to the runtime contract; forge behavior is owned by qk1.0.
- ❌ Contract/adapter work (earlier subtasks)

## References

- Parent: 8wq.t.k86; contract: 8wq.t.k86.0; adapters: k86.1, k86.2

## Lab-readiness review scope (2026-09-28)

This draft retains the existing detailed send/wait contract and the Captain's adapter-location and callback decisions. No runtime code is changed in this spec pass. Review must check all four child specs before parent promotion. Executed tests and independent current-head verdict gate implementation delivery; CI is advisory. Earlier text is preserved in history/pre-lab-spec-review.md only for provenance.

### Additional consumer acceptance

- ace-git-worktree terminal start/window/probe flows use the same configured runtime, preserve root/cwd and never launch tmux when herdr is explicit.
- ace-test-runner-e2e setup and retained overseer scenarios exercise both adapters through public ACE entrypoints. Required live Herdr proof must not be replaced by a mocked "scripted equivalent".
- Run ace-test ace-git-worktree all and ace-test ace-test-runner-e2e all, plus existing three consumer suites and retained E2E scenarios. Both-runtime fixture matrix covers absent/unknown backend, callback exactly once, context propagation, worktree tab open and accepted prune.
- Runtime selection for neutral callback follows explicit --runtime flag, then inherited ACE_RUNTIME from the caller, then ADR-022 runtime configuration, then detect; a child inherits caller backend so nested tmux/herdr cannot misroute a callback.

## Herdr acceptance prerequisite — 2026-10-04

ACE 8x1.t.hym owns pointer-only prepared-pane replacement and public CLI materialization errors. Implement consumers in parallel if useful, but accept/merge this scope only after hym is delivered and its restarted-adapter/native-tab scenario passes through the installed consumer. Do not broaden the done k86.2 contract backwards or duplicate the repair here.
