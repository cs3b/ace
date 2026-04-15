---
id: 8re.t.mh0
status: draft
priority: medium
created_at: "2026-04-15 14:58:55"
estimate: TBD
dependencies: []
tags: []
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/cli/commands/watch.rb, ace-assign/lib/ace/assign/cli.rb, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, ace-assign/handbook/skills/as-assign-drive/SKILL.md, docs/decisions/ADR-034-assignment-watch-and-callback-contract.md]
  commands: [ace-task show 8re.t.mh0 --content, ace-task show 8re.t.mh0.0 --content, ace-task show 8re.t.mh0.1 --content, ace-assign status]
needs_review: false
---

# Harden assignment drive continuation and callback handoff

## Objective

Define a durable assignment-drive continuation contract so forked subtrees run one after another without user nudges, and reserve a callback handoff contract that can wake parent operators without replacing assignment status as the source of truth.

## Behavioral Specification

### User Experience

- An operator starts `/as-assign-drive` for a fork-heavy assignment and does not need to keep typing `continue` after every completed child subtree.
- If a fork subtree is already running when the operator or agent re-enters, the system waits for it, recovers from assignment state if the old session disappeared, and keeps moving.
- When one fork subtree finishes cleanly, the next eligible fork subtree starts immediately if deterministic queue state allows it.
- The drive loop stops only at a real end boundary: assignment complete, subtree complete, failed/blocked state, or the next remaining step requires inline/manual agent execution.
- Future parent notification hooks can wake an operator or parent agent when meaningful events occur, but those hooks do not become the source of truth.

### Expected Behavior

1. `ace-assign watch` provides deterministic fork waiting, interruption recovery, and next-child continuation for fork-enabled assignment work.
2. `/as-assign-drive` delegates fork wait/resume behavior to `ace-assign watch` instead of relying on prompt wording or conversational sleep loops.
3. The watcher may use fork PID/session metadata to detect whether a fork session is still alive, but assignment status remains authoritative for completion and failure.
4. When a watched fork subtree completes, the watcher immediately re-reads status and launches the next eligible fork subtree without handing control back between children.
5. The watcher stops when the watched scope is complete, the whole assignment is complete, a failed/blocked state is reached, or only inline/manual work remains.
6. A future callback layer may emit wake-up events for parent coordination, but delivery is best-effort and cannot mutate assignment truth.

### Interface Contract

- **CLI surface**
  ```bash
  ace-assign watch --assignment 8rddnp
  ace-assign watch --assignment 8rddnp --root 010.03
  ace-assign watch --assignment 8rddnp --poll-interval 300
  ```
- **Watcher contract**
  - `--assignment <id>` identifies the assignment to monitor.
  - `--root <step>` limits the watcher to a specific fork-enabled subtree root.
  - `--poll-interval <seconds>` controls how often the watcher re-checks an active fork session while it is still alive.
  - If a previous fork session is no longer alive but assignment state is still non-terminal, the watcher recovers by re-entering fork execution from assignment state.
  - If the next actionable step is not fork-enabled and requires inline/manual work, the watcher stops and reports that boundary.
- **Workflow contract**
  - `/as-assign-drive` remains the public operator workflow.
  - `ace-assign watch` becomes the deterministic runtime for fork continuation inside that workflow.
- **Callback contract**
  - Callback delivery is notification-only.
  - Consumers must re-check `ace-assign status` before acting.
  - Callback failure must not corrupt or fail the assignment.

### Success Criteria

- [ ] Fork-heavy assignments no longer require user nudges between completed child subtrees.
- [ ] Re-entering a running assignment can wait on an active fork or recover from recorded assignment state after interruption.
- [ ] The watcher launches the next eligible fork subtree immediately after the previous one completes.
- [ ] The watcher stops only at completion, blocker/failure, or inline/manual-work boundaries.
- [ ] Draft usage guidance exists for the new watcher CLI surface and callback reservation.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: orchestrator with spike-first decomposition
- **Slice outcome**: a stable continuation contract for deterministic fork watching plus a separate callback-notification contract
- **Advisory size**: medium
- **Context dependencies**: `ace-assign` queue state, fork session metadata, `/as-assign-drive` workflow contract, ADR for callback reservation
- **Execution shape**
  - `8re.t.mh0.0`: validate the deterministic `ace-assign watch` continuation contract and the stop/recovery boundaries
  - `8re.t.mh0.1`: define the notification-only tmux callback contract layered on top of watcher state

## Verification Plan

### Unit / Component Validation

- Validate that the drafted contract keeps `ace-assign status` as the source of truth while allowing PID/session metadata to support wait decisions.
- Validate that `ace-assign watch` is limited to fork continuation and does not claim to execute arbitrary inline/manual assignment work.
- Validate that callback delivery remains explicitly advisory and best-effort.

### Integration / E2E Validation

- Walk through a multi-child fork assignment and confirm one invocation can wait, recover, and continue through successive fork subtrees without user prompts.
- Walk through an interruption case and confirm a new watcher invocation re-enters from assignment state instead of depending on a stale terminal session.
- Confirm `/as-assign-drive` uses `ace-assign watch` as the deterministic fork path.

### Failure / Invalid Path Validation

- Confirm the draft specifies the stop boundary when the next remaining work is inline/manual rather than fork-enabled.
- Confirm the draft specifies watcher behavior when a subtree or assignment reaches failed state.
- Confirm the draft specifies callback-failure behavior as non-fatal.

### Verification Commands

- `ace-task show 8re.t.mh0 --content`
- `ace-task show 8re.t.mh0.0 --content`
- `ace-task show 8re.t.mh0.1 --content`

## Scope of Work

- Define the deterministic watcher contract for fork waiting, recovery, and continuation
- Define how `/as-assign-drive` hands fork continuation off to the watcher
- Define watcher stop boundaries and source-of-truth semantics
- Define the reserved callback-notification surface for future parent wake-up behavior

## Deliverables

### Behavioral Specifications

- deterministic `ace-assign watch` contract
- `/as-assign-drive` delegation contract for fork continuation
- callback-notification behavioral contract layered on watcher state

### Validation Artifacts

- draft `ux/usage.md` for the watcher CLI surface
- spike subtask validating continuation/recovery boundaries
- callback design subtask defining reserved events and payload

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| Deterministic `ace-assign watch` loop | `8re.t.mh0.0` | -- | CANDIDATE |
| Assignment-state-first recovery | `8re.t.mh0.0` | -- | CANDIDATE |
| Automatic next-child continuation | `8re.t.mh0.0` | -- | CANDIDATE |
| Inline/manual stop boundary | `8re.t.mh0.0` | -- | CANDIDATE |
| Notification-only callback layer | `8re.t.mh0.1` | -- | CANDIDATE |
| `tmux:<target>` callback address shape | `8re.t.mh0.1` | -- | CANDIDATE |

## Out of Scope

- Implementing new package code during this drafting phase
- Turning the watcher into a general-purpose executor for all assignment steps
- Replacing `ace-assign status` with callback signals or tmux state
- Defining non-tmux callback transports in this task

## References

- `ux/usage.md`
- `ace-assign/lib/ace/assign/cli/commands/watch.rb`
- `ace-assign/lib/ace/assign/cli.rb`
- `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`
- `ace-assign/handbook/skills/as-assign-drive/SKILL.md`
- `docs/decisions/ADR-034-assignment-watch-and-callback-contract.md`
