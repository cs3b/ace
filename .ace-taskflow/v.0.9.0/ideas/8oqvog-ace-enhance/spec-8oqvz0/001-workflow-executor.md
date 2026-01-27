# Phase 1: Workflow Executor

## Goal

A CLI tool that executes a sequence of steps, checkpoints state after each, and can resume from any point.

## Scope

**In scope:**
- Parse workflow definition (YAML)
- Execute steps sequentially
- Persist state after each step
- Resume from last checkpoint
- Retry logic for failed steps
- Human gates (pause for approval)

**Out of scope (Phase 2+):**
- Worktree management
- Session lifecycle
- Multi-workflow orchestration
- TUI/dashboard

## Interface

```bash
# Run a workflow
ace-overseer run workflow.yml

# Run with task context
ace-overseer run workflow.yml --task 228

# Resume interrupted workflow
ace-overseer resume

# Show current state
ace-overseer status
```

## Workflow Definition Format

```yaml
name: task-completion
description: Complete a task through implementation, testing, and PR

context:
  task: $TASK_ID  # Passed via --task flag

steps:
  - id: implement
    action: ace-git-commit --staged -i "implement task $task"

  - id: test
    action: ace-test
    on_fail: retry
    max_retries: 3

  - id: review-gate
    gate: human
    prompt: "Review implementation before creating PR"

  - id: create-pr
    action: gh pr create --title "Task $task"
    capture: pr_url

  - id: self-review
    action: ace-review --preset code-deep --pr $pr_url
```

## State Persistence

State file: `.ace/overseer/state.json` (or in worktree if Phase 2)

```json
{
  "session_id": "228-abc123",
  "workflow": "task-completion",
  "status": "running",
  "started_at": "2026-01-27T20:00:00Z",
  "current_step": "test",
  "iteration": 2,
  "max_iterations": 5,
  "gate": null,
  "context": {
    "task": "228",
    "pr_url": null
  },
  "steps": [
    { "id": "implement", "status": "completed", "exit_code": 0 },
    { "id": "test", "status": "failed", "exit_code": 1, "retries": 2 }
  ],
  "history": [
    { "timestamp": "2026-01-27T20:00:00Z", "event": "started" },
    { "timestamp": "2026-01-27T20:05:00Z", "step": "implement", "event": "completed" }
  ]
}
```

## Step Execution Model

1. Read state (or initialize if new)
2. Build step-scoped context bundle (spec + needed files + last error)
3. Find current step
4. Execute action via `system()` / `Open3.capture3` (or wait on worker report)
5. Capture exit code, stdout, stderr, optional report
6. Apply on_fail logic (retry, goto, fail)
7. Persist state and append history
8. Next step (or pause at gate)

## Gate Mechanics (Pause/Resume)

When a gate is reached:
- Update state: `status: paused`, `gate: { id, status: "waiting" }`
- Persist state immediately
- Optionally exit the process to avoid idle loops

Approval transitions the gate to `approved` and resumes the workflow. Rejection can rewind to a prior step with
additional feedback context.

## Context Hygiene & Retry Feedback

Workers should only see the minimum required inputs for the current step. On retries, pass the spec and the latest
error summary, not the full prior logs or chat history. This keeps prompts focused and avoids compounding failure
context.

Suggested context path: `.ace/overseer/context.json` (step-scoped and overwritten each run).

## Observability

- Persist stdout/stderr per step in `.ace/overseer/logs/<step>.log`
- Optional step reports in `.ace/overseer/reports/<step>.json`
- `ace-overseer status` should show current step, status, retries, and last error summary

## Key Decisions Needed

- [ ] Workflow file location convention (`.ace/workflows/`? In gem?)
- [ ] State file location (per-directory? Global?)
- [ ] Variable interpolation syntax (`$var` vs `{{ var }}` vs `%{var}`)
- [ ] How to handle long-running actions (timeout?)
- [ ] Gate notification mechanism (stdout? desktop notification? webhook?)
- [ ] Context shaping rules and size budgets for worker prompts

## Implementation Notes

### Gem Structure

```
ace-overseer/
├── lib/ace/overseer/
│   ├── atoms/
│   │   ├── workflow_parser.rb
│   │   └── variable_interpolator.rb
│   ├── molecules/
│   │   ├── step_executor.rb
│   │   └── state_manager.rb
│   ├── organisms/
│   │   └── workflow_runner.rb
│   └── models/
│       ├── workflow.rb
│       ├── step.rb
│       └── session_state.rb
├── .ace-defaults/overseer/
│   └── config.yml
└── handbook/
    └── workflow-instructions/
        └── overseer.wf.md
```

### Minimal First Implementation

1. WorkflowParser - load YAML, validate structure
2. StepExecutor - run single action, return result
3. StateManager - load/save JSON state
4. WorkflowRunner - orchestrate the loop

## Success Criteria

- [ ] Can run a 3-step workflow end-to-end
- [ ] Can resume after manual interruption (Ctrl+C)
- [ ] Can retry failed step automatically
- [ ] Human gate pauses and resumes with explicit approval
- [ ] State file reflects accurate progress and history
- [ ] Step context file is created and overwritten per run
