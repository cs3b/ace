# ace-coworker Usage Documentation

## Overview

ace-coworker manages workflow sessions using a **file-based work queue model**. Each step is a separate markdown file with frontmatter - the queue is reconstructed by scanning files, not stored in a single JSON file.

## Core Concepts

### File-Based Work Queue

```
SESSION DIRECTORY:
.cache/ace-coworker/8or5kx/
├── session.yaml                   # Session metadata
└── jobs/                          # Work queue files
    ├── 010-init-project.md        # done (report appended)
    ├── 020-write-tests.md         # done
    ├── 030-implement-foobar.md    # done
    ├── 040-run-tests.md           # FAILED <- preserved
    ├── 041-fix-implementation.md  # done (dynamically added)
    ├── 042-run-tests.md           # done (retry of 040)
    └── 050-report-status.md       # done
```

Key behaviors:
- **History Preservation**: Failed items remain as files showing what happened
- **Retry Creates New File**: Retrying step 040 creates 042-run-tests.md, original 040 stays
- **Dynamic Work**: Add steps during execution with `ace-coworker add`
- **Corruption Isolation**: One file fails, others survive
- **Git-Friendly**: Better diffs, easier merges

### Numbering Convention

| Pattern | Purpose | Example |
|---------|---------|---------|
| `010`, `020`, `030` | Main tasks (10-step gaps) | `010-init-project.md` |
| `010.01`, `010.02` | Subtasks of main task | `010.01-setup-dirs.md` |
| `010.01.01` | Sub-subtasks (3 levels max) | `010.01.01-create-lib.md` |
| `041`, `042` | Injected after existing | `041-fix-implementation.md` |

### Status States

| Status | Description |
|--------|-------------|
| `pending` | Waiting to be executed |
| `in_progress` | Currently being worked on (only one at a time) |
| `done` | Completed successfully |
| `failed` | Failed and preserved as history |

## session.yaml Schema

```yaml
session_id: 8or5kx
name: foobar-gem-session
description: Create a minimal Ruby gem with FooBar class
created_at: 2026-01-28T10:30:00Z
updated_at: 2026-01-28T11:15:00Z
source_config: job.yaml
```

## Job File Schema (jobs/*.md)

### Frontmatter Fields

```yaml
---
name: init-project                 # Step name (required)
status: done                       # pending | in_progress | done | failed
started_at: 2026-01-28T10:30:00Z   # When work began (optional)
completed_at: 2026-01-28T10:35:00Z # When finished (optional, if done/failed)
error: null                        # Error message (optional, if failed)
added_by: null                     # null | dynamic | retry_of:040 (optional)
parent: 010                        # Parent task number (optional, for subtasks)
---
```

### File Lifecycle

A job file evolves through its lifecycle:

**1. Initial State (pending):**
```markdown
---
name: implement-foobar
status: pending
---

# Instructions

Create the FooBar class with `greet` and `shout` methods.

```ruby
class FooBar
  def greet(name)
    "Hello, #{name}!"
  end
end
```
```

**2. Work Started (in_progress):**
```markdown
---
name: implement-foobar
status: in_progress
started_at: 2026-01-28T10:38:00Z
---

# Instructions

Create the FooBar class with `greet` and `shout` methods.
...
```

**3. Completed (done with report appended):**
```markdown
---
name: implement-foobar
status: done
started_at: 2026-01-28T10:38:00Z
completed_at: 2026-01-28T10:45:00Z
---

# Instructions

Create the FooBar class with `greet` and `shout` methods.

```ruby
class FooBar
  def greet(name)
    "Hello, #{name}!"
  end
end
```

---

# Report

Implemented FooBar class with both methods.
- greet: returns greeting string
- shout: returns uppercase greeting

Files created:
- lib/foo_bar.rb
```

**4. Failed State:**
```markdown
---
name: run-tests
status: failed
started_at: 2026-01-28T10:42:00Z
completed_at: 2026-01-28T10:43:00Z
error: "2 tests failed: test_greet, test_shout"
---

# Instructions

Run the tests:
```bash
ruby -Ilib:test test/foo_bar_test.rb
```
```

## CLI Commands

### Start Session

```bash
# Start from YAML config file
ace-coworker start --config job.yaml

# Output:
# Session: foobar-gem-session (8or5kx)
# Created: .cache/ace-coworker/8or5kx/
# Step 010: init-project [in_progress]
#
# Instructions:
# Create a minimal Ruby project structure:
# ...
```

### Check Status

