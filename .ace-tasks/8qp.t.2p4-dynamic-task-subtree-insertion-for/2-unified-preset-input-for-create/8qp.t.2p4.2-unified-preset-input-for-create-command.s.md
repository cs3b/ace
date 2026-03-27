---
id: 8qp.t.2p4.2
status: done
priority: medium
created_at: "2026-03-27 11:52:00"
estimate: small
dependencies: [8qp.t.2p4.1]
tags: [ace-assign, cli]
parent: 8qp.t.2p4
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/cli/commands/create.rb, ace-assign/lib/ace/assign/organisms/task_assignment_creator.rb, ace-assign/lib/ace/assign/organisms/assignment_executor.rb, ace-assign/lib/ace/assign/atoms/preset_loader.rb, ace-assign/.ace-defaults/assign/presets/work-on-task.yml, ace-assign/test/commands/create_command_test.rb, ace-overseer/lib/ace/overseer/molecules/assignment_launcher.rb, ace-overseer/lib/ace/overseer/organisms/work_on_orchestrator.rb, ace-overseer/test/organisms/work_on_orchestrator_test.rb]
  commands: [ace-bundle project]
---

# Unified Preset Input for Create Command

## Objective

Make assignment creation easy from both `ace-assign` and `ace-overseer` by routing both tools through one simple task-driven `create` path. `ace-assign create` becomes explicit-mode only, supports multi-task input via `--task`, and `ace-overseer work-on` adopts it immediately instead of maintaining a separate preset-expansion path.

## Behavioral Specification

### User Experience

- **Input**: Exactly one creation mode: `--yaml <file>` or `--task <ref[,ref...]>` / repeated `--task`, with optional `--preset`
- **Process**: The CLI resolves the input into a hidden job.yaml when task mode is used, then passes it to the existing `executor.start()` path
- **Output**: Assignment ID, step count, first step instructions (same as current create output)

### Expected Behavior

Two mutually exclusive input modes for `ace-assign create`:

1. `ace-assign create --yaml <file>` -- create from a concrete job.yaml
2. `ace-assign create --task <ref[,ref...]> [--task <ref> ...] [--preset <name>]` -- load preset, expand with taskref/taskrefs, filter terminal tasks, create assignment

The positional `CONFIG` argument is removed. `--yaml` is the explicit file mode.

`--preset` defaults to `work-on-task` when omitted. It is only valid with `--task`.

**Task mode (`--task`):**
- Uses repeatable and comma-separated task refs while preserving caller order
- Loads preset via `PresetLoader`
- Rejects draft tasks with the same review guidance currently used by `ace-overseer`
- Filters terminal tasks: skips done/skipped/cancelled, errors if all requested refs are terminal
- For presets supporting `taskrefs`, expands orchestrator refs in place to active child refs while preserving order
- For presets supporting only `taskref`, rejects multi-ref input before assignment creation
- Builds preset params with `taskref` set to the primary requested ref and `taskrefs` set to the expanded ordered active list when supported
- Expands via `PresetExpander.expand(preset, params)`
- Writes hidden job.yaml to `.ace-local/assign/jobs/`
- Passes to `executor.start(job_path)`

**YAML mode (`--yaml`):**
- Passes file path directly to `executor.start(path)`

**`ace-overseer` adoption:**
- `ace-overseer work-on` keeps its current CLI surface and pre-side-effect validation flow
- `AssignmentLauncher` stops performing its own preset expansion and hidden YAML generation
- `AssignmentLauncher` delegates to the shared `ace-assign` task-mode creation path inside the provisioned worktree context
- `ace-overseer` and direct `ace-assign create --task` therefore share the same draft filtering, terminal filtering, preset validation, parameter shaping, and hidden job generation behavior

### Interface Contract

#### CLI

```bash
# Create from preset
ace-assign create --task t.2p4.1 --preset work-on-task
ace-assign create --task t.r6b
ace-assign create --task t.200,t.201 --preset work-on-task
ace-assign create --task t.200 --task t.201 --preset work-on-task

# Create from YAML
ace-assign create --yaml .ace-local/assign/jobs/my-job.yml

# ace-overseer uses the same task-driven path internally
ace-overseer work-on --task t.2p4.1 --preset work-on-task
```

#### Expected Output

```text
Assignment: work-on-task-t.2p4.1-job.yml (8qqgyk)
Created: .ace-local/assign/8qqgyk/

Step 000: onboard [in_progress]
Instructions: ...
```

#### Error Handling

| Condition | Response |
|-----------|----------|
| No input mode provided | Error: "Exactly one of --yaml or --task is required" |
| Both `--yaml` and `--task` provided | Error: "--yaml and --task are mutually exclusive" |
| `--preset` without `--task` | Error: "--preset requires --task" |
| Task ref is draft | Error instructs user to review with `/as-task-review <ref>` before retrying |
| All requested refs are terminal (done/skipped/cancelled) | Error: "All requested tasks are already terminal (done/skipped/cancelled): <refs>. No assignment created." |
| Mixed active + terminal refs | Terminal refs are reported and skipped; assignment is created from active refs only |
| Multi-ref input for preset without `taskrefs` support | Error: "Preset '<name>' accepts only single taskref. Use a preset with `taskrefs` (e.g., --preset work-on-task)." |
| Preset file not found | Error: "Preset 'foo' not found" |
| `--yaml` file not found | Error: "File not found: <path>" |

