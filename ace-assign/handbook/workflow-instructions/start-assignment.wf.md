---
name: start-assignment
allowed-tools: Bash, Read, Write, AskUserQuestion
description: Create and start an assignment from preset or instructions (prepare + create)
argument-hint: "[preset-name] [--taskref value] [--taskrefs values]"
doc-type: workflow
purpose: Combined workflow that prepares and creates an assignment in one step

update:
  frequency: on-change
  last-updated: '2026-02-11'
---

# Start Assignment Workflow

## Purpose

Combined workflow that runs prepare-assignment followed by create-assignment. This is the fastest way to start working on a task with ace-assign.

## Input Formats

The workflow accepts the same inputs as prepare-assignment:

### 1. Preset Name Only

```
/ace:assign-start work-on-task-with-pr --taskref 123
```

### 2. Preset with Multiple Tasks

```
/ace:assign-start work-on-tasks --taskrefs 148,149,150
```

### 3. Informal Instructions

```
/ace:assign-start "implement task 148, create pr, review twice"
```

## Process

### 1. Prepare Assignment

Run the prepare workflow:

```bash
ace-bundle wfi://prepare-assignment
```

This creates a `job.yaml` file from the preset or instructions.

### 2. Create Assignment

Run the create workflow:

```bash
ace-bundle wfi://create-assignment
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
Created: .cache/ace-assign/8or5kx/

Phases: 10 total
  010: onboard [in_progress]
  020: work-on-task [pending]
  ...

First phase: onboard

Start driving with: /ace:assign-drive
```

## Next Steps

After starting the assignment:

```bash
# Check status
ace-assign status

# Drive execution through the workflow
/ace:assign-drive
```

## Success Criteria

- job.yaml successfully created from preset or instructions
- Assignment directory created with proper structure
- Phase files created with pending status
- Clear summary provided to user
- User knows how to proceed with /ace:assign-drive
