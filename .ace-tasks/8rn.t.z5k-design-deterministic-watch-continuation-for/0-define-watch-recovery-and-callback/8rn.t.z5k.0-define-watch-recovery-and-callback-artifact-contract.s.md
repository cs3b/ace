---
id: 8rn.t.z5k.0
status: draft
priority: medium
created_at: "2026-04-24 23:26:18"
estimate: TBD
dependencies: []
tags: [ace-assign, tmux, callback]
parent: 8rn.t.z5k
bundle:
  presets: [project]
  files: [.ace-tasks/8rn.t.z5k-design-deterministic-watch-continuation-for/8rn.t.z5k-design-deterministic-watch-continuation-for-forked-ace.s.md, ace-assign/lib/ace/assign/cli/commands/fork_run.rb, ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb, ace-assign/lib/ace/assign/molecules/tmux_control_surface_runner.rb, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, ace-assign/docs/usage.md, ace-assign/test/fast/commands/fork_run_command_test.rb, ace-assign/test/fast/molecules/fork_session_launcher_test.rb, ace-assign/test/fast/organisms/assign_drive_contract_test.rb, ux/usage.md]
  commands: [ace-task show 8rn.t.z5k.0 --content, ace-task show 8rn.t.z5k --content, ace-assign fork-run --help]
---

# Define watch recovery and callback artifact contract

## Objective

Define how the future watcher contract recovers from lost parent sessions and coexists with current callback mode on `main`, while preserving structured event samples as **task artifacts only** instead of v1 runtime API.

## Behavioral Specification

### User Experience

- Operators can resume continuation from assignment state even when the original parent drive terminal or provider session is gone.
- Current callback-mode flows remain valid and understandable: a child fork can still send one final sentence back into the origin tmux pane before stopping.
- Designers and implementers retain the useful structured event intent from PR `#296` as examples in the task artifacts without being forced to ship that API in v1.

### Expected Behavior

1. Recovery begins from `ace-assign status` and scoped subtree state, not from historical PTY handles.
2. Callback mode remains an additive compatibility path for interactive tmux parent/child flows.
3. Watcher design must treat callback messages as wake-up hints only; they do not replace assignment state as truth.
4. Event-like payloads may be preserved in task artifacts for future follow-up, but v1 implementation is not required to emit them.
5. The task must explicitly distinguish between:
   - current shipped behavior that implementers must preserve
   - future artifact examples that remain illustrative only

### Interface Contract

- **Current shipped callback contract to preserve**
  ```bash
  ace-assign fork-run --assignment 8abcd1@010 --launch-mode tmux --callback
  ```
  Expected v1-preserved behavior:
  - parent origin pane is captured via `ACE_ASSIGN_CALLBACK_PANE`
  - child fork session receives that pane id in its environment
  - child sends one final success or failure sentence with direct `ace-tmux send`
- **Recovery contract**
  - if the parent terminal/session disappears, a fresh watcher or drive invocation must recover from assignment state
  - callback absence is never proof of failure
  - stale callback text is never proof of completion
- **Artifact-only event examples**
  ```json
  ACE_ASSIGN_EVENT {"assignment_id":"8abcd1","scope":"010","event":"subtree_completed","current_step":"010.02","next_step":"020","session_id":"sess_123","report_path_or_dir":".ace-local/assign/8abcd1/reports/","resume_command":"ace-assign watch --assignment 8abcd1","timestamp":"2026-04-25T00:00:00Z"}
  ACE_ASSIGN_EVENT {"assignment_id":"8abcd1","scope":"010","event":"subtree_failed","current_step":"010.02","next_step":null,"session_id":"sess_123","report_path_or_dir":".ace-local/assign/8abcd1/reports/010.02-report.md","resume_command":"ace-assign watch --assignment 8abcd1@010","timestamp":"2026-04-25T00:00:00Z"}
  ACE_ASSIGN_EVENT {"assignment_id":"8abcd1","scope":null,"event":"assignment_completed","current_step":null,"next_step":null,"session_id":"sess_parent","report_path_or_dir":".ace-local/assign/8abcd1/reports/","resume_command":null,"timestamp":"2026-04-25T00:00:00Z"}
  ```
- **Artifact-only rules**
  - examples must be clearly labeled “future event examples”
  - examples must not appear in success criteria as required runtime behavior
  - implementers must not infer a mandatory `watch --callback` API from these artifacts

### Success Criteria

- [ ] The task preserves current callback-pane behavior as a required compatibility contract.
- [ ] The task specifies status-first interruption recovery and rejects historical terminal handles as source of truth.
- [ ] The task includes concrete structured event examples in the artifact body and `ux/usage.md`.
- [ ] The task makes those event examples explicitly non-binding for v1.
- [ ] The task leaves no ambiguity about callback-message versus status-truth ownership.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: decision-complete recovery and callback compatibility contract with preserved future event examples
- **Advisory size**: medium
- **Context dependencies**: current `fork-run --callback`, current drive workflow callback guidance, current tmux control surface

## Verification Plan

### Unit / Component Validation

- Confirm the subtask preserves current callback-pane semantics already reflected in tests and docs.
- Confirm event examples are labeled illustrative only.

### Integration / E2E Validation

- Walk through a resumed parent flow where callback never arrives but status proves subtree completion.
- Walk through an interactive callback flow where the child sends the final sentence and the parent resumes from status.

### Failure / Invalid Path Validation

- Confirm callback text alone never marks a subtree complete.
- Confirm missing callback delivery does not corrupt assignment truth.
- Confirm the task does not accidentally promote event examples into required API surface.

### Verification Commands

- `ace-task show 8rn.t.z5k.0 --content`
- `ace-task show 8rn.t.z5k --content`
- `ace-assign fork-run --help`

## Scope of Work

- define interruption recovery rules
- define watcher compatibility with current callback mode
- preserve future event shapes as artifacts only
- define exact boundaries between callback hints and assignment truth

## Deliverables

### Behavioral Specifications

- callback compatibility contract
- interruption recovery contract
- future event example appendix with explicit non-binding status

### Validation Artifacts

- event example payloads in spec body
- usage scenarios in `ux/usage.md`

## Out of Scope

- implementing runtime event emission
- introducing a new `watch --callback` API in this family
- redefining `fork-run` launch semantics beyond compatibility and recovery behavior

## References

- parent task `8rn.t.z5k`
- `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`
- `ace-assign/lib/ace/assign/cli/commands/fork_run.rb`
- `ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb`
