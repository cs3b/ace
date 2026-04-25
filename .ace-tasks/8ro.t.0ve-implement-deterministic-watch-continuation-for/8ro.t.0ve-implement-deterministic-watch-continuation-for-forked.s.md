---
id: 8ro.t.0ve
status: pending
priority: medium
created_at: "2026-04-25 00:34:53"
estimate: TBD
dependencies: []
tags: [ace-assign, watch, workflow, e2e]
bundle:
  presets: [project]
  files: [.ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/8rn.t.z5k-design-deterministic-watch-continuation-for-forked-ace.s.md, .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/0-define-watch-recovery-and-callback/8rn.t.z5k.0-define-watch-recovery-and-callback-artifact-contract.s.md, .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/1-define-ace-assign-watch-command/8rn.t.z5k.1-define-ace-assign-watch-command-and-stop.s.md, .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/2-define-watch-continuation-verification-and/8rn.t.z5k.2-define-watch-continuation-verification-and-e2e-coverage.s.md, .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/ux/usage.md, ace-assign/lib/ace/assign/cli.rb, ace-assign/lib/ace/assign/cli/commands/assignment_target.rb, ace-assign/lib/ace/assign/cli/commands/fork_run.rb, ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb, ace-assign/docs/usage.md, ace-assign/README.md, ace-assign/test/fast/commands/fork_run_command_test.rb, ace-assign/test/fast/organisms/assign_drive_contract_test.rb, ace-assign/test/e2e/TS-ASSIGN-003-operations/scenario.yml, ace-assign/test/e2e/TS-ASSIGN-003-operations/runner.yml.md, ace-assign/test/e2e/TS-ASSIGN-003-operations/verifier.yml.md, .ace-tasks/8ro.t.0ve-implement-deterministic-watch-continuation-for/ux/usage.md]
  commands: [ace-task show 8ro.t.0ve --content, ace-task show 8ro.t.0ve.0 --content, ace-task show 8ro.t.0ve.1 --content, ace-task show 8ro.t.0ve.2 --content, ace-assign status, ace-assign fork-run --help]
needs_review: false
---

# Implement deterministic watch continuation for forked ace-assign work

## Objective

Ship the v1 `ace-assign watch` continuation surface described by the archived `8rn.t.z5k` design family.
The implementation must add a real public CLI command on current `main` that can wait on active fork work, recover from lost parent sessions, continue through pending fork roots in sequence, and stop cleanly when only inline or manual work remains.

## Behavioral Specification

### User Experience

- Operators can run one public command to keep fork-heavy assignments moving without repeatedly nudging the parent process after every child subtree.
- The same command can watch either the full assignment or one explicit scoped subtree and produces deterministic stop behavior.
- Users can restart the watcher later and recover from persisted assignment state instead of depending on the original pane or process handle.
- Reviewers get one shipped behavior surface backed by direct fast tests, retained E2E coverage, and package docs instead of relying on archived task artifacts.

### Expected Behavior

1. `ace-assign watch` is registered as a public CLI command and appears in help output, package docs, and task-local usage scenarios.
2. `ace-assign status` remains the canonical source of truth for subtree completion, assignment completion, failed watched work, next runnable fork root, and inline/manual tail detection.
3. Scoped invocations such as `--assignment <id>@<root>` or `--assignment <id> --root <root>` operate only inside that subtree and never widen back to parent siblings.
4. Unscoped invocations such as `--assignment <id>` may continue through multiple pending fork roots in sequence, but stop when no fork work remains and only inline/manual work is left.
5. PID and session metadata remain advisory telemetry only. They can distinguish wait versus recover, but they never overrule assignment state.
6. Existing `fork-run --callback` behavior remains compatible. Callback text is still a wake-up hint only and is not promoted into a required watcher event API.
7. Invalid targeting, failed watched scopes, and invalid poll intervals fail clearly with non-zero exit status.
8. The retained `TS-ASSIGN-003-operations` suite grows in place to validate sequential continuation and interruption recovery.

### Interface Contract

```bash
ace-assign watch --assignment 8abcd1
ace-assign watch --assignment 8abcd1@010
ace-assign watch --assignment 8abcd1 --root 010 --poll-interval 300
```

