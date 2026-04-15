# Assignment watch continuation and callback handoff - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Continue a fork-heavy assignment without manual nudges

**Goal**: An operator starts one watcher invocation and lets it wait, recover, and continue across successive forked child subtrees.

```bash
ace-assign watch --assignment 8rddnp
```

#### Expected Output

- The watcher announces which assignment or subtree it is watching.
- If a forked child is already running, the watcher waits and polls until that child reaches a terminal state or needs recovery.
- When a child subtree completes, the watcher immediately launches the next eligible fork subtree.
- The watcher stops only when the assignment is complete, failed, blocked, or only inline/manual work remains.

### Scenario 2: Recover deterministic continuation after interruption

**Goal**: A later invocation re-enters from assignment state after the original session disappeared.

```bash
ace-assign watch --assignment 8rddnp --root 010.03
```

#### Expected Output

- The watcher resolves the specified fork-enabled subtree root.
- If assignment state still shows active fork work but the old fork session is no longer alive, the watcher reports recovery and re-enters the subtree from assignment state.
- Continuation resumes without requiring the user to reconstruct the old terminal session manually.

### Scenario 3: Reserve a tmux wake-up callback

**Goal**: A parent operator or agent receives a lightweight callback when a watcher event occurs.

```bash
ace-assign watch --assignment 8rddnp --callback tmux:%42
```

#### Expected Output

- The watcher reserves a notification-only callback target for meaningful events.
- Emitted messages use the prefix `ACE_ASSIGN_EVENT ` followed by JSON payload data.
- The receiving side treats the callback as a wake-up signal and re-runs `ace-assign status` before acting.
- Callback delivery failure does not corrupt or fail the assignment.

## Notes for Implementer

- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
- Callback delivery remains a future implementation layer; status must stay authoritative.
