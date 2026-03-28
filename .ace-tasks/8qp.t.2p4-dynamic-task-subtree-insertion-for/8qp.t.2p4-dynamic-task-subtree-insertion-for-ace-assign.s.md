---
id: 8qp.t.2p4
status: done
priority: medium
created_at: "2026-03-26 01:47:55"
estimate: TBD
dependencies: []
tags: [ace-assign, cli, skill]
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/cli/commands/add.rb, ace-assign/lib/ace/assign/organisms/assignment_executor.rb, ace-assign/lib/ace/assign/molecules/step_writer.rb, ace-assign/lib/ace/assign/atoms/preset_expander.rb, ace-assign/lib/ace/assign/atoms/step_numbering.rb, ace-assign/.ace-defaults/assign/presets/work-on-task.yml, ace-assign/handbook/skills/as-assign-add-task/SKILL.md, ace-assign/handbook/workflow-instructions/assign/run-in-batches.wf.md]
  commands: [ace-bundle project]
needs_review: false
worktree:
  branch: 2p4-dynamic-task-subtree-insertion-for-ace-assign
  path: ../ace-t.2p4
  created_at: "2026-03-26 01:56:48"
  updated_at: "2026-03-26 01:56:48"
  target_branch: main
---

# Dynamic Task Subtree Insertion for ace-assign

## Objective

Enable flexible assignment composition and modification by allowing users to inject new task subtrees and preset-defined steps into active assignments, and by letting assignment creation start directly from task refs through the same preset-driven path used by `ace-overseer`. This improves adaptability when new requirements emerge, a review needs retrying, a task needs to be added to a running batch, or a fresh assignment should be created from tasks without a separate prepare step.

## Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|---------------|------------|--------|
| `--yaml` batch YAML insertion | t.2p4.0 | -- | KEPT |
| `add_batch()` executor method | t.2p4.0 | -- | KEPT |
| Canonical subtree materialization in batch insertion | t.2p4.0 | -- | KEPT |
| `as-assign-add-task` skill/workflow | t.2p4.0 | -- | KEPT |
| `--step` preset step insertion | t.2p4.1 | -- | PLANNED |
| `--task` preset child-template insertion | t.2p4.1 | -- | PLANNED |
| `--preset` source preset flag | t.2p4.1 | -- | PLANNED |
| `PresetLoader` atom | t.2p4.1 | -- | PLANNED |
| `PresetStepResolver` atom | t.2p4.1 | -- | PLANNED |
| `PresetInferrer` molecule | t.2p4.1 | -- | PLANNED |
| shared task-driven assignment creation | t.2p4.2 | -- | IN PROGRESS |
| `create --task` preset-based creation | t.2p4.2 | -- | IN PROGRESS |
| `create --yaml` (replaces positional CONFIG) | t.2p4.2 | -- | IN PROGRESS |
| multi-task `create --task` input | t.2p4.2 | -- | IN PROGRESS |
| `ace-overseer` adoption of shared create path | t.2p4.2 | -- | IN PROGRESS |
| task child-template inherits full `task/work` sub-step sequence | t.2p4.2 | -- | IN PROGRESS |
| `PresetJobBuilder` molecule | t.2p4.1 | -- | PLANNED |

## Subtasks

- **t.2p4.0** (done): YAML Batch Insertion and Add-Task Skill -- `--yaml`, `add_batch()`, canonical subtree insertion, skill/workflow
- **t.2p4.1** (done): Preset-Aware Step and Task Insertion -- `--step`, `--task`, `--preset`, option-only `add` contract
- **t.2p4.2** (in_progress): Unified Preset Input for Create Command -- flags-only `create`, multi-task `--task`, shared `ace-overseer` path, full task subtree sub-steps

## Behavioral Specification

### User Experience

