---
id: 8re.t.mh0.0
status: draft
priority: medium
created_at: "2026-04-15 14:59:00"
estimate: TBD
dependencies: []
tags: []
parent: 8re.t.mh0
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/cli/commands/watch.rb, ace-assign/lib/ace/assign/cli.rb, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, ace-assign/test/fast/commands/watch_command_test.rb, ace-assign/test/fast/organisms/assign_drive_contract_test.rb]
  commands: [ace-task show 8re.t.mh0 --content, ace-task show 8re.t.mh0.0 --content, ace-assign watch --help]
needs_review: false
---

# Spike deterministic ace-assign watch continuation contract

## Objective

Validate the end-state contract for deterministic fork continuation so one watcher invocation can wait for active forked work, recover from interruption, and launch the next eligible fork subtree until a real stop boundary is reached.

## Behavioral Specification

### User Experience

- An operator or agent can invoke `ace-assign watch` once and trust it to keep moving through fork-enabled child subtrees.
- If the original fork session disappears but assignment state still shows in-flight work, the watcher recovers instead of requiring manual restart choreography.
- The watcher reports clearly when it stops because only inline/manual work remains instead of silently idling.
- The spike produces a stable concept inventory for continuation semantics before any larger decomposition is attempted.

### Expected Behavior

1. The spike validates one coherent continuation path from watcher start through active-fork waiting, interruption recovery, and immediate next-child launch.
2. The spike explicitly keeps `ace-assign status` as the authority for completion and failure.
3. The spike defines how PID/session metadata is used only to decide whether to wait or recover, not to declare completion.
4. The spike defines the watcher stop boundary when the next remaining step requires inline/manual execution.
5. The spike defines failure behavior when the watched subtree or assignment enters a failed state.
6. The spike updates the parent concept inventory if any candidate concept should be kept, changed, or rejected.

### Interface Contract

- **Watcher invocation**
  ```bash
  ace-assign watch --assignment 8rddnp
  ace-assign watch --assignment 8rddnp --root 010.03
  ace-assign watch --assignment 8rddnp --poll-interval 300
  ```
- **Behavioral contract**
  - `watch` waits while an active fork session is alive.
  - `watch` re-enters fork execution from assignment state when session liveness is gone but fork work remains non-terminal.
  - `watch` launches the next eligible fork subtree immediately after completion of the current child.
  - `watch` stops when the watched scope is complete, failed, or the next actionable step is non-fork inline/manual work.

### Success Criteria

- [ ] One validated continuation scenario exists for wait, recover, and continue behavior.
- [ ] The spike leaves no behavioral ambiguity about source of truth, liveness checks, recovery, next-child launch, or stop boundaries.
- [ ] The spike confirms `watch` is deterministic fork orchestration, not a general-purpose assignment executor.
- [ ] The parent task can safely rely on the spike outcome when describing watcher behavior.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask spike
- **Slice outcome**: validated continuation/recovery contract for `ace-assign watch`
- **Advisory size**: small
- **Context dependencies**: parent draft, watcher command surface, drive workflow contract, fast watcher coverage

## Verification Plan

### Unit / Component Validation

- Review the watcher contract and confirm it distinguishes waiting, recovery, and launch-next behaviors cleanly.
- Confirm the spike keeps PID/session data as liveness hints only.
- Confirm the spike treats inline/manual execution as an explicit stop boundary.

### Integration / E2E Validation

- Trace a fork-enabled assignment with successive child roots and confirm the watcher contract supports one-invocation continuation.
- Trace an interruption scenario and confirm the watcher contract supports re-entry from assignment state.

### Failure / Invalid Path Validation

- Confirm the spike specifies behavior when a watched subtree fails.
- Confirm the spike specifies behavior when the root scope is not fork-enabled or does not exist.
- Confirm the spike specifies stop behavior when only inline/manual work remains.

### Verification Commands

- `ace-task show 8re.t.mh0.0 --content`
- `ace-assign watch --help`

## Scope of Work

- Validate watcher continuation semantics
- Validate watcher recovery semantics
- Validate watcher stop and failure boundaries
- Refine the parent task if the concept inventory changes

## Deliverables

### Behavioral Specifications

- deterministic watcher continuation contract
- liveness-hint versus status-authority contract
- inline/manual stop-boundary contract

### Validation Artifacts

- stable concept inventory for watcher behavior
- parent-task refinements if needed

## Out of Scope

- implementing runtime code in this drafting step
- designing callback payload schema beyond the handoff needed to parent task `8re.t.mh0.1`
- turning the watcher into a generic runner for non-fork steps

## References

- parent task `8re.t.mh0`
- `ace-assign/lib/ace/assign/cli/commands/watch.rb`
- `ace-assign/lib/ace/assign/cli.rb`
- `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`
- `ace-assign/test/fast/commands/watch_command_test.rb`
