# ace-coworker Logging and Reporting Usage

## Overview

Task 234.02 adds comprehensive logging and reporting to ace-coworker:
- **JSONL Event Log**: Structured event stream for all workflow events
- **Delegation Files**: Markdown capture of instructions given to agents
- **Report Files**: Markdown storage of agent responses

## Session Directory Structure

After logging is enabled, a session directory looks like:

```
.cache/ace-coworker/{session-id}/
├── job.json                              # Session state (from 234.01)
├── log.jsonl                             # NEW: Event stream
└── reports/                              # NEW: Delegation and report files
    ├── 001-01-implement-delegation.md    # Step 1, attempt 1: what we asked
    ├── 001-01-implement-report.md        # Step 1, attempt 1: what came back
    ├── 001-02-implement-delegation.md    # Step 1, attempt 2 (retry)
    ├── 001-02-implement-report.md
    ├── 002-01-release-delegation.md      # Step 2, attempt 1
    └── 002-01-release-report.md
```

## File Naming Convention

**Pattern:** `{step_number}-{attempt_number}-{step_name}-{type}.md`

| Component | Format | Example | Description |
|-----------|--------|---------|-------------|
| step_number | 3-digit zero-padded | `001`, `002` | Sequential step index (1-based) |
| attempt_number | 2-digit zero-padded | `01`, `02` | Attempt within step (1-based) |
| step_name | lowercase | `implement`, `release` | Step name from workflow |
| type | literal | `delegation`, `report` | What the file contains |

**Examples:**
- `001-01-implement-delegation.md` - First step, first attempt, instructions sent
- `001-02-implement-report.md` - First step, second attempt (retry), agent response
- `002-01-release-delegation.md` - Second step, first attempt, instructions sent

## Log Events

### Event Types

| Event | When Logged | Description |
|-------|-------------|-------------|
| `workflow_started` | `ace-coworker start` | New workflow session created |
| `step_started` | Beginning of each step | Step execution begins |
| `delegation_sent` | After step starts | Instructions written to delegation file |
| `report_received` | `ace-coworker report` | Agent report stored |
| `step_completed` | After report stored | Step finished successfully |
| `step_failed` | On verification failure | Step failed (future: 234.04) |
| `workflow_paused` | Human gate triggered | Awaiting approval (future: 234.06) |
| `workflow_completed` | All steps done | Workflow finished successfully |

### Event Schema

```jsonl
{"ts":"8or5kx","event":"workflow_started","workflow":"work-on-task","task_id":"228","session_id":"8or5kx"}
{"ts":"8or5ky","event":"step_started","step":"implement","step_index":0,"attempt":1,"session_id":"8or5kx"}
{"ts":"8or5kz","event":"delegation_sent","step":"implement","attempt":1,"file":"reports/001-01-implement-delegation.md"}
{"ts":"8or5m0","event":"report_received","step":"implement","attempt":1,"file":"reports/001-01-implement-report.md"}
{"ts":"8or5m1","event":"step_completed","step":"implement","attempt":1}
```

### Schema Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ts` | string | Yes | 6-char ace-timestamp (UTC) from ace-support-timestamp |
| `event` | string | Yes | Event type identifier |
| `session_id` | string | Yes | Session identifier for correlation |
| `step` | string | Step events | Step name |
| `step_index` | integer | Step events | Zero-based step index |
| `attempt` | integer | Step events | Attempt number (1-based) |
| `file` | string | File events | Relative path to file |
| `workflow` | string | workflow_started | Workflow name |
| `task_id` | string | workflow_started | Task identifier |

## Usage Scenarios

### Scenario 1: Normal Workflow Execution

```bash
# Start workflow - creates log.jsonl and first delegation file
ace-coworker start --task 228

# Files created:
# - log.jsonl (workflow_started, step_started, delegation_sent events)
# - reports/001-01-implement-delegation.md
```

