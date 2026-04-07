# Visible tmux-backed fork execution - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Run a forked subtree visibly in tmux

**Goal**: An operator launches a forked subtree and watches it in tmux instead of treating it as an invisible background process.

```bash
ace-assign fork-run --assignment 8r6.t.u53@010 --launch-mode tmux-visible
```

#### Expected Output

- `ace-assign` announces visible fork execution for subtree `010`.
- tmux creates or reuses a sibling window named from the current window with a `-fork` suffix.
- The subtree appears in its own pane within that fork window.
- `ace-assign` still reports subtree completion or failure from assignment state rather than from pane visibility alone.

### Scenario 2: Inspect runtime tmux state for active forks

**Goal**: An operator or higher-level ACE tool queries tmux runtime state to find active fork windows and panes.

```bash
ace-tmux state --format json
```

#### Expected Output

- JSON output lists tmux sessions, windows, and panes with enough metadata to identify:
  - the current session
  - the `<current-window>-fork` window
  - active and completed panes
  - pane ids, current commands, and liveness hints

### Scenario 3: Visible mode requested outside tmux

**Goal**: A user requests visible mode without an active tmux session and still gets a usable fork execution path.

```bash
ace-assign fork-run --assignment 8r6.t.u53@010 --launch-mode tmux-visible
```

#### Expected Output

- `ace-assign` reports that visible tmux execution is unavailable in the current environment.
- The command falls back to the existing provider-backed launcher unless quiet mode suppresses the notice.
- Assignment behavior remains correct even though no visible fork window is created.

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`.
