---
id: 8rn.t.z5k
status: pending
priority: medium
created_at: "2026-04-24 23:26:11"
estimate: TBD
dependencies: []
tags: [ace-assign, ace-tmux, workflow, e2e]
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/cli.rb, ace-assign/lib/ace/assign/cli/commands/fork_run.rb, ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, ace-assign/docs/usage.md, ace-assign/test/fast/commands/fork_run_command_test.rb, ace-assign/test/fast/molecules/fork_session_launcher_test.rb, ace-assign/test/fast/organisms/assign_drive_contract_test.rb, ace-assign/test/e2e/TS-ASSIGN-003-operations/scenario.yml, ace-assign/test/e2e/TS-ASSIGN-003-operations/runner.yml.md, ace-assign/test/e2e/TS-ASSIGN-003-operations/verifier.yml.md, .ace-tasks/_archive/8r/w/8r6.t.u53-design-visible-tmux-backed-fork/8r6.t.u53-design-visible-tmux-backed-fork-execution-for.s.md, .ace-tasks/_archive/8r/x/8re.t.n1d-design-ace-tmux-control-integrations/8re.t.n1d-design-ace-tmux-control-integrations-for-assignment.s.md, ux/usage.md]
  commands: [ace-task show 8rn.t.z5k --content, ace-task show 8rn.t.z5k.0 --content, ace-task show 8rn.t.z5k.1 --content, ace-task show 8rn.t.z5k.2 --content, ace-assign status, ace-assign fork-run --help]
needs_review: false
---

# Design deterministic watch continuation for forked ace-assign work

## Objective

Define the missing deterministic continuation contract for fork-heavy `ace-assign` work on top of current `main`.
This family captures the one remaining product gap left after the tmux control surface, callback-pane plumbing, scoped subtree rules, and detached recovery guidance landed separately: a parent-side `ace-assign watch` command that can wait on active fork work, recover when the original session disappears, and continue into the next pending fork subtree without manual nudges.

This family must treat current `fork-run`, current callback mode, current `ace-assign status`, and current `TS-ASSIGN-003` as the baseline. It must not resurrect the older `#296` branch as implementation truth.

## Behavioral Specification

### User Experience

- Operators and higher-level workflows can use a deterministic CLI continuation surface instead of relying on prompt prose or ad hoc shell polling loops to keep fork-heavy assignments moving.
- A parent assignment driver can leave and later resume from assignment state without losing continuation behavior.
- Scoped subtree work continues to obey the existing `@<root>` boundary contract and never widens back to parent scope implicitly.
- Current tmux callback mode remains available for interactive parent/child flows, but the new watcher becomes the generic state-based continuation primitive.
- Event-style callback payloads may be documented as future examples in task artifacts, but v1 behavior remains centered on `status`, `fork-run`, and the existing callback sentence contract.

### Expected Behavior

1. `ace-assign watch` becomes the public deterministic continuation command for waiting on active fork work and launching the next pending fork subtree.
2. `ace-assign status` remains the canonical source of truth for subtree completion, assignment completion, failure, and next runnable work.
3. PID and session metadata are advisory telemetry only. They may influence whether the watcher treats a fork as still alive or recoverable, but never override assignment state.
4. Scoped watcher invocations such as `ace-assign watch --assignment <id>@<root>` operate only within that subtree and never inspect later parent siblings.
5. Unscoped watcher invocations may continue through multiple fork roots in sequence, but stop when only inline/manual work remains or when the assignment reaches a real failure/blocker boundary.
6. The new family covers sequential continuation and interruption recovery only. It does not expand the public contract to include broader observer platforms, event buses, or parallel refill semantics.
7. Existing `fork-run --callback`, `ACE_ASSIGN_CALLBACK_PANE`, and direct `ace-tmux send` callback messaging remain compatible with the watcher contract and are not replaced in v1.

### Interface Contract

- **New public CLI surface**
  ```bash
  ace-assign watch --assignment 8abcd1
  ace-assign watch --assignment 8abcd1@010
  ace-assign watch --assignment 8abcd1 --root 010 --poll-interval 300
  ```
- **Scope contract**
  - `--assignment <id>` watches the assignment as a parent orchestrator.
  - `--assignment <id>@<root>` watches only the scoped subtree.
  - `--root <root>` is a convenience for explicit subtree targeting and must reject conflicts with a scoped `@<root>`.
- **Stop contract**
  - continue while active or pending fork work remains
  - stop when watched scope is terminal
  - stop when watched scope contains only inline/manual work
  - fail clearly when watched scope has failed steps
- **Telemetry contract**
  - live PID/session metadata may classify “wait” versus “recover”
  - telemetry is never authoritative over `ace-assign status`
- **Current callback compatibility**
  - keep current child message examples:
    ```bash
    ace-tmux send --pane "$ACE_ASSIGN_CALLBACK_PANE" --msg "Fork subtree ${FORK_ROOT} for assignment ${ASSIGNMENT_ID} completed. Resume parent assignment drive now." --key Enter
    ace-tmux send --pane "$ACE_ASSIGN_CALLBACK_PANE" --msg "Fork subtree ${FORK_ROOT} for assignment ${ASSIGNMENT_ID} failed. Resume parent assignment drive and inspect scoped status." --key Enter
    ```
