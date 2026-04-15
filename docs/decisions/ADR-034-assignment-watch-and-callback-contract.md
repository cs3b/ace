# ADR-034: Assignment Watch and Callback Contract

## Status

Accepted
Date: 2026-04-15

## Context

`/as-assign-drive` already documented a run-until-complete-or-blocked contract, but fork waiting and child-to-child continuation still depended too heavily on prompt instructions and conversational discipline. In real assignment batches, the driver could finish one child subtree, report progress, and then stop until the user said `continue`, even though the parent queue still had deterministic next work.

Existing building blocks already existed:

- `ace-assign status` provides canonical assignment and subtree state
- `ace-assign fork-run` executes one fork-enabled subtree
- fork session metadata and PID traces are persisted under `.ace-local/assign/<assignment-id>/sessions/`

What was missing was a deterministic runtime loop that owned "wait for fork / recover after interruption / launch next child" outside the LLM workflow prompt.

## Decision

We introduce `ace-assign watch` as the deterministic runtime for fork continuation, and we reserve callback delivery as a separate contract layered on top of watcher state.

Key aspects of this decision:

- `ace-assign watch --assignment <id>` is the canonical CLI for waiting on in-flight fork work, recovering from interruption via assignment state, and immediately continuing to the next pending fork subtree.
- `/as-assign-drive` remains the public orchestration workflow, but it delegates fork wait/resume behavior to `ace-assign watch` instead of hand-rolled polling guidance.
- `ace-assign status` remains the source of truth. PID/session data may help the watcher decide whether a child is still alive, but status determines completion.
- `watch` intentionally stops when only inline/manual work remains. It is not a general-purpose executor for arbitrary assignment steps.
- Callback delivery is defined as a notification layer only; parent agents must still re-check status before acting.

## Callback Contract

Future callback support will target deterministic parent wake-up without replacing status polling as the authority.

Reserved interface:

- `ace-assign watch --callback tmux:<target>`
- `<target>` accepts standard tmux targets, including explicit pane ids such as `%42`

Reserved events:

- `subtree_completed`
- `subtree_failed`
- `assignment_blocked`
- `assignment_completed`

Reserved payload shape:

- prefix: `ACE_ASSIGN_EVENT `
- JSON object keys:
  - `assignment_id`
  - `scope`
  - `event`
  - `current_step`
  - `next_step`
  - `session_id`
  - `report_path_or_dir`
  - `resume_command`
  - `timestamp`

Callback rules:

- delivery is best-effort and must not mutate assignment truth
- callback failure must not fail or corrupt the assignment
- consumers must re-run `ace-assign status` before deciding what to do next

## Consequences

### Positive

- Sequential fork batches now have a product-level continuation path instead of relying on agent memory.
- Interrupted drive sessions can recover by re-entering from assignment state.
- The LLM workflow becomes thinner and easier to verify.

### Negative

- Another CLI surface must be documented and tested.
- Watch/recovery semantics now depend on persisted fork metadata being kept accurate enough for telemetry.

### Neutral

- `fork-run` remains the single-subtree execution primitive.
- Inline/manual assignment work still belongs to `/as-assign-drive`, not to the deterministic watcher.

## Related Decisions

- [ADR-028: Assignment Fork Execution and Recovery](ADR-028-assignment-fork-execution-and-recovery.md)
- [ADR-031: CLI Argument and Execution Contract](ADR-031-cli-argument-and-execution-contract.md)

## References

- `ace-assign/lib/ace/assign/cli/commands/watch.rb`
- `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`
- `ace-assign/handbook/skills/as-assign-drive/SKILL.md`
