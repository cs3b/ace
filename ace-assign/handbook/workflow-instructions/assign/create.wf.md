---
name: assign/create
allowed-tools: Bash, Read, Write, AskUserQuestion
description: Create a new assignment from a hidden rendered spec
doc-type: workflow
purpose: workflow instruction for rendering one smart-create path into hidden spec and calling deterministic ace-assign create
argument-hint: "[work-on-task --taskref <id>]"

update:
  frequency: on-change
  last-updated: '2026-03-07'
---

# Create Assignment Workflow

## Purpose

Create an assignment through one proven smart-create tracer path while preserving deterministic runtime behavior:

1. Render a normalized hidden spec under `.ace-local/assign/jobs/`
2. Call `ace-assign create <hidden-spec-path>`
3. Surface standard create output plus hidden-spec provenance

This workflow intentionally validates one path end-to-end before broadening the interface.

## Supported Tracer Path

```bash
/as-assign-create work-on-task --taskref 123
```

Only this path is required for this slice. Equivalent freeform phrase parsing is deferred.

## Runtime Boundary (Hard Rule)

`ace-assign create FILE` remains the deterministic runtime boundary.

- This workflow may parse the user request and render YAML.
- The CLI create command must still ingest a concrete file path.
- Do not add natural-language parsing inside `ace-assign create`.

## Process

### 1. Parse Input

Validate the tracer input shape:
- Preset: `work-on-task`
- Required parameter: `--taskref <id>`

If input does not match this path, fail with a concrete unsupported-input message.

### 2. Render Hidden Spec

Create hidden spec directory if missing:

```bash
mkdir -p .ace-local/assign/jobs
```

Render normalized YAML to a timestamped file:

```bash
.ace-local/assign/jobs/<timestamp>-work-on-task-<taskref>.yml
```

Minimal required structure:

```yaml
session:
  name: work-on-task-123
  description: Work on task 123.

steps:
  - name: work-on-task
    skill: as-task-work
    taskref: "123"
    instructions:
      - "Work on task 123."
      - "Implement the required changes following project conventions."
```

Rules:
- Each invocation writes a new file (no in-place mutation of previous hidden specs).
- The hidden spec is internal provenance; users are not required to edit it.

### 3. Create Assignment Deterministically

Invoke CLI boundary with rendered spec:

```bash
ace-assign create .ace-local/assign/jobs/<timestamp>-work-on-task-<taskref>.yml
```

### 4. Report Result

Display assignment summary plus hidden-spec provenance line.

Expected output shape:

```text
Assignment: work-on-task-123 (<id>)
Created: .ace-local/assign/<id>/
Created from hidden spec: .ace-local/assign/jobs/<timestamp>-work-on-task-123.yml

Phase 010: ...
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Unsupported tracer input | Return concrete validation error; no assignment created |
| Hidden-spec render failure | Return concrete render error; no assignment created |
| `ace-assign create` rejection | Surface CLI error unchanged |

## Edge Cases

- Re-running the same command creates a new hidden spec file.
- Hidden spec path remains stable in assignment metadata after creation.
- Quiet mode for `ace-assign create` suppresses non-essential output (including provenance line).

## Success Criteria

- Hidden spec is written under `.ace-local/assign/jobs/`
- `ace-assign create FILE` receives the rendered spec path
- Assignment metadata preserves hidden spec path provenance
- User sees assignment summary and hidden-spec provenance in normal output

## Verification

```bash
# Validate hidden spec references exist in implementation
rg -n "\.ace-local/assign/jobs|Created from hidden spec" ace-assign

# Validate package behavior
ace-test ace-assign
```

## Next Steps

After assignment creation:

```bash
/as-assign-drive <assignment-id>
```
