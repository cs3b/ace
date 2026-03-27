---
id: 8qp.t.2p4.1
status: done
priority: medium
created_at: "2026-03-27 10:44:16"
estimate: medium
dependencies: [8qp.t.2p4.0]
tags: [ace-assign, cli]
parent: 8qp.t.2p4
needs_review: false
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/cli/commands/add.rb, ace-assign/lib/ace/assign/organisms/assignment_executor.rb, ace-assign/lib/ace/assign/atoms/preset_expander.rb, ace-assign/lib/ace/assign/models/assignment.rb, ace-assign/.ace-defaults/assign/presets/work-on-task.yml, ace-assign/test/commands/add_command_test.rb, ace-assign/test/organisms/assignment_executor_test.rb]
  commands: [ace-bundle project]
---

# Preset-Aware Step and Task Insertion

## Objective

Make it easy to pull step definitions and task child-templates from a preset into a running assignment. This removes manual YAML authoring for common retry and batch-expansion flows and finishes the dynamic insertion feature started in `t.2p4.0`.

## Behavioral Specification

### User Experience

- **Input**: Exactly one insertion mode for `ace-assign add`: `--yaml <file>`, `--step <name[,name...]>`, or `--task <ref>`, plus optional shared flags such as `--preset`, `--after`, and `--assignment`
- **Process**: The CLI resolves the requested mode into concrete step definitions, reuses the existing batch insertion path, and lets canonical subtree materialization expand workflow/skill-backed trees
- **Output**: Summary of inserted steps with assigned numbers, parent relationships, and auto-iteration labels when preset-backed roots are renamed

### Expected Behavior

Three mutually exclusive input modes for `ace-assign add`:

1. `ace-assign add --yaml <file>` — concrete steps from YAML
2. `ace-assign add --step <name>[,<name>,...]` — pull named step(s) from a preset
3. `ace-assign add --task <ref>` — pull task child-template from a preset expansion section

Exactly one of these options is required. The positional `name` mode is removed.

`--preset <name>` is only valid with `--step` or `--task`. When omitted, the CLI infers the preset from the active assignment's archived `source_config` job YAML `session.name`, then falls back to `work-on-task`.

**Step mode (`--step`):**
- Resolves step name(s) against the preset's `steps:` array
- Matches by exact name first, then by base-name (stripping trailing `-\d+` suffix)
- Auto-numbers iteration: if `review-fit-1` exists in the queue, the new step becomes `review-fit-2`
- Preserves the full step definition: `context`, `sub_steps`, `workflow`, `skill`, `instructions`
- When inserting a sequence (`review-valid,review-fit,review-shine`), steps are inserted in order

**Task mode (`--task`):**
- Extracts `expansion.child-template` from the preset
- Substitutes `{{item}}` with the task reference
- Auto-detects batch parent when `--after` is omitted by first looking for `batch-tasks`, then for a top-level step with `work-on-*` children
- Implies `--child` when auto-detecting batch parent

**YAML mode (`--yaml`):**
- Preserves the batch insertion behavior already shipped in `t.2p4.0`
- Uses concrete step definitions only; it does not resolve preset references inside the file
- Continues to use `add_batch()` and canonical subtree materialization for declared trees

### Interface Contract

#### CLI

```bash
# Add a step tree from preset
ace-assign add --step review-fit --preset work-on-task --after 100 --assignment abc123

# Add a sequence of step trees
ace-assign add --step review-valid,review-fit,review-shine --preset work-on-task --after 100 --assignment abc123

# Add a task subtree from preset expansion
ace-assign add --task t.456 --preset work-on-task --after 010 --child --assignment abc123

# YAML batch insertion remains available under the canonical flag
ace-assign add --yaml steps.yml --after 010 --child
```

#### Expected Output

```text
# --step mode
Added review-fit-2 (3 step(s)) after 100
  101: review-fit-2 [pending] (fork)
  101.01: review-pr [pending]
  101.02: apply-feedback [pending]
  101.03: release [pending]

# --task mode
Added task t.456 under 010
  010.03: work-on-t.456 [pending] (fork)
```

#### Error Handling

| Condition | Response |
|-----------|----------|
| No insertion mode provided | Error: "Exactly one of --yaml, --step, or --task is required" |
| More than one insertion mode provided | Error: "--yaml, --step, and --task are mutually exclusive" |
| `--preset` without `--step` or `--task` | Error: "--preset requires --step or --task" |
| Step name not found in preset | Error: "Step 'foo' not found in preset 'work-on-task'. Available: onboard, verify-test-suite, review-valid, review-fit, ..." |
| Preset has no expansion section (`--task`) | Error: "Preset 'X' has no expansion.child-template" |
| No batch parent found (`--task` without `--after`) | Error: "No batch parent found. Pass --after <step> to specify." |
| Preset file not found | Error: "Preset 'foo' not found" |
| `--yaml` file not found | Error: "File not found: <path>" |
| `--yaml` file has empty or missing `steps:` | Error: "No steps defined in <path>" |

### Success Criteria

