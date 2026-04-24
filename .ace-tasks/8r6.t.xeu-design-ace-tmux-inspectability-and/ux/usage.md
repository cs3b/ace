# ACE tmux read-side follow-up - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

This usage draft covers the read-side follow-up only. The current public baseline is `ace-tmux list`. Interactive control commands such as `send`, `wait`, live pane-tail `capture`, `attach`, and `detach` already belong to sibling task `8re.t.n1d`.

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

### Scenario 2: Evaluate a future machine-readable runtime surface

**Goal**: A later follow-up may expose machine-readable runtime inspection, but it must be additive to the shipped `list` baseline rather than a contradiction of it.

```bash
# Candidate follow-up surface only; not shipped today.
ace-tmux list --format json
```

#### Expected Output

- This scenario is blocked pending review.
- If implemented, it should report the same runtime entities already exposed by the shipped `list` scopes.
- It must not imply recording provenance or artifacts unless those concepts are explicitly accepted into scope.

### Scenario 3: Recording/provenance remains unresolved

**Goal**: Keep unimplemented recording ideas explicit instead of silently treating them as accepted contract.

```bash
# No shipped command today.
# Future ownership is unresolved:
#   ace-tmux state
#   ace-tmux start --record
```

#### Expected Output

- The task review should decide whether recording/provenance remains here, moves elsewhere, or is deferred entirely.
- Until that decision is made, no usage documentation should present recording flags, `source_scope`, or `.ace-local/tmux` artifacts as live behavior.

## Notes for Implementer

- Shipped visible fork launch behavior is owned by sibling task `8r6.t.u53`.
- Interactive control behavior is owned by sibling task `8re.t.n1d`.
- Full usage documentation should be completed only after the review questions on command shape and recording ownership are resolved.
