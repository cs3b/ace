# Deterministic watch continuation for forked ace-assign work

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Continue a full assignment across multiple fork roots

**Goal**: Keep a fork-heavy assignment moving until only inline/manual work remains.

```bash
ace-assign watch --assignment 8abcd1
```

### Expected Output

- The watcher announces that it is watching assignment `8abcd1`.
- If root `010` is pending, it launches `010` immediately.
- After `010` completes, it continues into the next pending fork root such as `020` without requiring a new user nudge.
- When no fork work remains and the next work is inline/manual, it exits successfully with a stop summary that names the remaining boundary.

### Scenario 2: Recover a scoped subtree after the original session disappears

**Goal**: Resume one subtree from assignment state without widening back to the parent assignment.

```bash
ace-assign watch --assignment 8abcd1@010
```

### Expected Output

- The watcher reports that it is watching subtree `010` only.
- If old PID/session metadata is stale but `ace-assign status` still shows non-terminal subtree work, the watcher reports recovery from assignment state and resumes the subtree path.
- If subtree `010` is already terminal, the watcher exits successfully without relaunching work.
- The watcher never continues into later parent siblings such as `020`.

### Scenario 3: Wait on active fork work that still looks alive

**Goal**: Avoid duplicate relaunch while an active fork child is still running.

```bash
ace-assign watch --assignment 8abcd1 --poll-interval 60
```

### Expected Output

- The watcher prints the watched assignment and effective poll interval.
- If the current fork root is active and persisted PID/session telemetry still indicates a live child, it prints a waiting summary instead of relaunching `fork-run`.
- If PID probing raises `Errno::EPERM`, the watcher still treats the child as alive and remains in the waiting path.
- Completion and failure are still determined by `ace-assign status`, not by callback absence or PTY silence.

### Scenario 4: Reject invalid watcher inputs

**Goal**: Fail before any continuation loop starts when targeting inputs are invalid.

```bash
ace-assign watch --assignment 8abcd1@010 --root 020
ace-assign watch --assignment 8abcd1 --poll-interval 0
ace-assign watch --assignment 8abcd1 --root 030
```

### Expected Output

- Conflicting `@010` plus `--root 020` exits non-zero with a clear targeting error.
- A zero or negative poll interval exits non-zero with a clear validation error.
- A non-fork root target exits non-zero instead of entering a partial watch loop.

### Scenario 5: Extend retained E2E coverage

**Goal**: Validate watcher behavior in the retained `TS-ASSIGN-003` suite instead of inventing a watcher-only test surface.

```text
TC-003-watch-sequential-continuation
TC-004-watch-recovers-after-interruption
```

### Expected Output

- `scenario.yml` expands the retained suite with watcher evidence areas while preserving `TC-001` and `TC-002`.
- `TC-003` records raw artifacts proving the watcher advanced across multiple fork roots and stopped at an inline/manual tail.
- `TC-004` records raw artifacts proving the watcher resumed from assignment state after the original parent/session disappeared.
- The verifier uses raw captures under `results/tc/03/` and `results/tc/04/` as primary evidence.
- The retained runner/verifier bundle order expands from 2 goals to 4 goals without creating a watcher-only suite.

## Notes for Implementer

- Preserve current `fork-run --callback` semantics; do not replace them with a new `watch --callback` API.
- Full package usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
