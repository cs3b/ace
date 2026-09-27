# Runtime-Switchable Terminal Surface - Draft Usage

## API Surface

- [ ] CLI (no new commands by default; consumers gain config, not flags)
- [x] Developer API (Ace::Runtime contract consumed by assign/overseer/demo)
- [ ] Agent API (drive.wf.md callback rule text changes)
- [x] Configuration (execution.launch_mode gains herdr; overseer runtime key)

## Usage Scenarios

### Scenario 1: fork run with callback on herdr

**Goal**: An agent launches a fork assignment from a herdr pane and the callback lands back in the caller's pane.

```bash
# .ace/assign/config.yml → execution.launch_mode: herdr   (or auto inside herdr)
ace-assign fork run 8wq.t.k86 --provider codex --callback

# Expected: fork agent starts in a herdr tab rooted at the fork worktree;
# completion callback is sent to the caller's pane (contract context);
# session metadata records launch_mode: herdr + runtime-neutral pane refs.
```

### Scenario 2: work-on opens a herdr tab

**Goal**: Overseer work-on provisions the worktree and opens the work window in the configured runtime.

```bash
# .ace/overseer/config.yml → runtime: herdr + window_presets: {"work-on-task": work-on-task}
ace-overseer work-on 8wq.t.k84

# Expected: herdr tab opens rooted at the task worktree (tmux path: unchanged when runtime: tmux).
```

### Scenario 3: Error path — herdr configured but unavailable

**Goal**: Explicit failure (or documented fallback), never a silent no-op.

```bash
# execution.launch_mode: herdr, herdr binary missing
ace-assign fork run 8wq.t.k86

# Expected output:
# Error: runtime 'herdr' unavailable (herdr CLI not found) — exit non-zero
# With launch_mode: auto → falls back to headless with a notice (existing behavior).
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
- Regression gate: `runtime: tmux` must be behavior-identical to today
