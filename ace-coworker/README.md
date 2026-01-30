# ace-coworker

Work queue-based session management for AI-assisted workflows.

## Overview

ace-coworker manages workflow sessions using a **file-based work queue model** where:
- Steps have states: `done`, `in_progress`, `pending`, `failed`
- Failed steps remain in queue as history (never overwritten)
- Work can be added dynamically during execution
- Status shows complete queue state including history

## Installation

Add to your Gemfile:

```ruby
gem "ace-coworker"
```

Or install directly:

```bash
gem install ace-coworker
```

## Quick Start

```bash
# Start a session from YAML config
ace-coworker create job.yaml

# Check current status
ace-coworker status

# Complete current step with a report
ace-coworker report my-report.md

# Mark step as failed
ace-coworker fail --message "Tests failed"

# Add a new step dynamically
ace-coworker add "fix-bug" --instructions "Fix the issue"

# Retry a failed step
ace-coworker retry 040
```

## Job Configuration

Create a `job.yaml` file:

```yaml
session:
  name: my-workflow
  description: Example workflow

steps:
  - name: init
    instructions:
      - Set up the project structure.
      - "Report when done: ace-coworker report init-report.md"

  - name: implement
    instructions:
      - Implement the feature.
      - "Report when done: ace-coworker report impl-report.md"

  - name: test
    instructions:
      - Run tests and verify.
      - "Report when done: ace-coworker report test-report.md"
```

## Session Storage

Sessions are stored in `.cache/ace-coworker/<session-id>/`:

```
.cache/ace-coworker/8or5kx/
├── session.yaml                   # Session metadata
├── jobs/                          # Step files (.j.md extension)
│   ├── 010-init.j.md             # done
│   ├── 020-implement.j.md        # in_progress
│   └── 030-test.j.md             # pending
└── reports/                       # Report files (.r.md extension)
    ├── 010-init.r.md             # completed report
    └── 020-implement.r.md        # in-progress report
```

Each step has:
- **Step file** (`jobs/NNN-name.j.md`) - Contains step instructions and status
- **Report file** (`reports/NNN-name.r.md`) - Contains completion report (created when step is done)

## Numbering Convention

| Pattern | Purpose | Example |
|---------|---------|---------|
| `010`, `020`, `030` | Main tasks (10-step gaps) | `010-init.j.md` |
| `010.01`, `010.02` | Subtasks | `010.01-setup.j.md` |
| `041`, `042` | Injected after existing | `041-fix.j.md` |

## Commands

### `create FILE`
Create a new session from YAML config.

### `status`
Display current queue state.

### `report FILE`
Complete current step with report content.

### `fail --message TEXT`
Mark current step as failed.

### `add NAME [--instructions TEXT]`
Add a new step dynamically.

### `retry STEP_REF`
Retry a failed step (creates new step linked to original).

## Fork Context

Jobs can declare `context: fork` in frontmatter to run in isolated agent contexts.

### When to Use

- Complex multi-step work that benefits from focused agent attention
- Work requiring clean agent context without conversation history
- Independent execution that can proceed without orchestrator oversight

### Job File Structure

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

When `ace-coworker status` encounters a fork job:

1. Outputs Task tool instructions instead of raw instructions
2. Orchestrating agent invokes Task tool with job content
3. Subagent executes in isolated context
4. Orchestrator captures response and submits via `ace-coworker report`

### Best Practice: Separate Work and Verification

Workers should not verify their own work. Use separate jobs:

```yaml
steps:
  - name: implement
    context: fork
    instructions: Implement the feature...

  - name: verify
    # No fork - orchestrator runs verification
    instructions: Run ace-test and verify results
```

See [Fork Context Guide](handbook/guides/fork-context.g.md) for detailed documentation.

## License

MIT
