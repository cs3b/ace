---
id: 8ro.t.0ve.2
status: draft
priority: medium
created_at: "2026-04-25 00:34:53"
estimate: TBD
dependencies: [8ro.t.0ve.0]
tags: [ace-assign, watch, recovery]
parent: 8ro.t.0ve
bundle:
  presets: [project]
  files:
    - .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/0-define-watch-recovery-and-callback/8rn.t.z5k.0-define-watch-recovery-and-callback-artifact-contract.s.md
    - .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/1-define-ace-assign-watch-command/8rn.t.z5k.1-define-ace-assign-watch-command-and-stop.s.md
    - .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/ux/usage.md
    - ace-assign/lib/ace/assign/cli/commands/fork_run.rb
    - ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb
    - ace-assign/test/fast/commands/fork_run_command_test.rb
    - ace-assign/test/fast/organisms/assign_drive_contract_test.rb
    - ux/usage.md
  commands:
    - ace-task show 8ro.t.0ve.2 --content
    - ace-assign status
    - ace-assign fork-run --help
---

# Implement unscoped continuation wait and recovery semantics

## Objective

Implement the watcher behavior that waits on active fork work, recovers from lost parent/session state, and continues through multiple fork roots in sequence when the watcher is invoked on the full assignment.

## Behavioral Specification

### User Experience

- Users can watch a whole assignment and let the tool continue through multiple pending fork roots in order.
- Users do not need the original tmux pane or process handle to resume progress after interruption.
- Users see whether the watcher is waiting on live work, recovering from lost session state, launching new fork work, or stopping because only inline/manual work remains.

### Expected Behavior

1. When an active fork root exists and advisory telemetry still supports liveness, the watcher waits instead of re-forking immediately.
2. When an active fork root is non-terminal but session/process telemetry no longer supports liveness, the watcher recovers by re-entering from assignment state and relaunching the correct continuation path.
3. When no fork root is active but a pending fork root is next, the watcher launches it immediately.
4. Unscoped watcher invocations continue through multiple fork roots in sequence until the assignment is terminal or only inline/manual work remains.
5. Scoped watcher invocations never use this logic to widen back to later parent siblings.
6. `Errno::EPERM` from PID liveness probing is treated as "alive but not signalable."
7. Callback-pane text remains a non-authoritative hint and never overrides assignment state.

### Interface Contract

- Wait summary appears when active fork work still looks alive.
- Recovery summary appears when historical session metadata is stale but assignment state remains non-terminal.
- Launch summary appears when the next pending fork root is started automatically.
- Completion summary appears when the watched assignment becomes terminal.
- Stop summary appears when only inline/manual work remains and the watcher should hand control back to direct execution.

Telemetry rules:

- persisted PID/session metadata may classify wait versus recover
- `ace-assign status` decides completion, failure, and next runnable work
- missing callback text is never proof of failure by itself
- same-root re-entry must not duplicate relaunch when state already shows scoped work is active or complete

### Success Criteria

- [ ] Whole-assignment watch can continue across multiple fork roots in sequence.
- [ ] Active-live telemetry causes wait instead of duplicate relaunch.
- [ ] Lost-session state triggers recovery from assignment state rather than terminal-handle dependence.
- [ ] `Errno::EPERM` is treated as alive.
- [ ] Scoped targets still respect the scoped boundary while using wait/recovery logic.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: shipped wait/recovery and sequential continuation semantics
- **Advisory size**: medium
- **Context dependencies**: scoped watcher command shell, current fork telemetry persistence, current drive/fork-run status-first rules

## Verification Plan

### Unit / Component Validation

- Add direct tests for live-child wait behavior.
- Add direct tests for lost-session recovery from assignment state.
- Add direct tests for `Errno::EPERM` classification as alive.

### Integration / E2E Validation

- Confirm unscoped watch continues across two or more fork roots in sequence.
- Confirm interruption recovery resumes from assignment state after the original parent/session disappears.

### Failure / Invalid Path Validation

- Confirm no duplicate relaunch occurs when the current subtree is already active or terminal.
- Confirm scoped invocations never continue into later sibling roots.

### Verification Commands

- `ace-test ace-assign test/fast/commands/watch_command_test.rb`
- `ace-test ace-assign test/fast/commands/fork_run_command_test.rb`

## Scope of Work

- implement wait-versus-recover classification from existing fork telemetry
- implement unscoped multi-root continuation
- preserve status-first completion/failure rules
- preserve callback compatibility as hint-only behavior

## Deliverables

### Behavioral Specifications

- live-child wait semantics
- interruption recovery semantics
- multi-root continuation behavior

### Validation Artifacts

- direct fast tests for wait, recovery, and `EPERM`
- matching acceptance scenarios in `ux/usage.md`

## Out of Scope

- CLI registration and basic scoped target parsing
- retained E2E wiring and package docs updates
- new event payload emission or callback APIs

## References

- archived tasks `8rn.t.z5k.0` and `8rn.t.z5k.1`
- `ace-assign/lib/ace/assign/cli/commands/fork_run.rb`
- `ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb`
