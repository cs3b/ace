---
id: 8re.t.n1d
status: draft
priority: medium
created_at: "2026-04-15 15:21:32"
estimate: TBD
dependencies: []
tags: [ace-tmux, ace-assign, ace-demo, tmux]
bundle:
  presets: [project]
  files:
    - ace-tmux/lib/ace/tmux/cli.rb
    - ace-assign/lib/ace/assign/molecules/tmux_fork_runner.rb
    - ace-demo/lib/ace/demo/cli/commands/record.rb
    - .ace-tasks/8r6.t.xeu-design-ace-tmux-inspectability-and/8r6.t.xeu-design-ace-tmux-inspectability-and-recording-surfaces.s.md
    - ux/usage.md
  commands:
    - ace-task show 8re.t.n1d --content
    - ace-task show 8r6.t.xeu --content
---

# Design ace-tmux control integrations for assignment and demo flows

## Objective

Define the generic `ace-tmux` control-side contract so higher-level ACE tools can interact with tmux through `ace-tmux` instead of raw `tmux`, while keeping sibling task `8r6.t.xeu` as the separate read-side contract for runtime inventory and recording provenance.

## Behavioral Specification

### User Experience

- Operators and higher-level ACE tools can use `ace-tmux` as the public tmux interaction surface instead of shelling directly to raw `tmux`.
- `ace-assign` can delegate tmux-backed fork work through a shared `ace-tmux` runtime/control service instead of owning a parallel private wrapper.
- `ace-demo` can orchestrate tmux-aware recordings through first-class tmux operations instead of shell-level sleeps and raw tmux glue.
- `ace-tmux` remains ACE-managed by default, while still allowing explicit `session`, `window`, or `pane` targeting when detached tools or demo controllers need it.
- The public control surface is distinct from the sibling `ace-tmux state` and recording-provenance contract in `8r6.t.xeu`.

### Expected Behavior

1. `ace-tmux` exposes a public control surface for tmux interactions such as send, capture, wait, attach, and detach.
2. The shared control surface serves both direct operator usage and package-to-package reuse through a Ruby API first, with CLI wrappers over the same runtime behavior.
3. `ace-assign` consumes that shared control surface for tmux delegation behavior while keeping assignment state as the source of truth for subtree completion and failure.
4. `ace-demo` consumes that shared control surface for tmux-aware recorder orchestration rather than embedding raw `tmux` shell commands in canonical demo tapes.
5. The new task does not redefine or absorb the read-side runtime inventory and recording provenance work already owned by sibling task `8r6.t.xeu`.
6. The control surface defaults to ACE-managed sessions but supports explicit targeting for demos and detached controllers.

### Interface Contract

- **`ace-tmux` CLI contract**
  ```bash
  ace-tmux send --pane <target> --command "<text>"
  ace-tmux capture --pane <target> --lines 40
  ace-tmux wait --session <name> --for window-active --window work-fs
  ace-tmux attach --session <name>
  ace-tmux detach --session <name>
  ```
- **Runtime API contract**
  - `ace-tmux` exposes a reusable runtime/control API that higher-level packages can call directly instead of shelling to raw `tmux`.
  - CLI wrappers and Ruby consumers share the same behavior and targeting semantics.
  - Runtime control models are separate from preset/config models.
- **Consumer boundary**
  - `8r6.t.xeu` owns generic runtime inventory and recording provenance.
  - `8re.t.n1d` owns control-side interaction semantics and consumer integrations.
  - `ace-assign` and `ace-demo` must consume the shared `ace-tmux` control surface rather than redefining their own private tmux contracts.

### Success Criteria