- `--assignment <id>` watches the full assignment as a parent continuation surface.
- `--assignment <id>@<root>` watches one scoped subtree only.
- `--assignment <id> --root <root>` is semantically identical to the scoped form above.
- `--poll-interval` is a positive integer in seconds and changes only wait/recovery polling frequency, not assignment truth semantics.
- Startup output names the watched assignment or subtree and the effective poll interval.
- Wait output reports that active fork work still appears alive.
- Recovery output reports that the watcher resumed from assignment state because historical session/process telemetry no longer supports liveness.
- Launch output reports when the next pending fork root is started.
- Stop output reports when only inline/manual work remains.
- Completion output reports successful terminal completion of the watched scope.

### Success Criteria

- [ ] `ace-assign watch` is implemented and documented as a public CLI command.
- [ ] Scoped versus unscoped behavior matches the archived design family without widening scoped targets.
- [ ] Status remains authoritative and telemetry remains advisory-only.
- [ ] Invalid/failure cases exit non-zero with explicit CLI errors.
- [ ] Fast tests and retained E2E cover sequential continuation and interruption recovery.
- [ ] Package docs and task-local usage docs describe the final shipped command surface.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: orchestrator with three implementation subtasks
- **Slice outcome**: shipped watcher runtime behavior, verification coverage, and package docs
- **Advisory size**: medium
- **Context dependencies**: archived `8rn.t.z5k` design bundle, current assignment targeting/fork-run behavior, current retained `TS-ASSIGN-003` suite
- **Child task map**
  - `8ro.t.0ve.0`: implement scoped watch targeting, CLI registration, and stop-state behavior
  - `8ro.t.0ve.2`: implement unscoped continuation, wait semantics, and interruption recovery
  - `8ro.t.0ve.1`: implement direct watcher verification, retained E2E updates, and package docs

## Verification Plan

### Unit / Component Validation

- Confirm the new CLI command is registered and discoverable from `ace-assign --help`.
- Confirm scoped and unscoped target parsing match the archived contract.
- Confirm live-child wait and lost-session recovery are driven by status plus advisory telemetry.

### Integration / E2E Validation

- Confirm full-assignment watch continues across multiple fork roots until inline/manual work remains.
- Confirm scoped watch exits cleanly for already terminal subtrees and never widens to later parent siblings.
- Confirm the retained `TS-ASSIGN-003` suite passes with additive `TC-003` and `TC-004` goals.

### Failure / Invalid Path Validation

- Confirm conflicting root targeting, invalid non-fork roots, failed watched scopes, and invalid poll intervals all fail with non-zero exits.
- Confirm missing callback text never causes false failure while status still shows healthy work.
- Confirm `Errno::EPERM` is treated as "alive but not signalable," not as proof of process death.

### Verification Commands

- `ace-test ace-assign test/fast/commands/watch_command_test.rb`
- `ace-test ace-assign test/fast/organisms/assign_drive_contract_test.rb`
- `ace-test ace-assign test/fast/commands/fork_run_command_test.rb`
- `ace-test ace-assign test/e2e/TS-ASSIGN-003-operations`

## Scope of Work

- implement the public `ace-assign watch` CLI surface
- implement scoped and unscoped continuation behavior
- implement wait and recovery semantics using current fork telemetry
- implement direct fast tests, retained E2E updates, and package docs

## Deliverables

### Behavioral Specifications

- shipped watcher command surface
- deterministic stop-state and recovery behavior
- retained status-versus-telemetry ownership rules

### Validation Artifacts

- direct fast tests for watcher behavior
- additive `TS-ASSIGN-003` watcher coverage
- updated package docs and `ux/usage.md`

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| Public `ace-assign watch` command | `8ro.t.0ve.0` | -- | KEPT |
| Scoped subtree watch boundary | `8ro.t.0ve.0` | -- | KEPT |
| Sequential multi-root continuation | `8ro.t.0ve.2` | -- | KEPT |
| Telemetry-driven wait/recover classification | `8ro.t.0ve.2` | -- | KEPT |
| Retained-suite watcher E2E coverage | `8ro.t.0ve.1` | -- | KEPT |
| Package docs for watcher surface | `8ro.t.0ve.1` | -- | KEPT |

## Out of Scope

- structured event emission in v1
- a new `watch --callback` API
- generic observer or event-bus infrastructure
- scheduler changes beyond sequential continuation on current `main`

## References

- archived design family `8rn.t.z5k`
- `ux/usage.md`
- `ace-assign/lib/ace/assign/cli/commands/assignment_target.rb`
- `ace-assign/lib/ace/assign/cli/commands/fork_run.rb`
- `ace-assign/test/e2e/TS-ASSIGN-003-operations/scenario.yml`