- **Future structured event examples for artifacts only**
  - These are non-binding examples to preserve useful design intent without turning them into v1 runtime obligations:
    ```json
    ACE_ASSIGN_EVENT {"assignment_id":"8abcd1","scope":"010","event":"subtree_completed","current_step":"010.02","next_step":"020","session_id":"sess_123","report_path_or_dir":".ace-local/assign/8abcd1/reports/","resume_command":"ace-assign watch --assignment 8abcd1","timestamp":"2026-04-25T00:00:00Z"}
    ACE_ASSIGN_EVENT {"assignment_id":"8abcd1","scope":"010","event":"assignment_blocked","current_step":"030","next_step":null,"session_id":"sess_123","report_path_or_dir":".ace-local/assign/8abcd1/reports/030-report.md","resume_command":"/as-assign-drive 8abcd1","timestamp":"2026-04-25T00:00:00Z"}
    ```

### Success Criteria

- [ ] A behavior-first parent task exists for `ace-assign watch` grounded in current `main` rather than the abandoned `#296` implementation.
- [ ] The family explicitly preserves current `fork-run --callback` and callback-pane behavior as compatible v1 surfaces.
- [ ] The family makes `ace-assign status` the canonical truth and telemetry advisory-only.
- [ ] The family specifies scoped versus unscoped watch behavior without leaving boundary decisions to the implementer.
- [ ] The family includes a dedicated verification/E2E subtask that extends current `TS-ASSIGN-003` rather than inventing a disconnected test surface.
- [ ] A task-local `ux/usage.md` artifact exists and includes concrete watcher scenarios plus event example payloads.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: orchestrator with three direct child subtasks
- **Slice outcome**: ACE gains an implementation-ready behavioral contract for deterministic fork continuation and its missing verification coverage
- **Advisory size**: medium
- **Context dependencies**: current `fork-run`, current callback mode, current drive workflow, current `TS-ASSIGN-003`, archived design families `8r6.t.u53` and `8re.t.n1d`
- **Child task map**
  - `8rn.t.z5k.0`: define recovery rules, current callback compatibility, and non-binding event artifact examples
  - `8rn.t.z5k.1`: define the `ace-assign watch` CLI and stop-state contract
  - `8rn.t.z5k.2`: define concrete fast-test and E2E coverage additions

## Verification Plan

### Unit / Component Validation

- Confirm the family does not treat the old PR branch as canonical truth.
- Confirm the watcher contract is decision-complete for scope, stop conditions, telemetry, and failure behavior.
- Confirm event examples are clearly marked as artifact-only and not v1 emitted behavior.

### Integration / E2E Validation

- Confirm the family can be read end-to-end as one cohesive continuation design on top of current `main`.
- Confirm the child tasks cover parent-side watch behavior, callback compatibility, and missing verification additions without overlap.
- Confirm the `ux/usage.md` scenarios are executable as behavioral acceptance contracts.

### Failure / Invalid Path Validation

- Confirm the family never lets scoped watch widen back to parent assignment state.
- Confirm the family does not replace current callback mode with an unimplemented event API.
- Confirm the family does not promise broader parallel scheduler behavior that current `main` does not establish.

### Verification Commands

- `ace-task show 8rn.t.z5k --content`
- `ace-task show 8rn.t.z5k.0 --content`
- `ace-task show 8rn.t.z5k.1 --content`
- `ace-task show 8rn.t.z5k.2 --content`

## Scope of Work

- define a deterministic watcher contract for parent-side fork continuation
- define interruption recovery and callback compatibility on top of current `main`
- define the exact missing fast-test and E2E additions
- preserve useful future event-shape examples in artifacts without promoting them into v1 runtime API

## Deliverables

### Behavioral Specifications

- public `ace-assign watch` CLI contract
- interruption recovery contract
- callback compatibility and event-example contract
- exact verification and E2E coverage contract

### Validation Artifacts

- task-local `ux/usage.md` with watcher flows, callback compatibility notes, event examples, and test-artifact expectations

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| Public `ace-assign watch` continuation command | `8rn.t.z5k.1` | -- | CANDIDATE |
| Status-as-source-of-truth continuation model | existing implementation + `8rn.t.z5k.1` | -- | ACCEPTED (KEPT) |
| PID/session telemetry as advisory recovery aid | `8rn.t.z5k.1` | -- | CANDIDATE |
| Callback compatibility with `ACE_ASSIGN_CALLBACK_PANE` | `8rn.t.z5k.0` | -- | CANDIDATE |
| Future structured event payload examples in artifacts only | `8rn.t.z5k.0` | -- | CANDIDATE |
| Sequential continuation and interruption recovery E2E coverage | `8rn.t.z5k.2` | -- | CANDIDATE |

## Out of Scope

- implementing runtime code, tests, or workflow changes in this drafting pass
- replacing current `fork-run --callback` with a new emitted event API
- defining broader watcher-platform hooks, event buses, or generic observer infrastructure
- promising new parallel refill or multi-root scheduling semantics beyond sequential continuation on current `main`

## References

- `ux/usage.md`
- archived PR `#296` as source context only
- sibling historical design family `8r6.t.u53`
- sibling historical design family `8re.t.n1d`
- `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`
- `ace-assign/lib/ace/assign/cli/commands/fork_run.rb`
- `ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb`
