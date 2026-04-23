---
id: 8re.t.n1d.2
status: done
priority: medium
created_at: "2026-04-15 15:21:37"
estimate: TBD
dependencies: [8re.t.n1d.0]
tags: [ace-demo, ace-tmux, tmux]
parent: 8re.t.n1d
bundle:
  presets: [project]
  files: [ace-demo/lib/ace/demo/cli/commands/record.rb, ace-demo/lib/ace/demo/atoms/demo_yaml_parser.rb, ace-demo/lib/ace/demo/atoms/asciinema_tape_compiler.rb, ace-demo/lib/ace/demo/atoms/vhs_tape_compiler.rb, ace-demo/lib/ace/demo/organisms/demo_recorder.rb, ace-demo/docs/usage.md, .ace-tasks/8r6.t.xeu-design-ace-tmux-inspectability-and/8r6.t.xeu-design-ace-tmux-inspectability-and-recording-surfaces.s.md]
  commands: [ace-task show 8re.t.n1d.2 --content, ace-task show 8r6.t.xeu --content]
needs_review: false
---

# Add ace-demo tmux-aware recording directives

## Objective

Define first-class tmux-aware recording directives in `ace-demo` backed by the shared `ace-tmux` control surface so canonical tapes stop relying on raw tmux shell commands and sleep-driven orchestration.

## Behavioral Specification

### User Experience

- Demo authors can express tmux-aware recorder control operations directly in demo tapes instead of embedding raw `tmux` shell commands.
- Tmux-driven recordings become more deterministic because attach, detach, wait, send, and optional capture are expressed as explicit recording operations.
- Visible on-camera feature steps may still use `ace-tmux` commands when that helps the demo contract, while recorder-control plumbing stays structured and off-camera.

### Expected Behavior

1. `ace-demo` defines first-class tmux-aware directives for recorder-control operations such as attach, detach, wait, send, and optional capture.
2. The tmux-aware directive surface is additive to the current YAML tape command model: existing `type:` commands continue to work, and structured tmux command maps are added for tmux-specific recorder control.
3. Those directives are backed by the shared `ace-tmux` control surface rather than ad hoc raw tmux shell invocations.
4. Canonical tmux demos no longer depend on fragile sleep-based background detach hacks as the primary orchestration model.
5. The directive surface focuses on recorder control and verification support, not on replacing visible feature commands that belong on camera.
6. The demo-side tmux contract remains consistent with the generic `ace-tmux` control behavior defined by the shared surface.

### Interface Contract

Structured tape command examples:

```yaml
scenes:
  - name: Attach to operator view
    commands:
      - tmux:
          action: attach
          session: fork-demo
      - tmux:
          action: wait
          for: window-active
          session: fork-demo
          window: work
      - tmux:
          action: send
          pane: fork-demo:work.0
          command: ACE_TMUX_SESSION=fork-demo ace-assign status --assignment "$ASSIGN_ID@010"
      - tmux:
          action: send
          pane: fork-demo:work.0
          key: Enter
      - tmux:
          action: capture
          pane: fork-demo:work-fs.0
          lines: 40
      - tmux:
          action: detach
          session: fork-demo
```

Contract notes:
- structured tmux maps are recorder-control directives; they are not a replacement for ordinary visible `type:` commands
- `wait` in demo tapes is limited to the shared v1 wait conditions from `8re.t.n1d.0`
- `send` in demo tapes uses the shared public `ace-tmux send` contract: command text or bounded named keys
- `capture` is optional and intended for verification/debugging support rather than read-side provenance

Error Handling:
- unresolved tmux targets fail the recording flow clearly
- wait conditions surface a timeout/failure outcome instead of hidden sleep-based flakiness

Edge Cases:
- recorder-control tmux directives remain distinct from visible on-camera commands
- optional capture can support verification/debugging without redefining the read-side provenance contract from `8r6.t.xeu`

### Success Criteria

- [x] The draft specifies first-class tmux-aware recording directives for attach, detach, wait, send, and optional capture.
- [x] Recorder-control behavior is defined as reuse of shared `ace-tmux` control semantics.
- [x] The tmux-aware surface is explicitly additive to existing `type:` scene commands.
- [x] The task clearly distinguishes recorder-control directives from visible on-camera feature commands.
- [x] The contract removes reliance on raw tmux shell glue as the canonical orchestration model.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: behavior-first `ace-demo` tmux-aware directive contract
- **Advisory size**: medium
- **Context dependencies**: shared `ace-tmux` control contract, current YAML tape recording behavior

## Verification Plan

### Unit / Component Validation

- Validate that attach, detach, wait, send, and optional capture are covered as first-class recorder-control behaviors.
- Validate that current YAML tapes using only `type:` commands remain valid and unchanged.
- Validate that the directives reuse the shared `ace-tmux` control surface rather than inventing demo-specific tmux semantics.

### Integration / E2E Validation

- Walk through a tmux demo that starts in one window, waits for a visible transition, and tears down cleanly through structured directives.
- Walk through replacement of the current fork-provider demo detach hack with a structured tmux detach directive.
- Confirm the draft supports deterministic attach/detach and state-transition synchronization without sleep-led shell glue.

### Failure / Invalid Path Validation

- Confirm unresolved tmux targets and wait timeouts are explicit in the draft.
- Confirm visible on-camera commands and off-camera recorder-control directives remain distinct.

### Verification Commands

- `ace-task show 8re.t.n1d.2 --content`
- `ace-task show 8re.t.n1d.0 --content`

## Scope of Work

- Define tmux-aware recorder-control directives for `ace-demo`
- Define one additive YAML extension for structured tmux command maps alongside existing `type:` commands
- Define their reuse boundary with the shared `ace-tmux` control contract
- Define the distinction between recorder control and visible on-camera behavior

## Deliverables

### Behavioral Specifications

- tmux-aware tape directive behavior
- deterministic attach/detach/wait/send/capture orchestration behavior
- recorder-control versus on-camera command boundary

### Validation Artifacts

- parent usage scenario for tmux-aware recording based on structured directives

## Out of Scope

- generic `ace-tmux` control command design owned by subtask `8re.t.n1d.0`
- `ace-assign`-specific delegation behavior
- breaking replacement of the existing `type:` command model
- implementation details of YAML schema internals or parser changes

## References

- parent task `8re.t.n1d`
- sibling task `8r6.t.xeu`
