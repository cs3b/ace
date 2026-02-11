# Fork Context Guide

## Overview

Fork context enables phase files to run in isolated agent contexts using the Task tool. When a phase has `context: fork` in its frontmatter, ace-assign outputs instructions for the orchestrating agent to execute the phase via a subagent.

## When to Use Fork Context

Use fork context when:

- **Isolation is needed** - The phase requires a clean agent context without previous conversation state
- **Complex multi-phase work** - The phase involves substantial implementation that benefits from focused agent attention
- **Independent execution** - The work can proceed without real-time interaction with the orchestrator

Do **not** use fork context for:

- Simple instructions that the orchestrator can execute directly
- Phases that require continuous orchestrator oversight
- Verification phases (see Anti-patterns below)

## Phase File Structure

Fork context phases can use a rich structure with distinct sections:

```markdown
---
status: pending
context: fork
---

## Onboard

Load context before starting work:
- `ace-bundle project`
- `ace-taskflow task {{taskref}}`

## Work

[Main instructions for the forked agent]

Implement the feature following project conventions.
Run tests after each significant change.

## Report

Return structured summary:
- **Task**: task ID and title
- **Status**: completed | partial | blocked
- **Changes**: files modified and what changed
- **Commits**: commit hashes and messages created
- **Issues**: problems encountered or deferred decisions
```

### Section Purposes

| Section | Purpose |
|---------|---------|
| **Onboard** | Context loading commands to run before work |
| **Work** | Main implementation instructions |
| **Report** | Expected output format from the forked agent |

## Execution Flow

When `ace-assign status` encounters a fork context phase:

1. Displays the phase file as a Task tool prompt
2. Includes assignment context (working directory, assignment ID)
3. Instructs the orchestrator to use Task tool for execution
4. After completion, the orchestrator submits a report via `ace-assign report`

```
ace-assign status
  |
  +-- Detects context: fork
  +-- Outputs Task tool instructions
  +-- Orchestrator invokes Task tool
  +-- Subagent executes phase content
  +-- Subagent returns structured report
  +-- Orchestrator calls: ace-assign report <report.md>
  +-- Advances to next phase
```

## Context Isolation Model

Fork context provides:

- **Clean slate** - No prior conversation affecting the subagent
- **Focused task** - Single phase with clear boundaries
- **Structured output** - Report format ensures consistent results

The orchestrating agent:

- Maintains workflow state
- Coordinates between phases
- Processes subagent reports
- Handles failures and retries

## Anti-Patterns

### Do Not Combine Work and Verify

**Wrong:** Worker verifies its own work

```yaml
phases:
  - name: implement-and-verify
    context: fork
    instructions: |
      Implement the feature.
      Then verify it works correctly.  # BAD: self-verification
```

**Right:** Separate phases for work and verification

```yaml
phases:
  - name: implement
    context: fork
    instructions: |
      Implement the feature.

  - name: verify
    # No context: fork - orchestrator runs this
    instructions: |
      Run ace-test to verify implementation.
```

### Do Not Use Fork for Simple Commands

**Wrong:** Forking for trivial work

```yaml
phases:
  - name: run-tests
    context: fork
    instructions: Run ace-test
```

**Right:** Orchestrator handles simple commands directly

```yaml
phases:
  - name: run-tests
    instructions: Run ace-test and report results
```

## Example Preset

A typical work-on-task preset with fork context:

```yaml
name: work-on-task
description: Work on a task with forked implementation

phases:
  - name: prepare
    instructions:
      - Load task context
      - Review requirements

  - name: implement
    context: fork
    instructions: |
      ## Onboard
      - ace-bundle project
      - ace-taskflow task {{taskref}}

      ## Work
      Implement the task following the specification.

      ## Report
      Return: status, changes, commits, issues

  - name: verify
    instructions:
      - Run ace-test
      - Verify all acceptance criteria
```

## Debugging

To see how fork phases are processed:

```bash
# Check current phase and context
ace-assign status

# Enable debug output
ACE_DEBUG=1 ace-assign status
```

## Related

- [ace-assign README](../../README.md) - Main documentation
- [Work Queue Model](../workflow-instructions/drive-assignment.wf.md) - Assignment management
