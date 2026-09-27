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
# {"panes":[{"id":"w1:p1","tab":"w1:t1","workspace":"w1","title":"~","cwd":"/tmp","focused":true,"agent_status":"idle"}]}
# Empty workspace: success with an empty array, never an error.

ace-herdr list --tabs --workspace w1
# {"tabs":[{"id":"w1:t1","workspace":"w1","title":"work","number":1,"pane_count":2,"focused":true}]}

ace-herdr list --workspaces
# {"workspaces":[{"id":"w1","title":"dev","number":1,"tab_count":2,"pane_count":3,"focused":false}]}
```

### Scenario 2: Agent-aware send  --  same flags, correct transport

**Goal**: One `send` vocabulary works for plain panes and agent panes; herdr's blocked/stalled semantics protect agent panes; mixed msg+key sequences submit exactly once.

```bash
ace-herdr send --cmd 'bundle exec rake test' --pane w1:p1
# {"pane":"w1:p1","sent":"cmd"}

ace-herdr send --cmd 'continue with the plan' --pane w1:p2   # pane hosts a live agent
# {"pane":"w1:p2","sent":"prompt"}
# If the agent is blocked: CLI error carrying agent_blocked, non-zero exit.

ace-herdr send --pane w1:p1 --msg 'done: 8wq.t.k86' --key Enter   # callback form, plain pane
# {"pane":"w1:p1","sent":"text"}

ace-herdr send --pane w1:p2 --msg 'done: 8wq.t.k86' --key Enter   # callback form, agent pane
# {"pane":"w1:p2","sent":"prompt","dropped_keys":["Enter"]}

ace-herdr send --pane w1:p1 --key Esc --cmd 'run'
# Error: --key must be declared after --cmd ...  --  usage error before any transport call
```

### Scenario 3: Capture then wait for output

**Goal**: Replace ace-tmux capture/wait-output over a herdr pane.

```bash
ace-herdr capture --pane w1:p1 --lines 40 --source recent
# raw pane text (no JSON wrapping)

ace-herdr wait --pane w1:p1 --for output --pattern 'tests? OK' --timeout 120
# {"pane":"w1:p1","matched":true}
# Timeout: CLI error carrying timeout, non-zero exit.
# Existing content is checked immediately, then polled (native pane wait-output).
```

### Scenario 4: Preset creation with cascade override

**Goal**: One command creates a declared workspace; project presets override gem defaults.

```bash
ace-herdr --list-presets
# {"workspaces":["development"],"tabs":["agent"]}   (gem defaults + merged project presets)

ace-herdr workspace development --cwd /Users/me/project
# {"workspace":"w2","tabs":[{"tab":"w2:t1","panes":["w2:p1","w2:p2"],"commands":0,"agents":["development-agent"]}]}
# Creation order: workspace → tab → root pane rename → split → rename → commands → readiness-gated agents.

ace-herdr tab agent --workspace w2
# {"tab":"w2:t2","panes":["w2:p3"],"commands":0,"agents":["task-agent"]}
```

### Scenario 5: Error path  --  unknown preset

**Goal**: Preset creation fails closed with guidance.

```bash
ace-herdr tab review-tab

# Expected output:
# Error: Unknown tab preset 'review-tab' (available: agent)  --  exit non-zero
```

## Notes for Implementer

- Full usage documentation: `ace-herdr/docs/usage.md` (parity table, send semantics, preset schema, error semantics).
- Parity oracle: ace-tmux command/flag inventory in `ace-tmux/lib/ace/tmux/cli.rb`.
- As-built divergences from the draft: `sent` value for the plain callback form is `text` (not `msg+key`); output wait reports `{"matched":true}` (agent form keeps `"state":"ready"`); split directions use herdr-native `right|down` (tmux-ish `horizontal|vertical` accepted as aliases).
