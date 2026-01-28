# ace-coworker Usage Documentation

## Overview

ace-coworker manages workflow sessions using a **work queue model**. The queue represents both pending work AND execution history - failed steps are preserved, not overwritten.

## Core Concepts

### Work Queue Model

```
QUEUE STATE EXAMPLE:
#  STATUS       NAME              NOTES
1  done         init-project      completed (report: 001-init.md)
2  done         write-tests       completed
3  done         implement-foobar  completed
4  failed       run-tests         "2 tests failed" <- PRESERVED
5  done         fix-implementation dynamically added
6  done         run-tests         retry of #4
7  done         report-status     final step
```

Key behaviors:
- **History Preservation**: Failed items stay in queue showing what happened
- **Retry Creates New**: Retrying step #4 creates NEW step #6, original stays
- **Dynamic Work**: Add steps during execution with `ace-coworker add`

### Status States

| Status | Description |
|--------|-------------|
| `done` | Completed successfully |
| `in_progress` | Currently being worked on (only one at a time) |
| `in_queue` | Waiting to be executed |
| `failed` | Failed and preserved as history |

## CLI Commands

### Start Session

```bash
# Start from YAML config file
ace-coworker start --config job.yaml

# Output:
# Session: foobar-gem-session (8or5kx)
# Step 1/5: init-project [in_progress]
#
# Instructions:
# Create a minimal Ruby project structure:
# ...
```

### Check Status

```bash
ace-coworker status

# Output:
# QUEUE - Session: foobar-gem-session
# #  STATUS       NAME
# 1  done         init-project
# 2  done         write-tests
# 3  in_progress  implement-foobar
# 4  in_queue     run-tests
# 5  in_queue     report-status
```

### Complete Step with Report

```bash
ace-coworker report impl-report.md

# Output:
# Step 3/5 (implement-foobar) completed
# Advancing to step 4/5: run-tests
#
# Instructions:
# Run the tests:
# ruby -Ilib:test test/foo_bar_test.rb
```

### Mark Step as Failed

```bash
ace-coworker fail --message "2 tests failed: test_greet, test_shout"

# Output:
# Step 4 (run-tests) marked as failed
# Error: 2 tests failed: test_greet, test_shout
#
# Options:
# - ace-coworker add "fix-step" to add a fix step
# - ace-coworker retry 4 to retry this step
```

### Add Step Dynamically

```bash
ace-coworker add "fix-implementation" --instructions "Fix the FooBar bug"

# Output:
# Added step: fix-implementation
# Queue position: after step 4 (run-tests failed)
# Status: in_progress
```

### Retry Failed Step

```bash
ace-coworker retry 4

# Output:
# Added retry of step 4 (run-tests) as step 6
# Original step 4 preserved: failed (2 tests failed)
# Note: Step 5 (fix-implementation) must complete first
```

## job.yaml Format

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
    verifications:
      - ruby -Ilib:test test/foo_bar_test.rb

  - name: report-status
    instructions: |
      Summarize what was created...

      Final report: ace-coworker report final-report.md
```

## job.json State Format

```json
{
  "version": 1,
  "session_id": "8or5kx",
  "session_name": "foobar-gem-session",
  "created_at": "2026-01-28T10:30:00Z",
  "updated_at": "2026-01-28T11:15:00Z",
  "queue": [
    {
      "id": 1,
      "name": "init-project",
      "status": "done",
      "started_at": "2026-01-28T10:30:00Z",
      "completed_at": "2026-01-28T10:35:00Z",
      "report": "reports/001-init-project.md"
    },
    {
      "id": 2,
      "name": "run-tests",
      "status": "failed",
      "started_at": "2026-01-28T10:45:00Z",
      "completed_at": "2026-01-28T10:46:00Z",
      "error": "2 tests failed: test_greet, test_shout"
    },
    {
      "id": 3,
      "name": "fix-implementation",
      "status": "done",
      "started_at": "2026-01-28T10:46:00Z",
      "completed_at": "2026-01-28T10:50:00Z",
      "added_by": "dynamic",
      "report": "reports/003-fix-implementation.md"
    },
    {
      "id": 4,
      "name": "run-tests",
      "status": "in_progress",
      "started_at": "2026-01-28T10:50:00Z",
      "added_by": "retry_of:2"
    },
    {
      "id": 5,
      "name": "report-status",
      "status": "in_queue"
    }
  ]
}
```

## Session Directory Structure

```
.cache/ace-coworker/8or5kx/
├── job.json                    # Session state
└── reports/                    # Step reports
    ├── 001-init-project.md
    ├── 002-write-tests.md
    ├── 003-fix-implementation.md
    └── 004-run-tests.md
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
# All 5 steps: done
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
ace-coworker retry 4
ace-coworker report test-results.md

# Final status shows history
ace-coworker status
# Shows: done, done, done, FAILED (preserved), done, done
```

### Scenario 3: Dynamic Work Addition

```bash
# Mid-workflow, realize more work needed
ace-coworker status
# Step 3 in_progress

# Add verification step
ace-coworker add "verify-coverage" --instructions "Check test coverage > 80%"

# Continue workflow - new step executes after current
```

## Error Handling

| Error | Message |
|-------|---------|
| No session | "Error: No active session. Use 'ace-coworker start' to begin." |
| Missing config | "Error: Config file not found: job.yaml" |
| Missing report | "Error: Report file not found: report.md" |
| Invalid step | "Error: Step 99 not found in queue" |
| Already complete | "Error: Session already completed. Start new session." |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | No active session |
| 3 | File not found |
