---
id: 8qp.t.2p4
status: pending
priority: medium
created_at: "2026-03-26 01:47:55"
estimate: TBD
dependencies: []
tags: [ace-assign, cli, skill]
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/cli/commands/add.rb, ace-assign/lib/ace/assign/organisms/assignment_executor.rb, ace-assign/lib/ace/assign/molecules/step_writer.rb, ace-assign/lib/ace/assign/atoms/preset_expander.rb, ace-assign/lib/ace/assign/atoms/step_numbering.rb, ace-assign/.ace-defaults/assign/presets/work-on-task.yml, ace-assign/handbook/skills/as-assign-run-in-batches/SKILL.md, ace-assign/handbook/workflow-instructions/assign/run-in-batches.wf.md]
  commands: [ace-bundle project]
needs_review: false
---

# Dynamic Task Subtree Insertion for ace-assign

## Objective

Enable flexible assignment modification by allowing users to inject new task subtrees into active assignments. This improves adaptability when new requirements emerge or when a task needs to be added to a running batch — avoiding manual editing of step files or recreating assignments from scratch.

## Behavioral Specification

### User Experience

- **Input**: A YAML file containing a `steps:` array (same format as job.yaml), or a skill invocation with a task reference
- **Process**: The CLI reads the file, expands any `sub_steps` directives into parent+children, computes insertion points, and creates all step files atomically. The skill orchestrates this by generating the YAML and invoking the CLI.
- **Output**: Summary of inserted steps with assigned numbers, parent relationships, and confirmation that existing steps were not disrupted

### Expected Behavior

Two complementary capabilities deliver this feature:

**1. CLI: `ace-assign add --from steps.yml`**

Extends the existing `add` command with a `--from` flag that accepts a YAML file containing multiple step definitions. When provided, the `name` positional argument is not required (mutually exclusive).

Steps in the file are inserted sequentially. When combined with `--after NNN --child`, all steps become children of the specified parent. When a step in the file contains a `sub_steps` array, it is expanded into a batch-parent + children (same pattern as `PresetExpander` uses at assignment creation time).

Each inserted step receives `added_by: "batch_from:<filename>"` for audit trail.

**2. Skill: `as-assign-add-task`**

A new skill that knows the recipe for adding a work-on-task child to a running assignment's batch parent. The skill:
1. Inspects `ace-assign status` to find the batch-parent step
2. Resolves the task reference via `ace-task show`
3. Generates a temporary YAML file with the work-on-task child-template steps
4. Calls `ace-assign add --from <file> --after <parent> --child`

### Interface Contract

#### CLI Addition

```bash
# Batch add from YAML file
ace-assign add --from steps.yml [--after NNN] [--child] [--assignment ID]

# Mutually exclusive with name argument
ace-assign add fix-bug -i "..."           # existing single-step (unchanged)
ace-assign add --from steps.yml --after 010 --child  # new batch mode
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

# String sub_steps become child steps using the string as name, with default instructions
# Hash sub_steps provide explicit name, instructions, and optional fields
steps:
  - name: batch-reviews
    instructions: "Review container"
    sub_steps:
      - name: review-frontend
        instructions: "Review frontend changes"
        context: fork
      - name: review-backend
        instructions: "Review backend changes"
        context: fork
```

#### CLI Output

```
Added 4 step(s) from add-task-xyz.yml
  010.03: work-on-t.xyz [pending]
  010.03.01: onboard [pending]
  010.03.02: plan-task [pending]
  010.03.03: work-on-task [pending]
```

#### Skill Invocation

```
/as-assign-add-task t.xyz
/as-assign-add-task t.xyz --parent 010
/as-assign-add-task t.xyz --assignment 8qm5rt
```

#### Error Handling

| Condition | Response |
|-----------|----------|
| `--from` and `name` both provided | Error: "--from and name argument are mutually exclusive" |
| Neither `--from` nor `name` provided | Error: "Either name argument or --from file.yml is required" |
| File not found | Error: "File not found: <path>" |
| Empty `steps:` array | Error: "No steps defined in <path>" |
| `--child` without `--after` | Error: "--child requires --after" (existing) |
| Child would exceed max depth | Error: depth exceeded (existing) |
| No active assignment | Error: "No active assignment" (existing) |

#### Consumer Packages
- `ace-assign` (internal: CLI command, executor)
- `ace-handbook-integration-claude` (skill projection for `as-assign-add-task`)

