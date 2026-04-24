# ACE tmux read-side follow-up - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

This usage draft covers the read-side follow-up only. The current public baseline is `ace-tmux list`, and the validated spike outcome is that no additional read-side CLI surface is justified in the current repo state. Interactive control commands such as `send`, `wait`, live pane-tail `capture`, `attach`, and `detach` already belong to sibling task `8re.t.n1d`.

### Scenario 1: Inspect current tmux runtime state through the shipped CLI

**Goal**: An operator or higher-level ACE tool inspects live tmux sessions, windows, and panes through the shipped read-side CLI.

```bash
ace-tmux list
ace-tmux list --windows
ace-tmux list --sessions
```

#### Expected Output

- The current output lists live sessions, windows, or panes in table form.
- Pane rows identify active state, pane id, resolved target, current command, and working-directory basename.
- Window rows identify active state, tmux window id, session/index, name, and pane count.
- Session rows identify session name, attached-client count, and window count.

### Scenario 2: Future machine-readable runtime output requires a new task, not this archived family

**Goal**: Keep speculative CLI JSON work out of the accepted contract unless a concrete consumer later requires it.

#### Expected Output

- This is not an accepted follow-up contract today.
- Current structured consumers already use Ruby APIs or local metadata rather than a shared CLI JSON schema.
- If a later consumer justifies this, it must be drafted as a new task, stay additive to the shipped `list` scopes, and must not imply recording provenance or artifacts.

### Scenario 3: Recording/provenance is out of scope for this task

**Goal**: Keep deferred recording ideas explicit instead of silently treating them as accepted contract.

```bash
# No shipped command today.
# Deferred to a separate future task if ever needed:
#   ace-tmux start --record
#   ace-tmux list --recording
```

#### Expected Output

- This task must not present recording flags, `source_scope`, or `.ace-local/tmux` artifacts as live behavior.
- If a future consumer requires generic tmux recording/provenance, that work should be drafted separately.

## Notes for Implementer

- Shipped visible fork launch behavior is owned by sibling task `8r6.t.u53`.
- Interactive control behavior is owned by sibling task `8re.t.n1d`.
- Current repo evidence supports no new read-side CLI implementation task from this task family.
- Archive this task family after closure. If a concrete consumer later needs more than the shipped `ace-tmux list` surface or the existing Ruby read-side APIs, draft a new task.
