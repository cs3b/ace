# ACE Tmux Control Integrations - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Operator uses `ace-tmux` directly

**Goal**: Send a command into an ACE-managed tmux pane, wait for visible output, and capture recent text without using raw `tmux`.

```bash
ace-tmux send --pane dev:work.0 --command "ace-assign status"
ace-tmux wait --pane dev:work.0 --for output --pattern "Current step"
ace-tmux capture --pane dev:work.0 --lines 40
```

#### Expected Output

- The target pane receives the command.
- The wait operation completes when the expected output appears or fails clearly on timeout.
- Capture returns recent pane text suitable for operator inspection.

### Scenario 2: `ace-assign` delegates a fork through `ace-tmux`

**Goal**: Start a tmux-backed fork run and rely on the shared `ace-tmux` control surface for window reuse, pane dispatch, and diagnostics.

```bash
ace-assign fork-run --launch-mode tmux 010.01
```

#### Expected Output

- `ace-assign` resolves the tmux target, ensures or reuses the fork window, and starts the delegated agent in the target pane.
- Assignment state remains the source of truth for subtree completion or failure.
- If the delegated run stalls or fails, pane capture can support diagnostics without replacing assignment-state truth.

### Scenario 3: `ace-demo` uses tmux-aware recording directives

**Goal**: Record a tmux-driven demo with explicit attach, wait, send, and detach orchestration instead of raw tmux shell glue.

```bash
ace-demo record ace-assign/docs/demo/fork-provider.tape.yml
```

#### Expected Output

- The tape uses first-class tmux-aware recorder-control directives for attach, wait, send, and detach.
- Visible on-camera commands remain part of the recorded scenario when helpful.
- Recording behavior becomes deterministic without sleep-based orchestration hacks.

## Notes for Implementer

- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