```bash
ace-coworker status

# Output:
# QUEUE - Session: foobar-gem-session (8or5kx)
# FILE                           STATUS       NAME
# 010-init-project.md            done         init-project
# 020-write-tests.md             done         write-tests
# 030-implement-foobar.md        in_progress  implement-foobar
# 040-run-tests.md               pending      run-tests
# 050-report-status.md           pending      report-status
```

### Complete Step with Report

```bash
ace-coworker report impl-report.md

# Output:
# Step 030 (implement-foobar) completed
# Report appended to: jobs/030-implement-foobar.md
# Advancing to step 040: run-tests
#
# Instructions:
# Run the tests:
# ruby -Ilib:test test/foo_bar_test.rb
```

### Mark Step as Failed

```bash
ace-coworker fail --message "2 tests failed: test_greet, test_shout"

# Output:
# Step 040 (run-tests) marked as failed
# Updated: jobs/040-run-tests.md
# Error: 2 tests failed: test_greet, test_shout
#
# Options:
# - ace-coworker add "fix-step" to add a fix step
# - ace-coworker retry 040 to retry this step
```

### Add Step Dynamically

```bash
ace-coworker add "fix-implementation" --instructions "Fix the FooBar bug"

# Output:
# Created: jobs/041-fix-implementation.md
# Status: in_progress
```

### Retry Failed Step

```bash
ace-coworker retry 040

# Output:
# Created: jobs/042-run-tests.md (retry of 040)
# Original 040-run-tests.md preserved: failed
# Note: Step 041 (fix-implementation) must complete first
```

## job.yaml Input Format

```yaml
session:
  name: foobar-gem-session
  description: Create a minimal Ruby gem with FooBar class

steps:
  - name: init-project
    instructions: |
      Create a minimal Ruby project structure:

      ```bash
      mkdir -p lib test
      ```

      Create lib/foo_bar.rb with a placeholder:
      ```ruby
      class FooBar
        # TODO: implement
      end
      ```

      Report when done with: ace-coworker report init-report.md

  - name: write-tests
    instructions: |
      Create test/foo_bar_test.rb with tests...

      Report when done with: ace-coworker report tests-report.md

  - name: implement-foobar
    instructions: |
      Implement the FooBar class...

      Report when done with: ace-coworker report impl-report.md

  - name: run-tests
    instructions: |
      Run the tests:

      ```bash
      ruby -Ilib:test test/foo_bar_test.rb
      ```

      Report with test output: ace-coworker report test-results.md

  - name: report-status
    instructions: |
      Summarize what was created...

      Final report: ace-coworker report final-report.md
```

## Usage Scenarios

### Scenario 1: Happy Path - Complete Workflow

```bash
# Start session
ace-coworker start --config job.yaml

# Complete each step
ace-coworker report init-report.md
ace-coworker report tests-report.md
ace-coworker report impl-report.md
ace-coworker report test-results.md
ace-coworker report final-report.md

# Final status shows all done
ace-coworker status
# All files show status: done
```

### Scenario 2: Failure and Recovery

```bash
# Progress through steps
ace-coworker start --config job.yaml
ace-coworker report init-report.md
ace-coworker report tests-report.md
ace-coworker report impl-report.md

# Tests fail
ace-coworker fail --message "2 tests failed"

# Add fix step
ace-coworker add "fix-bug" --instructions "Fix the implementation bug"

# Complete fix
ace-coworker report fix-report.md

# Retry tests
ace-coworker retry 040
ace-coworker report test-results.md

# Final status shows history
ace-coworker status
# Shows: done, done, done, FAILED (preserved), done, done
```

### Scenario 3: Subtask Injection

```bash
# Mid-workflow, break down a complex step
ace-coworker status
# Step 030 in_progress

# Add subtasks for step 030
ace-coworker add "030.01-design-api" --instructions "Design the API interface"
ace-coworker add "030.02-implement-core" --instructions "Implement core logic"
ace-coworker add "030.03-add-validation" --instructions "Add input validation"

# Complete subtasks in order
ace-coworker report design-report.md
ace-coworker report core-report.md
ace-coworker report validation-report.md

# Then complete the parent
ace-coworker report impl-report.md
```

## Error Handling

| Error | Message |
|-------|---------|
| No session | "Error: No active session. Use 'ace-coworker start' to begin." |
| Missing config | "Error: Config file not found: job.yaml" |
| Missing report | "Error: Report file not found: report.md" |
| Invalid step | "Error: Step 099 not found in queue" |
| Already complete | "Error: Session already completed. Start new session." |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | No active session |
| 3 | File not found (config or report) |
| 4 | Invalid step reference |
| 5 | Session already completed |