- **Input**: One explicit mode for `ace-assign add` (`--yaml <file>`, `--step <name[,name...]>`, or `--task <ref>`) and one explicit mode for `ace-assign create` (`--yaml <file>` or `--task <ref[,ref...]>`)
- **Process**: The CLI resolves the requested input into concrete step definitions or a hidden job spec, feeds insertion requests through the existing batch insertion engine, and feeds creation requests through the shared preset-driven task creation path also used by `ace-overseer`
- **Output**: For `add`, a summary of inserted steps with assigned numbers and preserved queue state. For `create`, a new assignment with the expanded step tree and first-step instructions.

### Expected Behavior

This task lands in three phases:

**1. Done in `t.2p4.0`: batch insertion engine**

`ace-assign add --yaml steps.yml` inserts multiple step definitions from a YAML file containing a top-level `steps:` array. The executor now owns `add_batch()` and canonical subtree materialization, so workflow/skill-backed roots and `sub_steps` trees are expanded through the same path as preset-backed insertion.

Each inserted step receives `added_by: "batch_from:<filename>"` for audit trail.

**2. Done in `t.2p4.1`: preset-aware insertion UX**

`ace-assign add` becomes an option-driven command with exactly one required mode:

1. `--yaml <file>` for direct YAML batch insertion
2. `--step <name[,name...]>` for preset step insertion
3. `--task <ref>` for preset child-template insertion

`--preset <name>` is optional for `--step` and `--task`. When omitted, the command infers the preset from the active assignment's archived `source_config` job YAML and falls back to `work-on-task`.

`--step` resolves preset steps by exact name first, then by base name after removing a trailing `-N` suffix from preset step names. Inserted root steps are renamed to the next available iteration found in the current queue.

`--task` resolves `expansion.child-template`, substitutes the task reference, auto-detects a batch parent when `--after` is omitted, and implies child insertion for the auto-detected path.

The child-template now declares the full `task/work` subtree so inserted task roots expand with:
- `onboard-base`
- `task-load`
- `plan-task`
- `work-on-task`
- `pre-commit-review`
- `verify-test`
- `release-minor`
- `create-retro`

`as-assign-add-task` remains supported, but its CLI invocation and examples must migrate to `--yaml`.

**3. In progress in `t.2p4.2`: unified create UX**

`ace-assign create` becomes an option-driven command with exactly one required mode:

1. `--yaml <file>` for direct YAML-based creation
2. `--task <ref[,ref...]>` / repeated `--task` for preset-based creation from one or more task refs

`--preset <name>` is optional for `--task` and defaults to `work-on-task`.

Task-driven creation rejects draft tasks, skips terminal tasks in mixed sets, errors when all requested refs are terminal, and rejects multi-task input for presets that do not support `taskrefs`.

`ace-overseer work-on` keeps its CLI surface but adopts the same shared task-driven assignment creation path, so direct `ace-assign create --task` and overseer-driven creation share preset loading, parameter shaping, hidden job generation, and task filtering semantics.

### Interface Contract

#### CLI Addition

```bash
# Exactly one insertion mode is required
ace-assign add --yaml steps.yml [--after NNN] [--child] [--assignment ID]
ace-assign add --step review-fit[,review-shine] [--preset work-on-task] [--after NNN] [--assignment ID]
ace-assign add --task t.456 [--preset work-on-task] [--after NNN] [--child] [--assignment ID]
```

#### YAML File Format

```yaml
# Flat batch: multiple independent steps
steps:
  - name: fix-api-tests
    instructions: "Fix the failing API integration tests."
  - name: update-docs
    instructions: "Update API documentation."

# Parent with sub_steps expansion
steps:
  - name: work-on-t.xyz
    context: fork
    workflow: wfi://task/work
    instructions: |
      Implement task t.xyz following project conventions.
    sub_steps:
      - onboard
      - plan-task
      - work-on-task
      - pre-commit-review
      - verify-test
```

#### CLI Output

```text
Added 4 step(s) from add-task-xyz.yml
  010.03: work-on-t.xyz [pending]
  010.03.01: onboard [pending]
  010.03.02: plan-task [pending]
  010.03.03: work-on-task [pending]
```

#### Skill Invocation

```text
/as-assign-add-task t.xyz
/as-assign-add-task t.xyz --parent 010
/as-assign-add-task t.xyz --assignment 8qm5rt
```

