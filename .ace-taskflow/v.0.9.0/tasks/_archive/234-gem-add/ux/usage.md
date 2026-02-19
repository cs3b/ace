# ace-coworker MVP Usage Documentation

## Overview

ace-coworker is a CLI tool that tracks workflow execution state between an agent and CLI. It manages session state, workflow steps, and agent reports.

## Installation

```bash
# From the ace-meta monorepo
bundle install
```

## CLI Commands

### Start a Workflow Session

```bash
# Start a new workflow session for a task
ace-coworker start --task 228

# Output:
# Session created: abc123
# Workflow: work-on-task
# Current step: 1/2 - implement
#
# Instructions:
# Execute wfi://work-on-task workflow
# When complete, report results with: ace-coworker report <file>
```

### Check Session Status

```bash
# Show current session status and next step instructions
ace-coworker status

# Output:
# Session: abc123
# Task: 228
# Status: running
# Current step: 1/2 - implement [pending]
#
# Instructions:
# Execute wfi://work-on-task workflow
# When complete, report results with: ace-coworker report <file>
```

### Submit Step Report

```bash
# Submit a report file to complete current step and advance
ace-coworker report /path/to/step-report.md

# Output:
# Report stored: implement-20260128-013500.md
# Step 1/2 (implement) completed
#
# Advancing to step 2/2: release
#
# Instructions:
# Execute wfi://draft-release workflow
# When complete, report results with: ace-coworker report <file>
```

### Workflow Completion

```bash
# When final step is reported
ace-coworker report /path/to/release-report.md

# Output:
# Report stored: release-20260128-014000.md
# Step 2/2 (release) completed
#
# Workflow completed successfully!
# Session: abc123
# Duration: 35 minutes
```

## Session Files

Sessions are stored in `.cache/ace-coworker/{session-id}/`:

```
.cache/ace-coworker/abc123/
├── job.json      # Session state
└── reports/      # Agent reports (placeholder for 234.02)
```

### job.json Schema (v1)

**MVP Schema (Task 234.01):**

```json
{
  "version": 1,
  "session_id": "8or5kx",
  "task_id": "228",
  "workflow": "work-on-task",
  "status": "running",
  "current_step": 0,
  "steps": [
    {"name": "implement", "status": "pending"},
    {"name": "release", "status": "pending"}
  ],
  "created_at": "2026-01-28T01:30:00Z",
  "updated_at": "2026-01-28T01:35:00Z"
}
```

**Full Schema (Task 234.04+):**

```json
{
  "version": 1,
  "session_id": "8or5kx",
  "task_id": "228",
  "workflow": "task-completion",
  "status": "running",
  "current_step": 2,
  "started_at": "2026-01-27T20:00:00Z",
  "updated_at": "2026-01-27T20:16:00Z",
  "steps": [
    {
      "name": "implement",
      "status": "completed",
      "attempts": 1,
      "completed_at": "2026-01-27T20:15:00Z"
    },
    {
      "name": "commit",
      "status": "completed",
      "attempts": 1,
      "completed_at": "2026-01-27T20:16:00Z"
    },
    {
      "name": "test",
      "status": "in_progress",
      "attempts": 2,
      "last_error": "3 tests failed: test_a, test_b, test_c"
    },
    {
      "name": "review-gate",
      "status": "pending"
    },
    {
      "name": "create-pr",
      "status": "pending"
    }
  ],
  "gate": null
}
```

### Session Status Lifecycle

```
[start] → created → running → paused → completed
                       ↓         ↑
                    failed ──────┘ (resume)
```

| Status | Description |
|--------|-------------|
| `created` | Session initialized, workflow not started |
| `running` | Workflow executing |
| `paused` | At human gate, waiting for approval (234.06) |
| `failed` | Step failed, awaiting retry/resume (234.04) |
| `completed` | Workflow finished successfully |

### Step Status Values

| Status | Description |
|--------|-------------|
| `pending` | Not yet started |
| `in_progress` | Currently executing |
| `completed` | Finished successfully |
| `failed` | Failed (may be retried) |
| `skipped` | Skipped (future: conditional steps) |

## Workflow Definition Format

Workflows are YAML files in `.ace-defaults/coworker/workflows/`. Each defines a sequence of steps with instructions, verifications, and control flow.

### Basic Workflow (MVP - Task 234.01)

`.ace-defaults/coworker/workflows/work-on-task.wf.yml`:

```yaml
name: work-on-task
description: Two-step task completion workflow

steps:
  - name: implement
    instruction: |
      Execute wfi://work-on-task workflow.
      When complete, report results with: ace-coworker report <file>

  - name: release
    instruction: |
      Execute wfi://draft-release workflow.
      When complete, report results with: ace-coworker report <file>
```