#### Operating Modes
- `--quiet`: Suppress per-step output, show only summary count
- `--verbose`/`--debug`: Show step creation details, renumbering events
- Existing flags pass through to each step insertion

### Success Criteria

- Multiple steps from a YAML file are inserted in a single `ace-assign add --from` invocation
- `sub_steps` arrays are expanded into batch-parent + children with correct hierarchical numbering
- Each inserted step has `added_by: "batch_from:<filename>"` metadata
- Extra frontmatter fields (`context`, `workflow`, `skill`, `batch_parent`) from the YAML are preserved in created step files
- Existing step states (done, in_progress, pending) are not modified by the insertion
- When inserting children under an active parent, parent is correctly rebalanced to pending
- The `as-assign-add-task` skill correctly generates and invokes the batch add for a given task reference

### Validation Questions

- [Resolved] Should `--from` be mutually exclusive with `name`? **Yes** — names come from the YAML file
- [Resolved] YAML format: `steps:` key at top level for consistency with job.yaml
- [Resolved] Implementation approach: `add_batch()` method on `AssignmentExecutor` that loops `add()` for each expanded step, reusing all existing validation/renumbering/rebalancing logic

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice**: Single standalone task (medium)
- **Outcome**: `ace-assign add --from` works end-to-end + `as-assign-add-task` skill created
- **Advisory size**: Medium — extends existing infrastructure, no new architectural concepts
- **Context dependencies**: `ace-assign` package internals (executor, step writer, step numbering)

## Verification Plan

### Unit/Component Validation

- `add_batch()` with flat YAML (3 steps) creates 3 sequential step files with correct numbers
- `add_batch()` with `sub_steps` YAML creates parent + N children with hierarchical numbering
- `add_batch()` with `--after 010 --child` creates all steps as children of 010
- `add_batch()` preserves `context: fork`, `workflow: wfi://task/work` in step frontmatter
- `add_batch()` sets `added_by: "batch_from:<filename>"` on all inserted steps
- CLI rejects `--from` + `name` together
- CLI rejects missing `--from` and missing `name`
- CLI rejects non-existent file path

### Integration/E2E Validation

- Create assignment with batch-parent, run `ace-assign add --from steps.yml --after 010 --child`, verify `ace-assign status` shows new children
- Insert subtree mid-assignment (some steps done, one in_progress), verify existing states unchanged
- Insert children under current in_progress parent, verify parent rebalanced to pending

### Failure/Invalid Path Validation

- YAML file with empty `steps:` array produces clear error
- YAML file with invalid structure (no `steps:` key) produces clear error
- Insertion that would exceed max nesting depth (3 levels) produces clear error

### Skill Validation
- `/as-assign-add-task t.xyz` with active batch-parent detects parent, generates YAML, inserts child steps
- `/as-assign-add-task t.xyz --parent 010` inserts under specified parent
- `/as-assign-add-task t.xyz` with no batch-parent produces clear error

### Verification Commands

- `ace-test ace-assign` — all existing + new tests pass
- `ace-assign add --from test.yml --after 010 --child` — manual E2E verification
- `ace-assign status` — verify step hierarchy after insertion

## Scope of Work

### User Experience Scope
- CLI users can batch-insert steps from a YAML file
- Skill users can add a work-on-task child to a running batch via `/as-assign-add-task`

### System Behavior Scope
- `AssignmentExecutor#add_batch()` — new method for batch insertion
- `expand_batch_sub_steps()` — sub_steps expansion helper
- CLI `add.rb` — `--from` flag routing

### Interface Scope
- `ace-assign add --from` CLI flag
- `as-assign-add-task` skill + `wfi://assign/add-task` workflow

## Deliverables

### Behavioral Specifications
- Extended `add` command with `--from` batch mode
- YAML file format for step definitions
- `as-assign-add-task` skill and workflow instruction

### Validation Artifacts
- Unit tests for `add_batch()` on AssignmentExecutor
- CLI tests for `--from` flag mutual exclusivity and routing
- Integration test for subtree insertion into active assignment

## Out of Scope

- Implementation details: file structures, code organization, technical architecture
- Performance optimization for large batch insertions
- Preset resolution within `--from` (the file contains concrete steps, not preset references)
- Changes to assignment creation flow or PresetExpander
- GUI or non-CLI interfaces

## References

- Source idea: `8qmfmt` — Dynamic Task Subtree Insertion for ace-assign
- Existing patterns: `ace-assign add` command, `PresetExpander`, `work-on-task.yml` preset