- [ ] A behavior-first public contract exists for `ace-tmux send`, `capture`, `wait`, `attach`, and `detach`.
- [ ] The task clearly separates read-side tmux state/provenance from control-side tmux interaction.
- [ ] The control surface is specified for Ruby API reuse first, with CLI wrappers over the same semantics.
- [ ] `ace-assign` and `ace-demo` consumer behavior is defined as reuse of the shared `ace-tmux` control surface.
- [ ] ACE-managed targeting is the default, with explicit targeting allowed where needed.
- [ ] Draft usage guidance exists for direct `ace-tmux` control commands and both consumer integrations.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: orchestrator with three direct subtasks
- **Slice outcome**: ACE gets a shared tmux control contract plus consumer-specific behavior for assignment delegation and demo orchestration
- **Advisory size**: medium
- **Execution shape**
  - `8re.t.n1d.0`: specify the shared `ace-tmux` runtime/control surface
  - `8re.t.n1d.1`: define `ace-assign` consumption of the shared control surface
  - `8re.t.n1d.2`: define `ace-demo` tmux-aware recording directives backed by the shared control surface

## Verification Plan

### Unit / Component Validation

- Validate that the drafted `ace-tmux` control surface is reusable by both operators and higher-level packages.
- Validate that the drafted consumer contracts do not privately redefine tmux behavior already owned by `ace-tmux`.
- Validate that Ruby API first plus CLI wrapper behavior is stated clearly and consistently.

### Integration / E2E Validation

- Walk through a direct operator flow that uses `ace-tmux` control commands without raw `tmux`.
- Walk through an `ace-assign fork-run --launch-mode tmux` flow that reuses the shared control surface.
- Walk through an `ace-demo` tmux-aware recording flow that uses structured tmux operations rather than sleep-based shell orchestration.

### Failure / Invalid Path Validation

- Confirm the task keeps `8r6.t.xeu` as the owner of read-side state/provenance and does not overlap its contract.
- Confirm the task does not promise arbitrary foreign-tmux management as the default behavior.
- Confirm the task avoids implementation-detail decisions such as concrete classes, files, or algorithms beyond public behavior and reuse boundaries.

### Verification Commands

- `ace-task show 8re.t.n1d --content`
- `ace-task show 8re.t.n1d.0 --content`
- `ace-task show 8re.t.n1d.1 --content`
- `ace-task show 8re.t.n1d.2 --content`
- `ace-task show 8r6.t.xeu --content`

## Scope of Work

- Define the shared `ace-tmux` control-side contract
- Define how `ace-assign` reuses that contract for tmux delegation
- Define how `ace-demo` reuses that contract for tmux-aware recording orchestration
- Define the boundary between this task and sibling `8r6.t.xeu`
- Draft usage guidance for the new external/control-facing behavior

## Deliverables

### Behavioral Specifications

- `ace-tmux` control command and runtime API contract
- `ace-assign` control-side integration behavior
- `ace-demo` tmux-aware directive behavior
- explicit ownership boundary versus `8r6.t.xeu`

### Validation Artifacts

- `ux/usage.md` covering direct operator use and both consumer integrations

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| Public `ace-tmux` control commands | `8re.t.n1d.0` | -- | CANDIDATE |
| Shared tmux runtime/control Ruby API | `8re.t.n1d.0` | -- | CANDIDATE |
| `ace-assign` as `ace-tmux` control consumer | `8re.t.n1d.1` | -- | CANDIDATE |
| `ace-demo` tmux-aware recording directives | `8re.t.n1d.2` | -- | CANDIDATE |
| ACE-managed default with explicit targets | `8re.t.n1d.0` | -- | CANDIDATE |
| Separate read-side vs control-side ownership | `8re.t.n1d.0` | -- | CANDIDATE |

## Out of Scope

- Implementing runtime code, tests, or package dependency changes in this drafting pass
- Replacing or rewriting sibling task `8r6.t.xeu`
- Designing semantic recording analysis or recording provenance beyond the read-side contract already covered elsewhere
- Promising non-ACE-managed tmux control as the default operator model

## References

- `ux/usage.md`
- `.ace-ideas/_archive/8r/x/8remm1-ace-tmux-public-control-surface/8remm1-ace-tmux-public-control-surface-for-sessions.idea.s.md`
- `.ace-ideas/_archive/8r/x/8remu2-ace-tmux-runtime-control-surface/8remu2-ace-tmux-runtime-control-surface-for-ace.idea.s.md`
- `.ace-ideas/_archive/8r/x/8remu3-ace-demo-tmux-aware-recording/8remu3-ace-demo-tmux-aware-recording-directives-backed.idea.s.md`
- sibling task `8r6.t.xeu`
