---
doc-type: guide
title: Fork Context Guide
purpose: Explain fork context execution model, boundaries, and recovery patterns for ace-assign subtree delegation.
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
---

# Fork Context Guide

## Overview

Fork context enables step files to run in isolated agent contexts using the Task tool. When a step has `context: fork` in its frontmatter, ace-assign outputs instructions for the orchestrating agent to execute the step via a subagent.

You can also set a per-step provider override with `fork.provider`:

```yaml
---
context: fork
fork:
  provider: "claude:sonnet@yolo"
---
```

Provider precedence during `ace-assign fork-run`:

1. CLI `--provider`
2. Step `fork.provider`
3. Assign config `execution.provider`
4. Built-in default

For hierarchical split workflows, use **parent-only** fork markers:
- Split parent step: `context: fork`
- Child steps (`onboard-base`, `task-load`, `plan-task`, `work-on-task`, `verify-test`, `release-minor`): no `context: fork`
- Runtime execution scope is controlled explicitly with `--assignment <id>@<root>`

## When to Use Fork Context

Use fork context when:

- **Isolation is needed** - The step requires a clean agent context without previous conversation state
- **Complex multi-step work** - The step involves substantial implementation that benefits from focused agent attention
- **Independent execution** - The work can proceed without real-time interaction with the orchestrator

Do **not** use fork context for:

- Simple instructions that the orchestrator can execute directly
- Steps that require continuous orchestrator oversight
- Verification steps (see Anti-patterns below)

## Step File Structure

Fork context steps can use a rich structure with distinct sections:

```markdown
---
status: pending
context: fork
---

## Onboard

Load context before starting work:
- `ace-bundle project`
- `ace-task show {{taskref}}`

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

When `ace:assign-drive` (or manual orchestration) encounters a fork-enabled subtree:

1. Runs `ace-assign status`
2. Detects `Fork subtree detected (root: ...)` in output (outside fork scope)
3. Delegates with `ace-assign fork-run --assignment <id>@<root>`
4. Fork launcher executes `/as-assign-drive <id>@<root>` in a scoped process
5. Scoped process advances only inside subtree
6. Parent process resumes after subtree completion

```
ace:assign-drive loop
  |
  +-- ace-assign status
  +-- Detects "Fork subtree detected (root: ...)"
  +-- ace-assign fork-run --assignment <id>@<root>
  +-- Forked /as-assign-drive <id>@<root>
  +-- Subtree completes
  +-- Parent loop continues
```

## Context Isolation Model

Fork context provides:

- **Clean slate** - No prior conversation affecting the subagent
- **Focused task** - Single step with clear boundaries
- **Structured output** - Report format ensures consistent results

The orchestrating agent:

- Maintains workflow state
- Coordinates between steps
- Processes subagent reports
- Handles failures and retries

## Recovery From Failed Fork Subtrees

When a forked subtree fails, use **adaptive minimal-safe replay**:

- Do not automatically replay the whole subtree.
- Replay only the minimum set of steps needed to restore context confidence.
- Always review prior subtree reports before choosing replay depth.

Typical recovery shape:

```
failed step
  -> recovery onboarding/report review
  -> verify-test
  -> retry failed or nearest affected step
  -> resume remaining subtree steps
```

Recovery steps are inserted between the failed step and the next pending step (or appended if the failure happened at subtree end). This keeps history intact while avoiding unnecessary rework.

## Anti-Patterns

### Do Not Combine Work and Verify

**Wrong:** Worker verifies its own work

```yaml
steps:
  - name: implement-and-verify
    context: fork
    instructions: |
      Implement the feature.
      Then verify it works correctly.  # BAD: self-verification
```

**Right:** Separate steps for work and verification

```yaml
steps:
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
steps:
  - name: run-tests
    context: fork
    instructions: Run ace-test
```

**Right:** Orchestrator handles simple commands directly

```yaml
steps:
  - name: run-tests
    instructions: Run ace-test and report results
```

## Example Preset

A typical work-on-task preset with fork context:

```yaml
name: work-on-task
description: Work on a task with forked implementation

steps:
  - name: prepare
    instructions:
      - Load task context
      - Review requirements

  - name: implement
    context: fork
    instructions: |
      ## Onboard
      - ace-bundle project
      - ace-task show {{taskref}}

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

To see how fork steps are processed:

```bash
# Check current step and context
ace-assign status

# Enable debug output
ACE_DEBUG=1 ace-assign status
```

## Related

- [ace-assign README](../../README.md) - Main documentation
- [Work Queue Model](../workflow-instructions/drive-assignment.wf.md) - Assignment management
- `ace-assign fork-run --root <step> --assignment <id>` - Prepare subtree-scoped fork session
