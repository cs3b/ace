# Deterministic watch continuation for forked ace-assign work - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflow-facing continuation semantics)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Continue sequential fork work without manual nudges

**Goal**: Keep a fork-heavy assignment moving through multiple child subtrees until only inline/manual work remains.

```bash
ace-assign watch --assignment 8abcd1
```

#### Expected Output

- `ace-assign watch` announces that it is watching assignment `8abcd1`.
- If fork subtree `010` is pending, the watcher launches it immediately.
- After `010` completes, the watcher does not stop for a user nudge if `020` is the next pending fork subtree.
- The watcher launches `020`, waits or recovers as needed, and continues until no fork work remains.
- When the assignment reaches an inline/manual tail step such as `030`, the watcher exits with a stop message that makes the remaining inline/manual boundary explicit.
- Assignment state remains the source of truth for completion and next-step decisions.

### Scenario 2: Recover after the original parent session disappears

**Goal**: Resume deterministic continuation from persisted assignment state rather than from the original terminal or provider session.

```bash
ace-assign watch --assignment 8abcd1@010
```

#### Expected Output

- The watcher inspects scoped assignment state for subtree `010`.
- If metadata suggests the historical child session disappeared but status shows non-terminal work, the watcher reports recovery from assignment state and re-enters the subtree continuation path.
- If status already shows subtree `010` terminal, the watcher exits successfully without relaunching work.
- The watcher never widens a scoped target such as `8abcd1@010` back to the parent assignment.
- Callback text or missing callback text may inform operator understanding, but neither overrides scoped status.

### Scenario 3: Preserve future event shapes as artifact examples only

**Goal**: Keep useful structured event payload ideas in the task artifacts without making them required runtime behavior for v1.

```text
ACE_ASSIGN_EVENT {"assignment_id":"8abcd1","scope":"010","event":"subtree_completed","current_step":"010.02","next_step":"020","session_id":"sess_123","report_path_or_dir":".ace-local/assign/8abcd1/reports/","resume_command":"ace-assign watch --assignment 8abcd1","timestamp":"2026-04-25T00:00:00Z"}
ACE_ASSIGN_EVENT {"assignment_id":"8abcd1","scope":"010","event":"subtree_failed","current_step":"010.02","next_step":null,"session_id":"sess_123","report_path_or_dir":".ace-local/assign/8abcd1/reports/010.02-report.md","resume_command":"ace-assign watch --assignment 8abcd1@010","timestamp":"2026-04-25T00:00:00Z"}
```

#### Expected Output

- These payloads appear only in task artifacts and usage guidance.
- They are labeled as future examples, not as required output from `ace-assign watch`.
- Current shipped callback mode remains the live parent/child wake-up path:
  ```bash
  ace-tmux send --pane "$ACE_ASSIGN_CALLBACK_PANE" --msg "Fork subtree ${FORK_ROOT} for assignment ${ASSIGNMENT_ID} completed. Resume parent assignment drive now." --key Enter
  ```
- Any future implementation that wants emitted events should be handled by a separate follow-up task instead of being silently folded into this v1 watcher family.

### Scenario 4: Extend TS-ASSIGN-003 with watcher verification

**Goal**: Validate watcher behavior in the retained `ace-assign` operations suite instead of inventing an unrelated test surface.

```text
TC-003-watch-sequential-continuation
TC-004-watch-recovers-after-interruption
```

#### Expected Output

- `TC-003` records raw artifacts proving the watcher advanced across multiple fork roots and stopped only when inline/manual work remained.
- `TC-004` records raw artifacts proving the watcher resumed from assignment state after the original parent/session disappeared.
- Expected raw evidence includes:
  ```text
  results/tc/03/watch.stdout
  results/tc/03/watch.stderr
  results/tc/03/watch.exit
  results/tc/03/status-before.stdout
  results/tc/03/status-after.stdout
  results/tc/04/watch-recover.stdout
  results/tc/04/watch-recover.stderr
  results/tc/04/watch-recover.exit
  results/tc/04/status-after.stdout
  ```
- Verifier logic judges PASS from those artifacts, not from fabricated summaries.

## Notes for Implementer

- Keep `ace-assign status` authoritative for subtree completion, failure, and next runnable work.
- Treat PID/session telemetry as advisory only.
- Preserve current `fork-run --callback` semantics; do not replace them with an unimplemented event API.
- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
