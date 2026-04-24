---
id: 8rn.t.z5k.1
status: pending
priority: medium
created_at: "2026-04-24 23:26:18"
estimate: TBD
dependencies: []
tags: [ace-assign, workflow, watch]
parent: 8rn.t.z5k
bundle:
  presets: [project]
  files: [.ace-tasks/8rn.t.z5k-design-deterministic-watch-continuation-for/8rn.t.z5k-design-deterministic-watch-continuation-for-forked-ace.s.md, ace-assign/lib/ace/assign/cli.rb, ace-assign/lib/ace/assign/cli/commands/fork_run.rb, ace-assign/lib/ace/assign/models/step.rb, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, ace-assign/docs/usage.md, ace-assign/test/fast/organisms/assign_drive_contract_test.rb, ux/usage.md]
  commands: [ace-task show 8rn.t.z5k.1 --content, ace-assign status, ace-assign fork-run --help]
needs_review: false
---

# Define ace-assign watch command and stop-state contract

## Objective

Define the public `ace-assign watch` command as the deterministic continuation primitive for fork-heavy assignments on current `main`.

## Behavioral Specification

### User Experience

- Users can run one command to keep forked assignment work moving instead of repeatedly nudging the parent after each child subtree completes.
- Users can target either the full assignment or one explicit subtree and get deterministic stop behavior.
- Users can re-enter the same assignment later and let the watcher recover from persisted state rather than from old terminal handles.
- Users get a clear stop message when only inline/manual work remains and should return to `/as-assign-drive` or direct step execution.

### Expected Behavior

1. `ace-assign watch` can watch an active assignment or a specific fork subtree.
2. The command loops until one of these conditions is true:
   - watched scope is complete
   - watched scope has failed
   - no fork work remains and only inline/manual work is left
3. When a fork root is currently active and telemetry indicates the child is still alive, the watcher waits instead of immediately re-forking.
4. When a fork root is active but the original session/process is gone, the watcher recovers by re-entering from assignment state and relaunching the needed subtree continuation path.
5. When no fork root is active but a pending fork root is next, the watcher launches it immediately.
6. Unscoped watcher invocations may continue through multiple fork roots in sequence.
7. Scoped watcher invocations must never widen back to the parent assignment.
8. `Errno::EPERM` on PID liveness checks must be treated as “process exists but cannot be signaled,” not as proof of death.

### Interface Contract

```bash
ace-assign watch --assignment 8abcd1
ace-assign watch --assignment 8abcd1@010
ace-assign watch --assignment 8abcd1 --root 010
ace-assign watch --assignment 8abcd1 --root 010 --poll-interval 300
```

Expected outputs:
- startup summary naming the watched assignment or subtree
- waiting summary while active fork work still appears alive
- recovery summary when relaunching from assignment state
- launch summary when starting the next pending fork subtree
- terminal completion summary for assignment or subtree
- stop summary when only inline/manual work remains

Error handling:
- conflicting `--root` versus scoped `@<root>` fails clearly
- non-fork root targets fail clearly
- watched failed steps fail clearly
- invalid `--poll-interval` values fail clearly

Edge cases:
- scoped subtree already terminal at invocation time returns success without relaunching
- old child metadata exists but status already shows terminal subtree; status wins
- active PID is inaccessible with `EPERM`; watcher still treats it as alive

### Success Criteria

- [ ] The task defines the full public command surface for `ace-assign watch`.
- [ ] The task defines exact watcher stop conditions and recovery behavior without leaving hidden scheduler decisions to implementation.
- [ ] The task preserves status-as-truth and telemetry-as-advisory semantics.
- [ ] The task explicitly covers scoped versus unscoped behavior.
- [ ] The task explicitly calls out `Errno::EPERM` as a live-process case for PID checks.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: decision-complete command contract for deterministic watcher behavior
- **Advisory size**: medium
- **Context dependencies**: current `fork-run`, current assignment state model, current drive workflow continuation text

## Verification Plan

### Unit / Component Validation

- Confirm the CLI contract covers startup, waiting, recovery, launch, stop, and completion cases.
- Confirm scoped watcher behavior never widens to parent state.
- Confirm PID and session telemetry are advisory only.

### Integration / E2E Validation

- Walk through a parent assignment with two sequential fork roots and one inline tail.
- Walk through a scoped subtree that is already complete when `watch` starts.
- Walk through interruption recovery where old child state disappeared but assignment state still needs continuation.

### Failure / Invalid Path Validation

- Confirm invalid root, conflicting scope, failed subtree, and invalid poll interval all fail clearly.
- Confirm `EPERM` is treated as live process existence rather than dead process inference.

### Verification Commands

- `ace-task show 8rn.t.z5k.1 --content`
- `ace-assign status`
- `ace-assign fork-run --help`

## Scope of Work

- define the `ace-assign watch` public CLI
- define its stop-state contract
- define telemetry and recovery semantics
- define scoped versus unscoped continuation behavior

## Deliverables

### Behavioral Specifications

- watcher command surface
- stop-state contract
- status-versus-telemetry ownership rules

### Validation Artifacts

- watcher acceptance scenarios in `ux/usage.md`

## Out of Scope

- implementation details such as exact class names or private helper layout
- broader parallel refill orchestration beyond sequential continuation
- replacing `/as-assign-drive` for inline/manual steps

## References

- parent task `8rn.t.z5k`
- `ace-assign/lib/ace/assign/cli/commands/fork_run.rb`
- `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`
