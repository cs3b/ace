# ACE tmux inspectability and recording follow-up - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Use shipped `ace-tmux list` as the current baseline

**Goal**: Inspect live ACE-managed tmux runtime state through the currently shipped read-side surface.

```bash
ace-tmux list
ace-tmux list --windows
ace-tmux list --sessions
```

#### Expected Output

- Current `ace-tmux` already exposes human runtime inspection through `list`.
- This task family treats that surface as the baseline for all follow-up design work.

### Scenario 2: Any richer runtime contract must be additive to `list`

**Goal**: Preserve the original inspectability intent without assuming the stale `ace-tmux state` contract is still correct.

```bash
# Not shipped today.
# If review keeps this direction alive, the follow-up should extend the existing baseline:
# ace-tmux list --format json
```

#### Expected Output

- The runtime-inspection child task owns any additive machine-readable or richer runtime surface.
- No additive runtime output is assumed validated until review confirms the child task is still needed.

### Scenario 3: Recording and evidence remain explicit work, not silent drift

**Goal**: Keep the original tmux-native recording/evidence intent alive as a real child task instead of hiding it in parent prose.

```bash
# Not shipped today.
# If review keeps this direction alive, the follow-up may look like:
# ace-tmux start --record
# ace-tmux window --record
```

#### Expected Output

- The recording child task owns ACE-managed tmux recording, persisted evidence under `.ace-local/tmux/`, and provenance such as `source_scope` if they remain justified.
- The boundary child task keeps live control-side pane-tail behavior out of this family.

## Notes for Implementer

- `ace-tmux list` is the current baseline, not proof that the full original intent was satisfied.
- The family preserves three separate concerns from the start: additive runtime inspection, ownership boundaries, and recording/evidence.
- `as-task-review` is expected to do the deep analysis and reshape these drafts if current codebase reality proves one child obsolete or misplaced.
