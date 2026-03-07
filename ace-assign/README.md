# ace-assign

Work queue-based assignment management for AI-assisted workflows.

## Overview

ace-assign manages workflow assignments using a **file-based work queue model** where:
- Phases have states: `done`, `in_progress`, `pending`, `failed`
- Failed phases remain in queue as history (never overwritten)
- Work can be added dynamically during execution
- Status shows complete queue state including history

## Installation

Add to your Gemfile:

```ruby
gem "ace-assign"
```

Or install directly:

```bash
gem install ace-assign
```

## Quick Start

```bash
# Start an assignment from YAML config
ace-assign create job.yaml

# Check current status
ace-assign status

# Complete current phase with a report
ace-assign finish --message my-report.md

# Mark phase as failed
ace-assign fail --message "Tests failed"

# Add a new phase dynamically
ace-assign add "fix-bug" --instructions "Fix the issue"

# Retry a failed phase
ace-assign retry 040
```

## Job Configuration

Create a `job.yaml` file:

```yaml
assignment:
  name: my-workflow
  description: Example workflow

phases:
  - name: init
    instructions:
      - Set up the project structure.
      - "Report when done: ace-assign finish --message init-report.md"

  - name: implement
    instructions:
      - Implement the feature.
      - "Report when done: ace-assign finish --message impl-report.md"

  - name: test
    instructions:
      - Run tests and verify.
      - "Report when done: ace-assign finish --message test-report.md"
```

## Assignment Storage

Assignments are stored in `.ace-local/assign/<assignment-id>/`:

```
.ace-local/assign/8or5kx/
├── assignment.yaml               # Assignment metadata
├── phases/                       # Phase files (.ph.md extension)
│   ├── 010-init.ph.md           # done
│   ├── 020-implement.ph.md      # in_progress
│   └── 030-test.ph.md           # pending
└── reports/                      # Report files (.r.md extension)
    ├── 010-init.r.md            # completed report
    └── 020-implement.r.md       # in-progress report
```

Each phase has:
- **Phase file** (`phases/NNN-name.ph.md`) - Contains phase instructions and status
- **Report file** (`reports/NNN-name.r.md`) - Contains completion report (created when phase is done)

## Numbering Convention

| Pattern | Purpose | Example |
|---------|---------|---------|
| `010`, `020`, `030` | Main tasks (10-step gaps) | `010-init.ph.md` |
| `010.01`, `010.02` | Nested phases (children) | `010.01-setup.ph.md` |
| `041`, `042` | Injected after existing | `041-fix.ph.md` |
| `010.01.01` | Deeply nested (up to 3 levels) | `010.01.01-detail.ph.md` |

**Limits**: Max 999 top-level phases, 99 children per parent, 3 nesting levels.

## Hierarchical Phases

Phases can be nested to create parent-child relationships. Parent phases automatically complete when all their children are done.

### Creating Child Phases

```bash
# Add a child phase under parent 010
ace-assign add verify --after 010 --child -i "Verify the setup"
# Creates: 010.01-verify.ph.md

# Add another child
ace-assign add test --after 010 --child -i "Test the setup"
# Creates: 010.02-test.ph.md
```

### Creating Sibling Phases

```bash
# Add a sibling after 010 (creates 011, renumbers existing if needed)
ace-assign add hotfix --after 010 -i "Apply hotfix"
# Creates: 011-hotfix.ph.md (renumbers 011+ to 012+ if they exist)
```

### Hierarchy Rules

1. **Completion cascades up**: When all children of a phase are done, the parent is auto-completed
2. **Work cascades down**: A parent with pending children is skipped; its first pending child becomes current
3. **Renumbering cascades down**: When a parent is renumbered, all descendants are updated too

### Status Display

Hierarchical status shows the tree structure:

```
NUMBER       STATUS      NAME                           CHILDREN
----------------------------------------------------------------------
010          ▶ Active    setup                          (1/2 done)
|-- 010.01   ✓ Done      verify
\-- 010.02   ○ Pending   test
020          ○ Pending   implement
```

## Commands

### `create FILE`
Create a new assignment from YAML config.

### `status`
Display current queue state (shows hierarchy by default, use `--flat` for flat view).

### `start [STEP]`
Start next workable pending phase, or an explicit pending `STEP` in the active assignment.

### `finish [STEP] --message VALUE`
Complete current in-progress phase with report content.

### `fail --message TEXT`
Mark current phase as failed.

### `add NAME [OPTIONS]`
Add a new phase dynamically.

Options:
- `--instructions, -i TEXT` - Phase instructions
- `--after, -a NUMBER` - Insert after this phase number
- `--child, -c` - Insert as child of `--after` phase (requires `--after`)

Examples:
```bash
# Add after current phase
ace-assign add fix -i "Fix the bug"

# Add as sibling after specific phase
ace-assign add verify --after 010 -i "Verify"

# Add as child of specific phase
ace-assign add sub-task --after 010 --child -i "Sub-task"
```

### `retry PHASE_REF`
Retry a failed phase (creates new phase linked to original).

## Fork Context

Phases can declare `context: fork` in frontmatter to run in isolated agent contexts.

### When to Use

- Complex multi-phase work that benefits from focused agent attention
- Work requiring clean agent context without conversation history
- Independent execution that can proceed without orchestrator oversight

### Phase File Structure

```markdown
---
status: pending
context: fork
---

## Onboard

Load context before starting work:
- `ace-bundle project`
- `ace-bundle task://{{taskref}}`

## Work

[Main instructions for the forked agent]

## Report

Return structured summary:
- **Status**: completed | partial | blocked
- **Changes**: files modified
- **Issues**: problems encountered
```

### Execution Flow

When `ace-assign status` encounters a fork phase:

1. Outputs Task tool instructions instead of raw instructions
2. Orchestrating agent invokes Task tool with phase content
3. Subagent executes in isolated context
4. Orchestrator captures response and submits via `ace-assign finish --message ...`

### Best Practice: Separate Work and Verification

Workers should not verify their own work. Use separate phases:

```yaml
phases:
  - name: implement
    context: fork
    instructions: Implement the feature...

  - name: verify
    # No fork - orchestrator runs verification
    instructions: Run ace-test and verify results
```

See [Fork Context Guide](handbook/guides/fork-context.g.md) for detailed documentation.

### Stall Detection

When a forked agent stalls (exits non-zero), the last message it produced is surfaced in the status output:

```
Current Phase: 020.04 - work-on-task
Current Status: failed
Stall Reason: Error: Cannot find module 'express'. Try running npm install first.
```

The stall reason (truncated to 2000 chars) is persisted in the phase frontmatter so it remains visible on subsequent `ace-assign status` calls.

## License

MIT
