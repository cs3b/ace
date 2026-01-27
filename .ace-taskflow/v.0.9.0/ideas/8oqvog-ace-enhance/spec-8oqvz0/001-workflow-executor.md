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
  "workflow": "task-completion",
  "started_at": "2026-01-27T20:00:00Z",
  "current_step": 2,
  "context": {
    "task": "228",
    "pr_url": null
  },
  "steps": [
    { "id": "implement", "status": "completed", "exit_code": 0 },
    { "id": "test", "status": "failed", "exit_code": 1, "retries": 2 }
  ]
}
```

## Step Execution Model

1. Read state (or initialize if new)
2. Find current step
3. Execute action via `system()` / `Open3.capture3`
4. Capture exit code, stdout, stderr
5. Apply on_fail logic (retry, goto, fail)
6. Persist state
7. Next step (or pause at gate)

## Key Decisions Needed

- [ ] Workflow file location convention (`.ace/workflows/`? In gem?)
- [ ] State file location (per-directory? Global?)
- [ ] Variable interpolation syntax (`$var` vs `{{ var }}` vs `%{var}`)
- [ ] How to handle long-running actions (timeout?)
- [ ] Gate notification mechanism (just stdout? Desktop notification?)

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
- [ ] Human gate pauses and waits for signal
- [ ] State file reflects accurate progress
