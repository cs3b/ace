# ace-coworker Advanced Features (Tasks 240.01, 240.03)

## Overview

This document describes the user-facing behavior for human approval gates and the coworker frontmatter schema used to prepare sessions from task/workflow files.

## Command Types

- CLI commands: `ace-coworker ...`
- Workflow files: `.wf.md` or task `.s.md` with `coworker:` frontmatter

## Human Approval Gates

### Gate Step Declaration

Add gate metadata to a step frontmatter:

```yaml
---
name: review-gate
status: pending
gate: true
gate_prompt: "Review implementation before create-pr"
---
```

### Status Output

When a gate is reached, the session is paused and status shows the gate prompt:

```
Session: abc123
Status: paused at gate
Step: 030-review-gate

Gate prompt:
Review implementation before create-pr

To continue: ace-coworker resume --approve
To reject: ace-coworker resume --reject --reason "needs fixes"
```

### Resume Flows

Approve and continue:

```
ace-coworker resume --approve
```

Reject with reason (session marked rejected, manual recovery required):

```
ace-coworker resume --reject --reason "needs fixes"
```

### Tips

- Use short, explicit prompts so reviewers know what to check.
- Rejection does not rewind previous steps; create a new session if needed.

## Frontmatter Schema

### Basic Example

```yaml
---
id: v.0.9.0+task.148
status: pending

coworker:
  session:
    required: true
  workflow:
    preset: work-on-task
  variables:
    taskref: "148"
    branch: "148-feature"
---

# Task 148: Implement Feature
```

### Inline Workflow Steps

```yaml
---
coworker:
  session:
    required: true
  workflow:
    steps:
      - name: implement
        instructions: |
          Implement the task below.
          Report with: ace-coworker report <file>
      - name: test
        instructions: |
          Run ace-test.
          Report with: ace-coworker report <file>
        verification: ace-test
---
```

### Prepare From File

```
ace-coworker prepare --file .ace-taskflow/v.0.9.0/tasks/148-foo/148.00-orchestrator.s.md
```

### Parent/Child Sessions

Child session created with explicit parent:

```
ace-coworker prepare --file task-148.01.s.md --parent abc123
```

List with hierarchy:

```
ace-coworker list --tree
```

Example output:

```
SESSION   TASK     STATUS    STEP
abc123    148      running   implement
|-- abc123.1  148.01  completed  2/2
|-- abc123.2  148.02  running    1/2
`-- abc123.3  148.03  pending    0/2
```

## Troubleshooting

- If `ace-coworker prepare --file` ignores frontmatter, verify the `coworker:` key is at the root of the frontmatter.
- If `list --tree` looks flat, check that session metadata includes `parent` values.
