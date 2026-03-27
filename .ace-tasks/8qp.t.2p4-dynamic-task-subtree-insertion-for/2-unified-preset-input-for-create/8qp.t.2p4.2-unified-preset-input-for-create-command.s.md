---
id: 8qp.t.2p4.2
status: draft
priority: medium
created_at: "2026-03-27 11:52:00"
estimate: small
dependencies: [8qp.t.2p4.1]
tags: [ace-assign, cli]
parent: 8qp.t.2p4
bundle:
  presets: [project]
  files:
    - ace-assign/lib/ace/assign/cli/commands/create.rb
    - ace-assign/lib/ace/assign/cli/commands/add.rb
    - ace-assign/lib/ace/assign/organisms/assignment_executor.rb
    - ace-assign/lib/ace/assign/atoms/preset_loader.rb
    - ace-assign/lib/ace/assign/molecules/preset_job_builder.rb
    - ace-assign/.ace-defaults/assign/presets/work-on-task.yml
    - ace-assign/test/commands/create_command_test.rb
  commands: [ace-bundle project]
---

# Unified Preset Input for Create Command

## Objective

Give `ace-assign create` the same `--yaml` and `--task` input modes that `add` already has (from t.2p4.1), so assignment creation works directly from a preset+taskref without the two-step prepare+create flow. This lets `ace-overseer work-on` delegate directly to `ace-assign create --task <ref> --preset work-on-task`.

## Behavioral Specification

### User Experience

- **Input**: Exactly one creation mode: `--yaml <file>` or `--task <ref>` with optional `--preset`
- **Process**: The CLI resolves the input into a job.yaml (loading preset and expanding if needed), then passes it to the existing `executor.start()` path
- **Output**: Assignment ID, step count, first step instructions (same as current create output)

### Expected Behavior

Two mutually exclusive input modes for `ace-assign create`:

1. `ace-assign create --yaml <file>` -- create from a concrete job.yaml (replaces positional CONFIG argument)
2. `ace-assign create --task <ref> [--preset <name>]` -- load preset, expand with taskref, filter terminal tasks, create assignment

The positional `CONFIG` argument is removed. `--yaml` is the explicit file mode.

`--preset` defaults to `work-on-task` when omitted. It is only valid with `--task`.

**Task mode (`--task`):**
- Loads preset via `PresetLoader` (reused from t.2p4.1)
- Normalizes taskref to `{"taskrefs" => [ref]}`
- Filters terminal tasks: runs `ace-task show <ref>`, skips done/skipped/cancelled, errors if all terminal
- Expands via `PresetExpander.expand(preset, params)`
- Writes hidden job.yaml to `.ace-local/assign/jobs/`
- Passes to `executor.start(job_path)`

**YAML mode (`--yaml`):**
- Passes file path directly to `executor.start(path)` (same as current positional CONFIG)

### Interface Contract

#### CLI

```bash
# Create from preset (new -- replaces prepare+create two-step)
ace-assign create --task t.2p4.1 --preset work-on-task
ace-assign create --task t.r6b

# Create from YAML (existing behavior, new flag name)
ace-assign create --yaml .ace-local/assign/jobs/my-job.yml
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
| Task ref is terminal (done/skipped/cancelled) | Error: "Task <ref> is already terminal (done). No assignment created." |
| Preset file not found | Error: "Preset 'foo' not found" |
| `--yaml` file not found | Error: "File not found: <path>" |

### Success Criteria

- `ace-assign create --task t.xyz --preset work-on-task` creates a full assignment with expanded step tree
- `ace-assign create --task t.xyz` defaults preset to `work-on-task`
- `ace-assign create --yaml job.yml` preserves existing behavior
- Terminal task filtering works (done tasks rejected before expansion)
- `ace-overseer` can replace its `AssignmentLauncher` internals with `ace-assign create --task`
- The positional CONFIG argument is removed; `--yaml` is the only file mode

### Validation Questions

- [Resolved] Two-way mutual exclusivity: `--yaml`, `--task`
- [Resolved] Positional CONFIG removed; `--yaml` replaces it
- [Resolved] `--preset` defaults to `work-on-task`
- [Resolved] Terminal filtering reuses `ace-task show` status check pattern from prepare workflow

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice**: Single subtask under the t.2p4 orchestrator (small)
- **Outcome**: `ace-assign create --task` works end-to-end, `ace-overseer` can delegate to it
- **Advisory size**: Small -- reuses `PresetLoader`, `PresetExpander`, and `PresetJobBuilder` from t.2p4.1; only the create command CLI and its tests change
- **Context dependencies**: `PresetLoader` and `PresetJobBuilder` from t.2p4.1, `AssignmentExecutor.start()`

## Verification Plan

### Unit/Component Validation

- CLI rejects invocations with no input mode
- CLI rejects `--yaml` + `--task` together
- CLI rejects `--preset` without `--task`
- `--task` with terminal task ref produces clear error
- `--task` with valid ref creates assignment with expected steps

### Integration/E2E Validation

- `ace-assign create --task t.xyz --preset work-on-task` creates assignment, `ace-assign status` shows full step tree
- `ace-assign create --yaml job.yml` still works (backward compat)
- Created assignment has correct `source_config` pointing to archived job.yaml

### Failure/Invalid Path Validation

- `ace-assign create --task t.done` where task is done produces terminal error
- `ace-assign create --task t.xyz --preset nonexistent` produces preset-not-found error
- `ace-assign create` with no flags produces required-mode error

### Verification Commands

- `ace-test ace-assign` -- all existing + new tests pass
- `ace-test-suite` -- no cross-package regressions

## Scope of Work

### User Experience Scope
- `ace-assign create` accepts `--task` + `--preset` for direct preset-based creation
- `ace-assign create --yaml` replaces positional CONFIG

### System Behavior Scope
- Updated `create.rb` command with option-driven input
- Reuses `PresetLoader`, `PresetExpander`, `PresetJobBuilder` from t.2p4.1
- Terminal task filtering before expansion

### Interface Scope
- `ace-assign create --task` flag (new)
- `ace-assign create --preset` flag (new)
- `ace-assign create --yaml` flag (replaces positional CONFIG)

## Deliverables

### Behavioral Specifications
- Option-driven `create` command with preset integration
- Terminal task filtering on `--task` mode

### Validation Artifacts
- Extended `create_command_test.rb` for new flags and modes
- Integration test for preset-based creation

## Out of Scope

- Changes to `PresetLoader`, `PresetExpander`, or `PresetJobBuilder` (all from t.2p4.1)
- Changes to `ace-overseer` (it will adopt `create --task` separately)
- Multi-task `--taskrefs` support (single task only for now; multi-task uses `--yaml`)

## References

- Plan: `/home/mc/.claude/plans/twinkly-knitting-sutton.md`
- Parent task: t.2p4 (Dynamic Task Subtree Insertion for ace-assign)
- Sibling (completed): t.2p4.0 (YAML Batch Insertion), t.2p4.1 (Preset-Aware Add)
- Existing: `ace-assign/lib/ace/assign/cli/commands/create.rb`
