---
name: assign/start
allowed-tools: Bash, Read, Write, AskUserQuestion
description: Create and start an assignment from preset or instructions (prepare + create)
argument-hint: "[preset-name] [--taskref value] [--taskrefs values]"
doc-type: workflow
purpose: Combined workflow that prepares and creates an assignment in one step

update:
  frequency: on-change
  last-updated: '2026-02-13'
---

# Start Assignment Workflow

## Purpose

Combined workflow that composes (or prepares) and creates an assignment in one step. This is the fastest way to start working on a task with ace-assign.

## Path Selection

This workflow supports two paths for generating job.yaml:

### Compose Path (Default)

Uses the compose-assignment workflow for intelligent, catalog-driven phase selection. Best for:
- Natural language descriptions of what you need
- Custom combinations of phases
- Assignments that don't match existing presets exactly

Compose is intentionally catalog-only. It does not read external `assign:` frontmatter.

### Prepare Path (Legacy)

Uses the prepare-assignment workflow for mechanical preset expansion. Best for:
- Exact preset names with known parameters
- Backward compatibility with existing automation
- Deterministic metadata-driven expansion from runtime sources (skill/workflow `assign:`)

**Auto-detection**: If the first argument is an exact preset name (e.g., `work-on-task`), use the prepare path. Otherwise, use the compose path.

## Input Formats

### 1. Natural Description (→ Compose Path)

```
/ace-assign-start "implement task 148, create pr, review twice"
```

### 2. Recipe or Preset Name (→ Auto-detected)

```
/ace-assign-start work-on-task --taskref 123
/ace-assign-start implement-with-pr --taskref 123
```

### 3. Multiple Tasks

```
/ace-assign-start work-on-tasks --taskrefs 148,149,150
/ace-assign-start "work on tasks 148,149,150" --taskrefs 148,149,150
```

## Process

### 1. Generate Job Configuration

Determine the path based on input:

#### If input matches an existing preset name:

Run the prepare workflow (legacy path):

```bash
ace-bundle wfi://assign/prepare
```

#### Otherwise (default):

Run the compose workflow:

```bash
ace-bundle wfi://assign/compose
```

Both paths produce a `job.yaml` file.

### 2. Create Assignment

Run the create workflow:

```bash
ace-bundle wfi://assign/create
```

This creates the assignment directory structure and initializes the work queue.

### 3. Report Result

Show the user:
- Assignment ID and name
- Assignment directory path
- Total phase count
- First phase to work on

## Output

```
Assignment: work-on-task-123 (8or5kx)
Created: .ace-local/assign/8or5kx/

Phases: 10 total
  010: onboard [in_progress]
  020: work-on-task [pending]
  ...

First phase: onboard

Start driving with: /ace-assign-drive
```

## Next Steps

After starting the assignment:

```bash
# Check status
ace-assign status

# Drive execution through the workflow
/ace-assign-drive
```

## Success Criteria

- job.yaml successfully created from preset or instructions
- Assignment directory created with proper structure
- Phase files created with pending status
- Clear summary provided to user
- User knows how to proceed with /ace-assign-drive