#### Error Handling

| Condition | Response |
|-----------|----------|
| No insertion mode provided | Error: "Exactly one of --yaml, --step, or --task is required" |
| More than one insertion mode provided | Error: "--yaml, --step, and --task are mutually exclusive" |
| File not found | Error: "File not found: <path>" |
| Empty `steps:` array | Error: "No steps defined in <path>" |
| `--preset` without `--step` or `--task` | Error: "--preset requires --step or --task" |
| Step name not found in preset | Error with available step names from the preset |
| Preset has no `expansion.child-template` | Error: "Preset '<name>' has no expansion.child-template" |
| `--task` auto-detect finds no batch parent | Error: "No batch parent found. Pass --after <step> to specify." |
| `--child` without `--after` | Error: "--child requires --after" (existing) |
| Child would exceed max depth | Error: depth exceeded (existing) |
| No active assignment | Error: "No active assignment" (existing) |

#### Consumer Packages
- `ace-assign` (internal: CLI command, executor)
- `ace-overseer` (shared create-path consumer in `work-on`)
- `ace-handbook-integration-claude` (skill projection for `as-assign-add-task`)
- other projected skill packages for `as-assign-add-task`

#### Operating Modes
- `--quiet`: Suppress per-step output, show only summary count
- `--verbose`/`--debug`: Show step resolution details, insertion decisions, and renumbering events
- Existing target-selection flags continue to apply to all insertion modes

### Success Criteria

- `ace-assign add --yaml` preserves the batch insertion behavior shipped in `t.2p4.0`
- `ace-assign add --step review-fit` resolves the preset definition and inserts it with the next queue iteration name
- `ace-assign add --step review-valid,review-fit,review-shine` inserts an ordered sequence of preset step trees
- `ace-assign add --task t.456` resolves the preset child-template, auto-detects the batch parent when possible, and inserts the full `task/work` subtree as a child
- `ace-assign create --task t.xyz` creates a full assignment directly from task refs without a separate prepare step
- `ace-assign create --task t.100,t.101 --preset work-on-task` creates one assignment from the ordered active task set
- `ace-overseer work-on` uses the shared task-driven creation path rather than its own preset expansion implementation
- Each inserted step has `added_by: "batch_from:<filename>"` metadata when materialized through batch insertion
- Existing step states (done, in_progress, pending) are not modified by insertion other than the documented parent rebalance for active child injection
- `as-assign-add-task` remains coherent with the CLI contract and examples after the `--yaml` rename

### Validation Questions

- [Resolved] Canonical file-based mode is `--yaml`; `--from` is removed
- [Resolved] `ace-assign add` is option-only; exactly one of `--yaml`, `--step`, or `--task` is required
- [Resolved] Batch insertion implementation is the existing `add_batch()` executor path with canonical subtree materialization
- [Resolved] Preset inference comes from archived `source_config` job YAML `session.name`, with fallback to `work-on-task`
- [Resolved] Preset inference does not consult `.ace/assign/config.yml`
- [Resolved] `create` is also option-only; positional `CONFIG` is removed
- [Resolved] multi-task `--task` creation is part of this track so `ace-overseer` can converge on the same path

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice**: Single standalone task with one completed subtask and one pending subtask (medium)
- **Outcome**: `ace-assign add --yaml`, `--step`, and `--task` work end-to-end with a single coherent insertion model
- **Advisory size**: Medium — `.0` landed the engine, `.1` completes the public CLI and preset resolution layer
- **Context dependencies**: `ace-assign` package internals (executor, step writer, step numbering, preset loading)

## Verification Plan

### Unit/Component Validation

