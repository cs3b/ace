---
name: create-coworker-session
allowed-tools: Bash, Read, Write, AskUserQuestion
description: Create a new coworker workflow session from job.yaml
argument-hint: "[path/to/job.yaml]"
doc-type: workflow
purpose: workflow instruction for creating ace-coworker sessions

update:
  frequency: on-change
  last-updated: '2026-01-28'
---

# Create Coworker Session Workflow

## Purpose

Create a new ace-coworker workflow session from a job.yaml configuration file. This initializes the work queue and sets up the session directory structure.

## Prerequisites

- A valid `job.yaml` file exists with `session:` and `steps:` sections
- `ace-coworker` CLI tool is installed and available

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
      Report when done: ace-coworker report init.md
```

Required elements:
- `session.name` is set
- `steps` array exists with at least one step
- Each step has `name` and `instructions`
- No unresolved `{{placeholder}}` tokens remain

### 3. Create Session

Run the create command:

```bash
ace-coworker create <path-to-job.yaml>
```

This creates the session directory at `.cache/ace-coworker/<session-id>/` with:

```
.cache/ace-coworker/<session-id>/
├── session.yaml                   # Session metadata
├── jobs/                          # Step files (.j.md extension)
│   ├── 010-init.j.md             # pending
│   ├── 020-implement.j.md        # pending
│   └── 030-test.j.md             # pending
└── reports/                       # Report files (.r.md extension)
    └── (created as steps complete)
```

### 4. Report Result

Show the user:
- Session ID and name
- Session directory path
- Total step count
- First step to work on

Example output:
```
Session: work-on-task-123 (8or5kx)
Created: .cache/ace-coworker/8or5kx/

Steps: 3 total
  010: onboard [in_progress]
  020: work-on-task [pending]
  030: finalize [pending]

First step: onboard

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
      Report when done: ace-coworker report init.md

  - name: implement
    skill: ace:work-on-task      # Optional skill reference
    instructions: |
      Implement the feature.
      Report when done: ace-coworker report impl.md

  - name: test
    instructions: |
      Run tests and verify.
      Report when done: ace-coworker report test.md
```

### Skill-Aware Steps

Steps can include a `skill:` field that references a Claude Code skill to invoke:

```yaml
- name: work-on-task
  skill: ace:work-on-task
  instructions: |
    Work on task 123.
    Follow project conventions.
```

When executing this step, invoke `/ace:work-on-task 123` then follow the skill workflow.

### Common Skill References

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `onboard` | `/onboard` | Load project context |
| `ace:work-on-task` | `/ace:work-on-task <taskref>` | Implement task changes |
| `ace:create-pr` | `/ace:create-pr` | Create pull request |
| `ace:review-pr` | `/ace:review-pr [pr#]` | Review code changes |
| `ace:commit` | `/ace:commit` | Generate commit message |
| `ace:update-pr-desc` | `/ace:update-pr-desc` | Update PR description |

### Parameter Passing

Extract parameters from instructions for skill invocation:

```yaml
- name: work-on-task
  skill: ace:work-on-task
  instructions: |
    Work on task 148.          # Extract "148" as taskref
    Implement required changes.
```

Agent Action: Run `/ace:work-on-task 148`

### Dynamic Parameter Updates

Some steps need parameters from previous steps (e.g., PR number):

```yaml
- name: create-pr
  skill: ace:create-pr
  instructions: |
    Create a pull request.
    Capture the PR number for subsequent review steps.
    Update the next steps with the PR number.
```

When completing this step:
1. Note the PR number from the skill output
2. Mentally track for subsequent review steps
3. Report includes the PR number for reference

## Session Archiving

When `ace-coworker create job.yaml` runs, the source job.yaml is automatically archived to `<task>/jobs/{session_id}-job.yml`. This keeps the task folder clean while preserving the job recipe for provenance.

**Note:** The archived file is for historical reference only—always use `ace-coworker status` to query the current session state.

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
| 0 | Success - session created |
| 1 | General error |
| 3 | File not found (job.yaml) |
| 4 | Invalid configuration format |

## Success Criteria

- job.yaml successfully validated
- Session directory created with structure intact
- Session metadata written to session.yaml
- Step files created with proper status (pending)
- Clear summary provided to user
- User knows how to proceed (drive session)

## Next Steps

After creating the session, use the drive workflow to work through steps:

```bash
# Check status
ace-coworker status

# Drive execution through the workflow
/ace:coworker-drive-session
```