### Full Workflow Schema (Task 234.04+)

Complete schema with verifications, retries, and gates:

```yaml
name: task-completion
description: Complete a task through implementation, testing, and PR

steps:
  - name: implement
    instruction: |
      Execute wfi://work-on-task for task $task_id.
      When complete, report results with: ace-coworker report <file>
    verifications:              # (Task 234.04)
      - ace-test passes
      - no lint errors
    retries: 5                  # Max retry attempts
    timeout: 30m                # Step timeout
    on_repeated_failure: 3      # Stop after N same errors
    restart_hint: "Focus on one failing test at a time"

  - name: commit
    instruction: |
      Execute wfi://commit workflow.
      When complete, report results with: ace-coworker report <file>
    verifications:
      - commit created

  - name: review-gate           # (Task 234.06)
    gate: human
    prompt: "Review implementation before creating PR"

  - name: create-pr
    instruction: |
      Execute wfi://create-pr workflow.
      When complete, report results with: ace-coworker report <file>
```

### Step Schema Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Step identifier |
| `instruction` | string | yes* | Instructions for agent (*not for gates) |
| `verifications` | string[] | no | Commands that must succeed (234.04) |
| `retries` | int | no | Max retry attempts (default: 5) |
| `timeout` | duration | no | Step timeout (default: 30m) |
| `on_repeated_failure` | int | no | Stop after N identical errors (default: 3) |
| `restart_hint` | string | no | Guidance for retries |
| `gate` | string | no | Gate type: `human` (234.06) |
| `prompt` | string | no | Gate prompt for human approval |

### Variable Interpolation

Steps support variable interpolation:
- `$task_id` - Task ID from `--task` flag
- `$session_id` - Current session ID
- `$step_name` - Current step name

## Agent Integration

The agent follows this pattern:

1. Agent invokes `/ace:coworker-work-on 228`
2. Agent calls `ace-coworker start --task 228` to get step 1 instructions
3. Agent follows step 1 instructions (wfi://work-on-task)
4. Agent writes report file and calls `ace-coworker report <file>`
5. Agent follows step 2 instructions (wfi://draft-release)
6. Agent writes report file and calls `ace-coworker report <file>`
7. Workflow complete

## Error Handling

### No Active Session

```bash
ace-coworker status
# Error: No active session found
# Use 'ace-coworker start --task <id>' to begin a workflow
```

### Missing Report File

```bash
ace-coworker report /nonexistent/file.md
# Error: Report file not found: /nonexistent/file.md
```

### Already Completed Session

```bash
ace-coworker report report.md
# Error: Session already completed
# Start a new session with 'ace-coworker start --task <id>'
```

## Configuration

Configuration file: `.ace/coworker/config.yml`

```yaml
coworker:
  cache_dir: .cache/ace-coworker
  default_workflow: work-on-task
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (missing file, invalid state) |
| 2 | No active session |

---

## Logging and Reporting (Task 234.02)

### Session Directory Structure

After logging is enabled, a session directory looks like:

```
.cache/ace-coworker/{session-id}/
├── job.json                              # Session state
├── log.jsonl                             # Event stream
└── reports/                              # Delegation and report files
    ├── 001-01-implement-delegation.md    # Step 1, attempt 1: what we asked
    ├── 001-01-implement-report.md        # Step 1, attempt 1: what came back
    ├── 001-02-implement-delegation.md    # Step 1, attempt 2 (retry)
    ├── 001-02-implement-report.md
    ├── 002-01-release-delegation.md      # Step 2, attempt 1
    └── 002-01-release-report.md
```

### File Naming Convention

**Pattern:** `{step_number}-{attempt_number}-{step_name}-{type}.md`

| Component | Format | Example | Description |
|-----------|--------|---------|-------------|
| step_number | 3-digit zero-padded | `001`, `002` | Sequential step index (1-based) |
| attempt_number | 2-digit zero-padded | `01`, `02` | Attempt within step (1-based) |
| step_name | lowercase | `implement`, `release` | Step name from workflow |
| type | literal | `delegation`, `report` | What the file contains |

### Log Event Schema

```jsonl
{"ts":"8or5kx","event":"workflow_started","workflow":"work-on-task","task_id":"228","session_id":"8or5kx"}
{"ts":"8or5ky","event":"step_started","step":"implement","step_index":0,"attempt":1,"session_id":"8or5kx"}
{"ts":"8or5kz","event":"delegation_sent","step":"implement","attempt":1,"file":"reports/001-01-implement-delegation.md"}
{"ts":"8or5m0","event":"report_received","step":"implement","attempt":1,"file":"reports/001-01-implement-report.md"}
{"ts":"8or5m1","event":"step_completed","step":"implement","attempt":1}
```

For full logging documentation, see the implementation details in task 234.02.
