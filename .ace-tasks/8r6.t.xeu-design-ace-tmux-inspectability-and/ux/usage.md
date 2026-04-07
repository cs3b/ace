# ACE tmux inspectability and recording - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Inspect runtime tmux state for ACE-managed sessions and panes

**Goal**: An operator or higher-level ACE tool queries tmux runtime state to find active ACE-managed sessions, windows, and panes.

```bash
ace-tmux state --format json
```

#### Expected Output

- JSON output lists ACE-managed tmux sessions, windows, and panes with enough metadata to identify:
  - the current session
  - ACE-managed windows and panes
  - pane and window identifiers
  - liveness hints and current commands where available
  - effective recording status and the `source_scope` that enabled recording
  - artifact directories or manifest paths for recorded panes

### Scenario 2: Configure recording through ACE-managed tmux presets

**Goal**: An operator or implementer configures recording in ACE-managed preset files and relies on session-to-window-to-pane inheritance with lower-scope overrides.

```yaml
# sessions/dev.yml
name: dev
recording:
  enabled: true
windows:
  - preset: work
    recording:
      enabled: false
  - preset: takeover
    panes:
      - commands: ["ace-task show 8r6.t.xeu --content"]
        recording:
          enabled: true
```

#### Expected Output

- Session-level recording enables recording by default for ACE-managed panes in that session.
- Window-level overrides can disable or refine recording for one window without changing sibling windows.
- Pane-level overrides can re-enable recording for one ACE-managed pane even if the containing window disabled it.
- `ace-tmux state --format json` reports the effective recording status plus the `source_scope` that set it for each pane.

### Scenario 3: Start an ACE-managed tmux session with recording enabled via CLI convenience flag

**Goal**: An operator starts an ACE-managed tmux session that records later manual takeover activity for inspection.

```bash
ace-tmux start --record
```

#### Expected Output

- `ace-tmux` starts the session with recording enabled for ACE-managed panes unless overridden at a lower scope.
- Recording remains scoped to ACE-managed panes rather than arbitrary existing tmux panes.
- Recorded artifacts are stored under `.ace-local/tmux/`.

### Scenario 4: Inspect recorded evidence after manual takeover work

**Goal**: An operator inspects what happened in a recorded pane after switching from agent-driven flow to manual work.

```bash
ace-tmux state --format json
```

#### Expected Output

- Runtime state identifies the recorded pane and its artifact directory.
- Runtime state reports the effective recording state and `source_scope` that enabled the recording.
- The operator can inspect raw evidence files under `.ace-local/tmux/`.
- The system does not claim semantic learning, redaction, or perfect action attribution from those logs.

## Notes for Implementer

- Visible fork launch behavior is owned by sibling task `8r6.t.u53`.
- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`.
