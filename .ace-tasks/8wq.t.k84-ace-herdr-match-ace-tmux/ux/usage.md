# ace-herdr Intent Parity - Draft Usage

## API Surface

- [x] CLI (user-facing commands: list, send, capture, wait --for output, workspace/tab presets, --list-presets)
- [ ] Developer API (public Ruby normalization is Task 8wq.t.k86's contract)
- [ ] Agent API (no new workflows/skills)
- [x] Configuration (`.ace-defaults/herdr/{workspaces,tabs}/*.yml` preset cascade)

## Usage Scenarios

### Scenario 1: List panes in the caller's workspace

**Goal**: An agent inspects live herdr state with the vocabulary it knows from ace-tmux.

```bash
ace-herdr list --panes

# Expected output:
# {"panes":[{"id":"w1:p1","tab":"w1:t1","workspace":"w1","title":"bash"},{"id":"w1:p2","tab":"w1:t1","workspace":"w1","title":"pi"}]}
```

### Scenario 2: Agent-aware send — same flags, correct transport

**Goal**: One `send` vocabulary works for plain panes and agent panes; herdr's blocked/stalled semantics protect agent panes; mixed msg+key sequences submit exactly once.

```bash
ace-herdr send --cmd 'bundle exec rake test' --pane w1:p1
# {"pane":"w1:p1","sent":"cmd"}

ace-herdr send --cmd 'continue with the plan' --pane w1:p2   # pane hosts a live agent
# {"pane":"w1:p2","sent":"prompt"}
# If the agent is blocked: CLI error carrying agent_blocked, non-zero exit.

ace-herdr send --pane w1:p1 --msg 'done: 8wq.t.k86' --key Enter   # callback form, plain pane
# {"pane":"w1:p1","sent":"msg+key"}

ace-herdr send --pane w1:p2 --msg 'done: 8wq.t.k86' --key Enter   # callback form, agent pane
# {"pane":"w1:p2","sent":"prompt","dropped_keys":["Enter"]}
```

### Scenario 3: Capture then wait for output

**Goal**: Replace ace-tmux capture/wait-output over a herdr pane.

```bash
ace-herdr capture --pane w1:p1 --lines 40 --source recent
# raw pane text

ace-herdr wait --pane w1:p1 --for output --pattern 'tests? OK' --timeout 120
# {"pane":"w1:p1","state":"ready"}
# Timeout: CLI error, non-zero exit.
```

### Scenario 4: Error path — unknown preset

**Goal**: Preset creation fails closed with guidance.

```bash
ace-herdr tab review-tab

# Expected output:
# Error: unknown preset 'review-tab' (available tabs: cc, work-on-task) — exit non-zero
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
- Parity oracle: ace-tmux command/flag inventory in `ace-tmux/lib/ace/tmux/cli.rb`
