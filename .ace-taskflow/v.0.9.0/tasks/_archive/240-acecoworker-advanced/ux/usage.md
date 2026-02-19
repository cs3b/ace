# ace-assign Advanced Features (Tasks 240.01, 240.03)

## Overview

This document describes the user-facing behavior for human approval gates and the assign frontmatter schema used to prepare assignments from task/workflow files.

## Command Types

- CLI commands: `ace-assign ...`
- Workflow files: `.wf.md` or task `.s.md` with `assign:` frontmatter

## Human Approval Gates

### Gate Phase Declaration

Add gate metadata to a phase frontmatter:

```yaml
---
name: review-gate
status: pending
gate: true
gate_prompt: "Review implementation before create-pr"
---
```

### Status Output

When a gate is reached, the assignment is paused and status shows the gate prompt:

```
Assignment: abc123
Status: paused at gate
Phase: 030-review-gate

Gate prompt:
Review implementation before create-pr

To continue: ace-assign resume --approve
To reject: ace-assign resume --reject --reason "needs fixes"
```

### Resume Flows

Approve and continue:

```
ace-assign resume --approve
```

Reject with reason (assignment marked rejected, manual recovery required):

```
ace-assign resume --reject --reason "needs fixes"
```

### Tips

- Use short, explicit prompts so reviewers know what to check.
- Rejection does not rewind previous phases; create a new assignment if needed.

## Frontmatter Schema

### Basic Example

```yaml
---
id: v.0.9.0+task.148
status: pending

assign:
  assignment:
    required: true
  workflow:
    preset: work-on-task
  variables:
    taskref: "148"
    branch: "148-feature"
---

# Task 148: Implement Feature
```

### Inline Workflow Phases

```yaml
---
assign:
  assignment:
    required: true
  workflow:
    phases:
      - name: implement
        instructions: |
          Implement the task below.
          Report with: ace-assign report <file>
      - name: test
        instructions: |
          Run ace-test.
          Report with: ace-assign report <file>
        verification: ace-test
---
```

### Prepare From File

```
ace-assign prepare --file .ace-taskflow/v.0.9.0/tasks/148-foo/148-orchestrator.s.md
```

### Parent/Child Assignments

Child assignment created with explicit parent:

```
ace-assign prepare --file task-148.01.s.md --parent abc123
```

List with hierarchy:

```
ace-assign list --tree
```

Example output:

```
ASSIGNMENT  TASK     STATUS    PHASE
abc123      148      running   implement
|-- abc123.1  148.01  completed  2/2
|-- abc123.2  148.02  running    1/2
`-- abc123.3  148.03  pending    0/2
```

## Troubleshooting

- If `ace-assign prepare --file` ignores frontmatter, verify the `assign:` key is at the root of the frontmatter.
- If `list --tree` looks flat, check that assignment metadata includes `parent` values.
