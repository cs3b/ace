# Phase 1: Workflow Executor (ace-coworker core)

## Goal

A CLI tool that executes a sequence of steps, checkpoints state after each, and can resume from any point.
Agent-driven: the agent invokes `/ace:coworker-do`, CLI manages state.

## Scope

**In scope:**
- Parse workflow definition (YAML/markdown)
- Execute steps sequentially (push model)
- Persist state after each step (job.json)
- Resume from last checkpoint
- Retry logic with configurable limits
- Human gates (pause for approval)
- Verifications per step
- Logging (JSONL + markdown reports)

**Out of scope:**
- Worktree management (manual, or future ace-overseer)
- Multi-session orchestration (future ace-overseer)
- TUI/dashboard

## CLI Interface

```bash
# Start workflow (auto-resumes if session exists for task)
ace-coworker start --task 228 --workflow task-completion

# Check status
ace-coworker status [--session <id>] [--json]

# Resume after interruption
ace-coworker resume [--session <id>]

# Store report/artifact
ace-coworker report <file>

# List sessions
ace-coworker list
```

## Workflow Definition Format

```yaml
name: task-completion
description: Complete a task through implementation, testing, and PR

steps:
  - name: implement
    context: "Task $task - implement the feature"
    instructions: ace-bundle wfi://work-on-task $task
    report: summary of changes made
    verifications:
      - ace-test passes
      - no lint errors
    retries: 5
    timeout: 30m
    on_repeated_failure: 3
    restart_hint: "Focus on one failing test at a time"

  - name: commit
    instructions: ace-bundle wfi://commit
    verifications:
      - commit created

  - name: test
    instructions: ace-test
    retries: 5
    on_repeated_failure: 3

  - name: review-gate
    gate: human
    prompt: "Review implementation before creating PR"

  - name: create-pr
    instructions: ace-bundle wfi://create-pr
    report: PR URL and summary
```

## Session Files

Location: `.cache/ace-coworker/{ace-timestamp}/`

```
.cache/ace-coworker/8or5kx/
├── job.json       # plan + execution status
├── log.jsonl      # event log (all steps, all events)
└── reports/       # delegation docs + returned reports
    ├── 001-implement-delegation.md
    ├── 001-implement-report.md
    ├── 002-commit-delegation.md
    └── ...
```

### job.json

```json
{
  "session_id": "8or5kx",
  "task": "228",
  "workflow": "task-completion",
  "status": "running",
  "started_at": "2026-01-27T20:00:00Z",
  "current_step": "test",
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
    }
  ]
}
```

### log.jsonl

One JSON object per line:

```jsonl
{"ts":"2026-01-27T20:00:00Z","event":"session_started","task":"228","workflow":"task-completion"}
{"ts":"2026-01-27T20:00:01Z","event":"step_started","step":"implement"}
{"ts":"2026-01-27T20:15:00Z","event":"step_completed","step":"implement","attempts":1}
{"ts":"2026-01-27T20:15:01Z","event":"step_started","step":"test"}
{"ts":"2026-01-27T20:16:00Z","event":"step_failed","step":"test","error":"3 tests failed"}
{"ts":"2026-01-27T20:16:01Z","event":"step_retry","step":"test","attempt":2}
```

## Step Execution Model (Push)

1. Read job.json (or initialize if new)
2. Find current step from workflow
3. Build step context (plain English):
   ```
   We work on: Task 228 - implement feature X
   Current step is: test
   Your instructions: ace-bundle wfi://run-tests
   Last error: 3 tests failed (test_a, test_b, test_c)
   ```
4. Log delegation to reports/
5. Execute (agent runs the skill/action)
6. Capture outcome (report file)
7. Run verifications
8. If failed: check retry logic, update job.json
9. If passed: advance to next step
10. If gate: write status, exit process, wait for resume

## Gate Mechanics

When a gate is reached:
- Update job.json: `status: "paused"`, `gate: { prompt: "...", waiting: true }`
- Log gate question to log.jsonl (for recovery after crashes)
- Exit the process

Resume:
```bash
ace-coworker resume --approve
ace-coworker resume --reject --reason "Need to fix X first"
```

## Failure Handling

| Failure Type | Behavior |
|--------------|----------|
| Verification failed / missing report | Retry (up to `retries`, default 5) |
| Same error repeated | Stop after `on_repeated_failure` (default 3) |
| Crash / unknown | Log, allow manual resume |

Track all failures in log.jsonl to detect patterns.

## Observability

**`ace-coworker status` output:**
```
Session: 8or5kx (Task 228)
Workflow: task-completion
Status: running

Progress: 3/5 steps
Current: test (attempt 2/5)
Last error: 3 tests failed

Logs: .cache/ace-coworker/8or5kx/log.jsonl
Reports: .cache/ace-coworker/8or5kx/reports/
```

**`ace-coworker status --json`** for machine-readable output.

## Gem Structure

```
ace-coworker/
├── lib/ace/coworker/
│   ├── atoms/
│   │   ├── workflow_parser.rb
│   │   └── variable_interpolator.rb
│   ├── molecules/
│   │   ├── step_executor.rb
│   │   ├── job_manager.rb
│   │   └── log_writer.rb
│   ├── organisms/
│   │   └── workflow_runner.rb
│   └── models/
│       ├── workflow.rb
│       ├── step.rb
│       └── job.rb
├── .ace-defaults/coworker/
│   └── config.yml
├── handbook/
│   ├── agents/
│   ├── workflow-instructions/
│   └── guides/
├── exe/ace-coworker
├── CHANGELOG.md
└── ace-coworker.gemspec
```

## Success Criteria

- [ ] Can run a multi-step workflow end-to-end
- [ ] Can resume after manual interruption (Ctrl+C)
- [ ] Can resume after agent crash (state preserved)
- [ ] Can retry failed step automatically
- [ ] Detects repeated failures and stops
- [ ] Human gate pauses and resumes with explicit approval
- [ ] job.json reflects accurate progress
- [ ] log.jsonl captures all events
- [ ] reports/ contains delegation and result docs
- [ ] `ace-coworker status` shows current state
- [ ] `ace-coworker start --task X` auto-resumes if session exists