```bash
# Submit report - stores report, logs events, advances step
ace-coworker report /path/to/my-work.md

# Files created:
# - reports/001-01-implement-report.md
# - log.jsonl (report_received, step_completed, step_started, delegation_sent events)
# - reports/002-01-release-delegation.md
```

### Scenario 2: Reviewing Session History

```bash
# View all events for a session
cat .cache/ace-coworker/abc123/log.jsonl | jq

# Filter to step completion events
grep step_completed .cache/ace-coworker/abc123/log.jsonl

# Count attempts per step
grep step_started .cache/ace-coworker/abc123/log.jsonl | jq -r '.step + ": " + (.attempt | tostring)'
```

### Scenario 3: Retry Scenario (Future: 234.04)

When a step fails verification and retries:

```bash
# After failed verification, retry creates new attempt
# log.jsonl shows:
{"ts":"8or5m2","event":"step_failed","step":"implement","attempt":1,"reason":"tests_failed"}
{"ts":"8or5m3","event":"step_started","step":"implement","step_index":0,"attempt":2}
{"ts":"8or5m4","event":"delegation_sent","step":"implement","attempt":2,"file":"reports/001-02-implement-delegation.md"}
```

### Scenario 4: Inspecting Delegation Content

```bash
# View what instructions were sent to the agent
cat .cache/ace-coworker/abc123/reports/001-01-implement-delegation.md

# Example content:
# ---
# step: implement
# attempt: 1
# timestamp: 2026-01-28T01:35:00Z
# ---
#
# # Step: implement
#
# Execute wfi://work-on-task workflow.
# When complete, report results with: ace-coworker report <file>
```

## Delegation File Format

Delegation files contain the instructions sent to the agent:

```markdown
---
step: implement
step_index: 0
attempt: 1
timestamp: 2026-01-28T01:35:00Z
session_id: abc123
---

# Step: implement

Execute wfi://work-on-task workflow.
When complete, report results with: ace-coworker report <file>
```

## Report File Format

Report files contain the agent's response (copied from the submitted file):

```markdown
---
step: implement
step_index: 0
attempt: 1
timestamp: 2026-01-28T01:55:00Z
session_id: abc123
source: /path/to/submitted/report.md
---

[Content copied from submitted report file]
```

## API Integration

### Log Class Usage

```ruby
# Create logger for a session
log = Ace::Coworker::Atoms::EventLogger.new(session_path)

# Log events
log.log(event: "step_started", step: "implement", step_index: 0, attempt: 1)
log.log(event: "delegation_sent", step: "implement", attempt: 1, file: "reports/001-01-implement-delegation.md")

# Read log
events = log.read_all
```

### Delegation Writer Usage

```ruby
# Create delegation file
writer = Ace::Coworker::Molecules::DelegationWriter.new(session_path)
path = writer.write(
  step: "implement",
  step_index: 0,
  attempt: 1,
  instructions: "Execute wfi://work-on-task..."
)
# => "reports/001-01-implement-delegation.md"
```

### Report Storage Usage

```ruby
# Store agent report
storage = Ace::Coworker::Molecules::ReportStorage.new(session_path)
path = storage.store(
  source_file: "/path/to/agent-report.md",
  step: "implement",
  step_index: 0,
  attempt: 1
)
# => "reports/001-01-implement-report.md"
```

## Tips and Best Practices

1. **Log Analysis**: Use `jq` for filtering and analyzing JSONL events
2. **Correlation**: Use `session_id` field to correlate events across sessions
3. **Debugging**: Check delegation files to see exactly what the agent received
4. **History**: Reports directory provides full audit trail of all attempts
5. **Timestamps**: Use ace-support-timestamp for compact, sortable IDs

## Error Handling

### Missing Session Directory

```bash
ace-coworker report file.md
# Error: No active session. Use 'ace-coworker start --task <id>' first.
```

### Report File Not Found

```bash
ace-coworker report /nonexistent/file.md
# Error: Report file not found: /nonexistent/file.md
```

## Dependencies

- ace-support-timestamp: Provides 6-character compact timestamps
- ace-support-core: Base infrastructure
