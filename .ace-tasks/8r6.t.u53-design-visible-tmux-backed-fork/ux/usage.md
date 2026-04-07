# Visible tmux-backed fork execution - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

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
- If the pane exits early before assignment state is terminal, the operator-facing diagnostics include recent pane tail output.

### Scenario 2: Visible mode requested outside tmux

**Goal**: A user requests visible mode without an active tmux session and still gets a usable fork execution path.

```bash
ace-assign fork-run --assignment 8r6.t.u53@010 --launch-mode tmux-visible
```

#### Expected Output

- `ace-assign` reports that visible tmux execution is unavailable in the current environment.
- The command falls back to the existing provider-backed launcher unless quiet mode suppresses the notice.
- Assignment behavior remains correct even though no visible fork window is created.

### Scenario 3: Visible pane exits before assignment state is terminal

**Goal**: An operator gets actionable diagnostics when the visible pane surface ends before the subtree is logically complete.

```bash
ace-assign fork-run --assignment 8r6.t.u53@010 --launch-mode tmux-visible
```

#### Expected Output

- `ace-assign` reports that the visible pane surface ended before subtree completion was observed.
- The error includes recent pane-tail output for operator diagnosis.
- If a sibling tmux inspectability surface already exposes additional references, `ace-assign` may include them without redefining their schema here.

## Notes for Implementer

- Generic `ace-tmux state`, recording, and artifact usage are owned by sibling task `8r6.t.xeu`.
- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`.
