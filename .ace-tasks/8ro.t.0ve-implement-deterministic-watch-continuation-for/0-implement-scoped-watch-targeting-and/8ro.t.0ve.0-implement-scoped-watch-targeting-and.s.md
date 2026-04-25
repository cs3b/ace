---
id: 8ro.t.0ve.0
status: draft
priority: medium
created_at: "2026-04-25 00:34:53"
estimate: TBD
dependencies: []
tags: [ace-assign, watch, cli]
parent: 8ro.t.0ve
bundle:
  presets: [project]
  files:
    - .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/1-define-ace-assign-watch-command/8rn.t.z5k.1-define-ace-assign-watch-command-and-stop.s.md
    - .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/ux/usage.md
    - ace-assign/lib/ace/assign/cli.rb
    - ace-assign/lib/ace/assign/cli/commands/assignment_target.rb
    - ace-assign/lib/ace/assign/cli/commands/fork_run.rb
    - ace-assign/docs/usage.md
    - ace-assign/test/fast/commands/assignment_target_test.rb
    - ace-assign/test/fast/commands/fork_run_command_test.rb
    - ux/usage.md
  commands:
    - ace-task show 8ro.t.0ve.0 --content
    - ace-assign status
    - ace-assign fork-run --help
---

# Implement scoped watch targeting and stop-state behavior

## Objective

Implement the public watcher command shell and all scoped targeting and stop-state behavior needed for deterministic subtree watching.

## Behavioral Specification

### User Experience

- Users can invoke a real `ace-assign watch` command from the CLI instead of relying on archived task prose.
- Users can explicitly target either a whole assignment or one fork subtree and get deterministic startup and stop messaging.
- Users see clear CLI errors when they provide conflicting scope inputs, non-fork roots, failed watched scopes, or invalid poll intervals.

### Expected Behavior

1. `ace-assign watch` is added to the CLI registry and help examples.
2. `--assignment <id>@<root>` and `--assignment <id> --root <root>` resolve to the same scoped execution boundary.
3. Conflicting scoped forms such as `--assignment <id>@010 --root 020` fail before any watch loop begins.
4. Scoped targets that are already terminal exit successfully without relaunching work.
5. Watched scopes that contain failed work exit non-zero with an explicit failure message.
6. Watched scopes that contain no remaining fork work and only inline/manual work exit successfully with an explicit stop summary.
7. Invalid non-fork roots and invalid poll intervals fail non-zero with clear CLI errors.

### Interface Contract

```bash
ace-assign watch --assignment 8abcd1@010
ace-assign watch --assignment 8abcd1 --root 010
ace-assign watch --assignment 8abcd1 --poll-interval 60
```

- CLI options in v1:
  - `--assignment <id>`
  - `--root <root>`
  - `--poll-interval <seconds>`
  - `--quiet`
  - `--debug`
- Startup summary reports assignment id, optional subtree root, and effective poll interval.
- Stop summary names the remaining inline/manual boundary when fork work is exhausted.
- Error output is explicit and non-zero for:
  - conflicting `--root` versus scoped `@<root>`
  - non-fork root target
  - invalid or non-positive poll interval
  - watched failed scope

### Success Criteria

- [ ] `ace-assign watch` is registered in `ace-assign/lib/ace/assign/cli.rb`.
- [ ] Scoped-target parsing is deterministic and rejects conflicting root forms.
- [ ] Terminal scoped subtrees exit successfully without relaunching.
- [ ] Manual-tail stop behavior is implemented for watched scopes with no remaining fork work.
- [ ] Invalid-target and invalid-poll-interval paths fail non-zero.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: shipped scoped watcher entrypoint and stop-state behavior
- **Advisory size**: medium
- **Context dependencies**: current assignment targeting helpers, current fork-root detection rules, archived watcher contract

## Verification Plan

### Unit / Component Validation

- Add direct watcher command tests for scoped-complete exit.
- Add tests for `--assignment <id> --root <root>` equivalence to scoped assignment syntax.
- Add tests for conflicting scoped root rejection and invalid poll interval rejection.

### Integration / E2E Validation

- Confirm scoped watch on an already terminal subtree exits success without relaunching.
- Confirm scoped watch on a non-fork root exits non-zero before watch-loop work begins.

### Failure / Invalid Path Validation

- Confirm failed watched scopes exit non-zero.
- Confirm inline/manual-tail stop exits success with an explicit stop summary.

### Verification Commands

- `ace-test ace-assign test/fast/commands/watch_command_test.rb`
- `ace-test ace-assign test/fast/commands/assignment_target_test.rb`

## Scope of Work

- add watcher CLI registration and help entries
- implement watcher option parsing and scoped target resolution
- implement scoped terminal success, failed-scope failure, and manual-tail stop behavior

## Deliverables

### Behavioral Specifications

- real watcher command surface
- scoped targeting rules
- explicit stop and failure semantics

### Validation Artifacts

- direct fast tests for scoped and invalid-input behavior
- usage scenarios in `ux/usage.md`

## Out of Scope

- multi-root unscoped continuation logic
- PID/session wait and recovery classification
- retained E2E and package docs updates

## References

- archived task `8rn.t.z5k.1`
- `ace-assign/lib/ace/assign/cli/commands/assignment_target.rb`
- `ace-assign/lib/ace/assign/cli/commands/fork_run.rb`
