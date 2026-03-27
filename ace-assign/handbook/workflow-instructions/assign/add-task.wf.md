---
doc-type: workflow
title: Add Task To Assignment Workflow
purpose: Insert a work-on-task subtree into a running assignment batch parent using ace-assign add --yaml
ace-docs:
  last-updated: 2026-03-26
  last-checked: 2026-03-26
---

# Add Task To Assignment Workflow

## Purpose

Add one new task subtree to an existing assignment without editing step files manually.

This workflow:
1. Resolves the target assignment and parent step
2. Validates task reference exists
3. Renders a hidden YAML file under `.ace-local/assign/jobs/`
4. Calls `ace-assign add --yaml <file> --after <parent> --child`

## Supported Inputs

```bash
/as-assign-add-task t.xyz
/as-assign-add-task t.xyz --parent 010
/as-assign-add-task t.xyz --assignment abc123
/as-assign-add-task t.xyz --assignment abc123 --parent 010
```

## Process

### 1. Parse Input

Required:
- task reference (first positional argument)

Optional:
- `--assignment <id>`: explicit assignment target
- `--parent <step-number>`: explicit parent step for insertion

If task reference is missing, fail with usage guidance.

### 2. Resolve Assignment

- If `--assignment` is provided, use it for all assignment commands.
- Otherwise use active assignment context.

Run status to capture current queue state:

```bash
ace-assign status [--assignment <id>] --format json
```

### 3. Resolve Parent Step

If `--parent` is provided:
- Use it directly
- Ensure it exists in assignment status output

If `--parent` is not provided:
1. Prefer a top-level step named `batch-tasks`
2. Otherwise, choose a top-level step that has direct children where at least one child name starts with `work-on-`
3. If no match exists, fail and instruct user to pass `--parent`

### 4. Validate Task Reference

Confirm task exists and is readable:

```bash
ace-task show <taskref>
```

If task lookup fails, stop and surface the CLI error.

### 5. Render Hidden Batch Spec

Create the hidden jobs directory if missing:

```bash
mkdir -p .ace-local/assign/jobs
```

Write a temporary YAML file:

```bash
.ace-local/assign/jobs/<timestamp>-add-task-<taskref>.yml
```

Template:

```yaml
steps:
  - name: work-on-<taskref>
    context: fork
    workflow: wfi://task/work
    instructions: |
      Implement task <taskref> following project conventions.
      When complete, mark the task as done.
```

Notes:
- Do not hardcode `sub_steps` here.
- `ace-assign add --yaml` resolves canonical child steps from `wfi://task/work` assign metadata at insertion time.
- This keeps the inserted subtree aligned with workflow contract updates.

### 6. Insert Subtree

Run batch insertion:

```bash
ace-assign add --yaml .ace-local/assign/jobs/<timestamp>-add-task-<taskref>.yml --after <parent> --child [--assignment <id>]
```

### 7. Report Result

Report:
- Assignment ID
- Parent step used
- Hidden YAML path
- Inserted step numbers from CLI output

## Error Handling

| Scenario | Action |
|----------|--------|
| Missing taskref | Fail with usage and example invocation |
| No target assignment | Surface `ace-assign status` error |
| Parent not found | Fail with "step not found" and suggest `--parent` |
| Parent auto-detection failed | Fail with actionable message to pass `--parent` |
| Task not found | Surface `ace-task show` error unchanged |
| YAML render/write failure | Fail with concrete filesystem error |
| `ace-assign add --yaml` fails | Surface CLI error unchanged |

## Success Criteria

- Workflow inserts a new work-on-task subtree under the selected parent in one command
- Hidden YAML artifact is written under `.ace-local/assign/jobs/`
- Parent selection is deterministic with clear fallback to explicit `--parent`
- Output includes assignment, parent, and inserted step confirmation

## Verification

```bash
ace-bundle wfi://assign/add-task
```