### Success Criteria

- `ace-assign create --task t.xyz --preset work-on-task` creates a full assignment with expanded step tree
- `ace-assign create --task t.xyz` defaults preset to `work-on-task`
- `ace-assign create --task t.100,t.101 --preset work-on-task` creates one assignment from the ordered active task set
- `ace-assign create --yaml job.yml` preserves existing behavior
- Draft tasks are rejected before assignment creation with review guidance
- Terminal task filtering works across single and multi-ref input before expansion
- `ace-overseer work-on` delegates through the shared task-mode creation path instead of its own preset expansion path
- The positional CONFIG argument is removed; `--yaml` is the only file mode

### Validation Questions

- [Resolved] Two-way mutual exclusivity: `--yaml`, `--task`
- [Resolved] Positional CONFIG removed; `--yaml` replaces it
- [Resolved] `--preset` defaults to `work-on-task`
- [Resolved] Multi-task support is included in `--task` mode so `ace-overseer` can converge on the same path
- [Resolved] `ace-overseer` migration is part of this task, not follow-up work
- [Resolved] Terminal and draft filtering follow the current `ace-overseer` semantics before assignment creation

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice**: Single subtask under the t.2p4 orchestrator (small)
- **Outcome**: `ace-assign create --task` works end-to-end for single and multi-task inputs, and `ace-overseer` uses the same creation path
- **Advisory size**: Small -- reuses `PresetLoader`, `PresetExpander`, and the existing executor start path; adds one shared task-creation service and swaps `ace-overseer` to it
- **Context dependencies**: `PresetLoader`, `PresetExpander`, `AssignmentExecutor.start()`, and `ace-overseer` assignment launching

## Verification Plan

### Unit/Component Validation

- CLI rejects invocations with no input mode
- CLI rejects `--yaml` + `--task` together
- CLI rejects `--preset` without `--task`
- CLI rejects positional config-only invocation
- Shared task-mode creation rejects draft refs with review guidance
- Shared task-mode creation skips terminal refs in mixed sets and errors on all-terminal sets
- Multi-ref input is normalized across repeated and comma-separated `--task`
- Presets without `taskrefs` support reject multi-ref input before assignment creation
- `--task` with valid refs creates assignment with expected steps

### Integration/E2E Validation

- `ace-assign create --task t.xyz --preset work-on-task` creates assignment, `ace-assign status` shows full step tree
- `ace-assign create --task t.100,t.101 --preset work-on-task` creates one assignment from both refs in order
- `ace-assign create --yaml job.yml` still works
- Created assignment has correct `source_config` pointing to archived job.yaml
- `ace-overseer work-on --task ...` still validates before worktree/tmux side effects, then launches through the shared task-mode creation path

### Failure/Invalid Path Validation

- `ace-assign create --task t.done` where all requested tasks are terminal produces terminal error
- `ace-assign create --task t.draft` produces review-required error
- `ace-assign create --task t.xyz --preset nonexistent` produces preset-not-found error
- `ace-assign create` with no flags produces required-mode error

### Verification Commands

- `ace-test ace-assign` -- all existing + new tests pass
- `ace-test ace-overseer` -- overseer integration coverage passes with the shared creation path
- `ace-test-suite` -- no cross-package regressions

## Scope of Work

### User Experience Scope
- `ace-assign create` accepts `--task` + `--preset` for direct preset-based creation
- `ace-assign create --yaml` replaces positional CONFIG
- `ace-overseer work-on` benefits from the same simplified path without changing its CLI

### System Behavior Scope
- Updated `create.rb` command with option-driven input
- Shared task-mode assignment creation service in `ace-assign`
- Reuses `PresetLoader` and `PresetExpander`
- Draft and terminal task filtering before expansion
- `ace-overseer` assignment launch path delegates to the shared service

### Interface Scope
- `ace-assign create --task` flag
- `ace-assign create --preset` flag
- `ace-assign create --yaml` flag
- `ace-overseer work-on` CLI unchanged, but its assignment-creation backend changes

## Deliverables

### Behavioral Specifications
- Option-driven `create` command with preset integration
- Shared task-mode creation behavior across `ace-assign` and `ace-overseer`
- Draft and terminal task filtering on `--task` mode

### Validation Artifacts
- Extended `create_command_test.rb` for new flags and modes
- `ace-overseer` tests validating delegation still preserves current guardrails

## Out of Scope

- Changes to `PresetLoader` or `PresetExpander` semantics
- New preset formats or preset composition
- New public flags for `ace-overseer`

## References

- Plan: `/home/mc/.claude/plans/twinkly-knitting-sutton.md`
- Parent task: t.2p4 (Dynamic Task Subtree Insertion for ace-assign)
- Sibling (completed): t.2p4.0 (YAML Batch Insertion), t.2p4.1 (Preset-Aware Add)
- Existing: `ace-assign/lib/ace/assign/cli/commands/create.rb`
