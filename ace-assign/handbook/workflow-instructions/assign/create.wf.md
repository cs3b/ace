---
name: assign/create
allowed-tools: Bash, Read, Write, AskUserQuestion
description: Create a new assignment workflow from job.yaml
argument-hint: "[path/to/job.yaml]"
doc-type: workflow
purpose: workflow instruction for creating ace-assign assignments

update:
  frequency: on-change
  last-updated: '2026-01-28'
---

# Create Assignment Workflow

## Purpose

Create a new ace-assign workflow from a job.yaml configuration file. This initializes the work queue and sets up the assignment directory structure.

## Prerequisites

- A valid `job.yaml` file exists with `session:` and `steps:` sections
- `ace-assign` CLI tool is installed and available

## Process

### 1. Locate job.yaml

Use the path provided as argument. If no path given, look for `job.yaml` in the current task directory.

### 2. Validate Configuration

Read the job.yaml file and verify it has the required structure:

```yaml
session:
  name: my-workflow
  description: Optional description

steps:
  - name: init
    instructions: |
      Set up the project structure.
      Report when done: ace-assign finish --report init.md
```

Required elements:
- `session.name` is set
- `steps` array exists with at least one phase
- Each phase has `name` and `instructions`
- No unresolved `{{placeholder}}` tokens remain

### 3. Create Assignment

Run the create command:

```bash
ace-assign create <path-to-job.yaml>
```

This creates the assignment directory at `.cache/ace-assign/<session-id>/` with:

```
.cache/ace-assign/<session-id>/
├── assignment.yaml               # Assignment metadata
├── phases/                       # Phase files (.ph.md extension)
│   ├── 010-init.ph.md           # pending
│   ├── 020-implement.ph.md      # pending
│   └── 030-test.ph.md           # pending
└── reports/                      # Report files (.r.md extension)
    └── (created as phases complete)
```

### 4. Report Result

Show the user:
- Assignment ID and name
- Assignment directory path
- Total phase count
- First phase to work on

Example output:
```
Assignment: work-on-task-123 (8or5kx)
Created: .cache/ace-assign/8or5kx/

Phases: 3 total
  010: onboard [in_progress]
  020: work-on-task [pending]
  030: finalize [pending]

First phase: onboard

Instructions:
Onboard yourself to the codebase.
Load context and understand the project structure.
```

## Job Configuration Format

### Full Structure

```yaml
session:
  name: my-workflow
  description: Optional description of the workflow

steps:
  - name: init
    instructions: |
      Set up the project structure.
      Report when done: ace-assign finish --report init.md

  - name: implement
    skill: ace-task-work      # Optional skill reference
    instructions: |
      Implement the feature.
      Report when done: ace-assign finish --report impl.md

  - name: test
    instructions: |
      Run tests and verify.
      Report when done: ace-assign finish --report test.md
```

### Skill-Aware Phases

Phases can include a `skill:` field that references a Claude Code skill to invoke:

```yaml
- name: work-on-task
  skill: ace-task-work
  instructions: |
    Work on task 123.
    Follow project conventions.
```

When executing this phase, invoke `/ace-task-work 123` then follow the skill workflow.

### Common Skill References

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `ace-onboard` | `/ace-onboard` | Load project context |
| `ace-task-work` | `/ace-task-work <taskref>` | Implement task changes |
| `ace-github-pr-create` | `/ace-github-pr-create` | Create pull request |
| `ace-review-pr` | `/ace-review-pr [pr#]` | Review code changes |
| `ace-git-commit` | `/ace-git-commit` | Generate commit message |
| `ace-github-pr-update` | `/ace-github-pr-update` | Update PR description |

### Parameter Passing

Extract parameters from instructions for skill invocation:

```yaml
- name: work-on-task
  skill: ace-task-work
  instructions: |
    Work on task 148.          # Extract "148" as taskref
    Implement required changes.
```

Agent Action: Run `/ace-task-work 148`

### Dynamic Parameter Updates

Some phases need parameters from previous phases (e.g., PR number):

```yaml
- name: create-pr
  skill: ace-github-pr-create
  instructions: |
    Create a pull request.
    Capture the PR number for subsequent review phases.
    Update the next phases with the PR number.
```

When completing this phase:
1. Note the PR number from the skill output
2. Mentally track for subsequent review phases
3. Report includes the PR number for reference

## Assignment Archiving

When `ace-assign create job.yaml` runs, the source job.yaml is automatically archived to `<task>/jobs/{session_id}-job.yml`. This keeps the task folder clean while preserving the job recipe for provenance.

**Note:** The archived file is for historical reference only—always use `ace-assign status` to query the current assignment state.

## Error Handling

| Scenario | Action |
|----------|--------|
| job.yaml not found | Check current directory or ask user for path |
| Invalid format | Show required structure and examples |
| Missing required fields | Report which fields are missing |
| Unresolved placeholders | Report which parameters need values |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - assignment created |
| 1 | General error |
| 3 | File not found (job.yaml) |
| 4 | Invalid configuration format |

## Success Criteria

- job.yaml successfully validated
- Assignment directory created with structure intact
- Assignment metadata written to assignment.yaml
- Phase files created with proper status (pending)
- Clear summary provided to user
- User knows how to proceed (drive assignment)

## Next Steps

After creating the assignment, use the drive workflow to work through phases:

```bash
# Check status
ace-assign status

# Drive execution through the workflow
/ace-assign-drive
```