- `ace-assign add --step review-fit` resolves the step definition from the preset and inserts it with auto-numbered iteration
- `ace-assign add --step review-valid,review-fit,review-shine` inserts three step trees in sequence
- `ace-assign add --task t.456` resolves the expansion child-template, detects the batch parent, and inserts the task subtree as a child
- `ace-assign add --yaml` preserves the batch insertion behavior already shipped in `t.2p4.0`
- Step name matching works with both exact names (`review-fit-1`) and base names (`review-fit`)
- Auto-iteration numbering correctly increments (`review-fit-1` exists -> `review-fit-2`)
- Preset is correctly inferred from assignment metadata when `--preset` is omitted
- The command no longer supports positional `name` insertion or the legacy `--from` spelling

### Validation Questions

- [Resolved] Three-way mutual exclusivity: `--yaml`, `--step`, `--task`
- [Resolved] The command is option-only; positional `name` is removed
- [Resolved] `--from` is removed; `--yaml` is the only file-based mode
- [Resolved] Step matching: exact first, then base-name (strip `-\d+`)
- [Resolved] `--task` auto-detects batch parent, implies `--child`
- [Resolved] Preset inference does not check `.ace/assign/config.yml`

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice**: Single subtask under the t.2p4 orchestrator (medium)
- **Outcome**: `--yaml`, `--step`, `--task`, and `--preset` work end-to-end as a single coherent contract on the `add` command
- **Advisory size**: Medium — CLI contract rewrite plus preset resolution on top of the already landed `add_batch`
- **Context dependencies**: `ace-assign` package (add command, executor, preset expander, assignment model)

## Verification Plan

### Unit/Component Validation

- `PresetLoader.load("work-on-task")` returns a Hash with `steps` and `expansion` keys
- `PresetLoader.load("nonexistent")` raises a CLI error
- `PresetStepResolver.find_step(preset, "review-fit")` matches `review-fit-1` via base-name
- `PresetStepResolver.find_step(preset, "review-fit-1")` matches exactly
- `PresetStepResolver.find_step(preset, "unknown")` raises an error with available step names
- `PresetStepResolver.find_steps(preset, ["review-valid", "review-fit"])` returns an ordered array
- `PresetStepResolver.next_iteration_name("review-fit", ["review-fit-1"])` returns `"review-fit-2"`
- `PresetStepResolver.next_iteration_name("review-fit", [])` returns `"review-fit-1"`
- `PresetInferrer.infer_from_assignment(assignment)` extracts preset name from `source_config`
- CLI rejects invocations with no insertion mode
- CLI rejects invocations with multiple insertion modes
- CLI rejects `--preset` without `--step` or `--task`

### Integration/E2E Validation

- Create an assignment from `work-on-task`, run `ace-assign add --step review-fit`, verify new `review-fit-2` with children appears in status
- Create an assignment, run `ace-assign add --step review-valid,review-fit,review-shine --after 100`, verify three step trees are inserted in sequence
- Create an assignment with `batch-tasks`, run `ace-assign add --task t.999`, verify the task subtree appears as a child of `batch-tasks`
- Verify `ace-assign add --yaml file.yml` still works after the contract rewrite

### Failure/Invalid Path Validation

- `ace-assign add --step unknown-step` produces an error with suggestions
- `ace-assign add --task t.123` with no batch parent produces a clear error
- `ace-assign add --step review-fit --task t.123` produces a mutual exclusivity error
- `ace-assign add` without any insertion mode produces the required-mode error
- `ace-assign add --preset work-on-task` without `--step` or `--task` produces an error

### Verification Commands

- `ace-test ace-assign` — all existing + new tests pass
- `ace-test-suite` — no cross-package regressions

## Scope of Work

### User Experience Scope
- CLI users can add preset steps by name with auto-iteration numbering
- CLI users can add task subtrees with batch parent auto-detection
- The file-backed insertion mode is `--yaml`

### System Behavior Scope
- `PresetLoader` atom — preset file resolution and loading
- `PresetStepResolver` atom — step name matching and iteration numbering
- `PresetInferrer` molecule — preset inference from assignment metadata
- Updated `add` command — three explicit input modes and shared preset routing

### Interface Scope
- `ace-assign add --yaml` flag (canonical file mode)
- `ace-assign add --step` flag
- `ace-assign add --task` flag
- `ace-assign add --preset` flag

## Deliverables

### Behavioral Specifications
- Option-only `add` command with preset integration
- Step name resolution with base-name matching and auto-iteration
- Batch parent auto-detection for task insertion

### Validation Artifacts
- `PresetLoader` atom tests
- `PresetStepResolver` atom tests
- Extended `add` command tests for new flags
- Integration tests for step and task insertion

## Out of Scope

- Changes to preset file format or `PresetExpander` expansion logic
- New presets or preset composition
- GUI or non-CLI interfaces
- Assignment-model persistence of a dedicated preset field

## References

- Plan: `/home/mc/.claude/plans/twinkly-knitting-sutton.md`
- Parent task: t.2p4 (Dynamic Task Subtree Insertion for ace-assign)
- Sibling (completed): t.2p4.0 (YAML Batch Insertion and Add-Task Skill)
- Existing patterns: `ace-assign add --yaml`, `PresetExpander`, `work-on-task.yml` preset