- `PresetLoader.load("work-on-task")` returns a preset hash with `steps` and `expansion`
- `PresetLoader.load("missing")` raises a CLI error
- `PresetStepResolver.find_step(preset, "review-fit-1")` matches exactly
- `PresetStepResolver.find_step(preset, "review-fit")` matches the base-name form
- `PresetStepResolver.find_steps(preset, ["review-valid", "review-fit"])` preserves caller order
- `PresetStepResolver.next_iteration_name("review-fit", queue_names)` returns the next suffix
- `PresetInferrer.infer_from_assignment(assignment)` extracts the preset from archived `source_config`
- CLI rejects missing insertion mode
- CLI rejects multiple insertion modes
- CLI rejects `--preset` without `--step` or `--task`
- CLI rejects non-existent `--yaml` file path

### Integration/E2E Validation

- Create assignment from `work-on-task`, run `ace-assign add --step review-fit`, verify the next `review-fit-N` tree appears in status
- Run `ace-assign add --step review-valid,review-fit,review-shine --after 100`, verify the three step trees are inserted in order
- Create assignment with `batch-tasks`, run `ace-assign add --task t.999`, verify the task subtree appears as a child under the detected parent
- Run `ace-assign add --yaml steps.yml --after 010 --child`, verify the `.0` batch path still works

### Failure/Invalid Path Validation

- YAML file with empty `steps:` array produces a clear error
- YAML file with invalid structure (no `steps:` key) produces a clear error
- `ace-assign add --step unknown-step` produces an error with available preset step names
- `ace-assign add --task t.123` with no detectable batch parent produces a clear error
- Insertion that would exceed max nesting depth (3 levels) produces a clear error

### Verification Commands

- `ace-test ace-assign` — all existing + new tests pass
- `ace-assign add --yaml test.yml --after 010 --child` — manual E2E verification
- `ace-assign status` — verify step hierarchy after insertion

## Scope of Work

### User Experience Scope
- CLI users can batch-insert concrete steps from YAML
- CLI users can insert preset-backed step trees by name with auto-iteration numbering
- CLI users can insert preset-backed task subtrees with batch-parent auto-detection
- CLI users can create assignments directly from YAML or task refs through explicit modes
- `ace-overseer` users get the same simplified task-driven creation behavior without a CLI change
- Skill users can continue adding a work-on-task child to a running batch via `/as-assign-add-task`

### System Behavior Scope
- `AssignmentExecutor#add_batch()` and canonical subtree materialization from `.0` are reused
- `PresetLoader` atom — preset file resolution and loading
- `PresetStepResolver` atom — step matching and next-iteration naming
- `PresetInferrer` molecule — preset inference from archived assignment metadata
- shared task-driven assignment creation service
- CLI `add.rb` — option-only insertion modes and preset routing
- CLI `create.rb` — option-only creation modes and preset routing
- `ace-overseer` assignment launch path delegates to the shared creation service

### Interface Scope
- `ace-assign add --yaml` CLI flag
- `ace-assign add --step` CLI flag
- `ace-assign add --task` CLI flag
- `ace-assign add --preset` CLI flag
- `ace-assign create --yaml` CLI flag
- `ace-assign create --task` CLI flag
- `ace-assign create --preset` CLI flag
- `as-assign-add-task` skill + `wfi://assign/add-task` workflow examples updated for `--yaml`

## Deliverables

### Behavioral Specifications
- Extended `add` command with option-only insertion modes
- YAML file format for concrete step definitions
- Preset-backed step resolution, iteration naming, and task child-template insertion
- Shared task-driven assignment creation across `ace-assign` and `ace-overseer`
- Updated `as-assign-add-task` contract/examples for `--yaml`

### Validation Artifacts
- Unit tests for preset loading, preset step resolution, and preset inference
- CLI tests for `--yaml`, `--step`, `--task`, and `--preset`
- Integration tests for ordered preset insertion and task subtree auto-detection
- create-path tests for single-task and multi-task taskref expansion plus overseer delegation

## Out of Scope

- Performance optimization for large batch insertions
- Changes to preset file format or `PresetExpander` expansion semantics
- New presets or preset composition
- GUI or non-CLI interfaces

## References

- Source idea: `8qmfmt` — Dynamic Task Subtree Insertion for ace-assign
- Existing patterns: `add_batch()` implementation, canonical subtree insertion, `PresetExpander`, `work-on-task.yml` preset
