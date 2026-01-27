# Phase 3: Agent Integration

## Goal

Define how agents (Claude Code, Codex CLI, humans) interact with the overseer as "workers."

## Dependency

Requires Phase 1 (Workflow Executor) and Phase 2 (Session Management).

## Scope

**In scope:**
- Worker interface contract
- Agent dispatch mechanism
- Report/status communication
- Claude Code skill integration
- Human-as-worker pattern

**Out of scope:**
- TUI dashboard (separate feature)
- Multi-agent coordination (future)
- Remote/distributed workers (future)

## The Worker Contract

A worker is anything that can:
1. **Receive context** (environment vars, files)
2. **Perform action** (code, test, review)
3. **Report outcome** (exit code, output files)

### Input Contract

Workers receive context via:
- **Environment variables**: `$ACE_TASK`, `$ACE_SESSION`, `$ACE_STEP`, `$ACE_CONTEXT_FILE`
- **Context files**: `.ace/overseer/context.json` (path passed via `$ACE_CONTEXT_FILE`)
- **Working directory**: The session worktree

### Output Contract

Workers report via:
- **Exit code**: 0 = success, non-zero = failure
- **stdout/stderr**: Captured for logging
- **Report file** (optional): `.ace/overseer/step-report.json`

```json
{
  "step": "test",
  "outcome": "failed",
  "summary": "3 tests failed",
  "details": {
    "failed_tests": ["test_auth", "test_login", "test_session"],
    "coverage": 0.85
  },
  "artifacts": [
    "test-reports/results.xml"
  ]
}
```

## Context Hygiene

Workers should receive only the context relevant to the current step. On retries, the overseer should write a fresh
context file that includes the spec, the latest error summary, and any explicitly requested files. Avoid passing
full logs or prior chat history.

## Optional File IO Convention

For richer integrations (agents or enhanced CLI tools), support an optional input/output directory convention:

- Input: `.ace/overseer/steps/<step-id>/input/`
- Output: `.ace/overseer/steps/<step-id>/output/`

This keeps file-based contracts explicit without forcing changes on existing CLI tools.

## Agent Types

### 1. CLI Tool (Simplest)

Any CLI command is a worker:

```yaml
steps:
  - action: ace-test
  - action: ace-lint --fix
  - action: gh pr create
```

### 2. Claude Code Agent

Invoke Claude Code as a worker:

```yaml
steps:
  - worker: claude-code
    prompt: |
      Implement the feature described in the task specification.
      Run tests after implementation.
    timeout: 30m
```

Implementation options:
- **Option A**: Shell out to `claude` CLI
- **Option B**: Skill that reads session state

### 3. Human Worker

Human gates are workers with infinite timeout:

```yaml
steps:
  - worker: human
    prompt: "Review the code changes and approve"
    notify: desktop  # or: slack, email
```

## Role-Specific Workers (Optional Taxonomy)

Some workflows benefit from explicit role separation (Architect, Engineer, Tester) to reduce role confusion.
This can be encoded in prompts or worker names without introducing new schema.

Example: plan -> review -> implement -> test:

```yaml
steps:
  - id: plan
    worker: claude-code
    prompt: "Act as Architect. Produce spec.md with planned changes."

  - id: plan-review
    gate: human
    prompt: "Review spec.md and approve or request changes."

  - id: implement
    worker: claude-code
    prompt: "Act as Engineer. Implement spec.md changes."

  - id: test
    action: ace-test
    on_fail:
      worker: claude-code
      prompt: "Act as Engineer. Fix failing tests from the report."
      max_retries: 3
```

## Coworker Responsibilities (UI Layer)

Coworker is a thin, user-facing layer that manages sessions and approvals. It should:
- Create and list sessions (worktrees).
- Surface status from overseer state files.
- Provide approval/reject actions for human gates.
- Avoid owning workflow execution logic (that stays in overseer).

## Claude Code Integration

### Skill: `/ace:overseer-continue`

```markdown
## ace:overseer-continue

Resume the current overseer workflow as a worker.

1. Read session state from `.ace/overseer/state.json`
2. Identify current step
3. If step.worker == "claude-code", execute the prompt
4. Report outcome via exit code and report file
5. Overseer advances to next step
```

### Workflow for Agent-Driven Steps

```yaml
name: task-with-agent
steps:
  - id: plan
    worker: claude-code
    prompt: "Read task spec and create implementation plan"

  - id: review-plan
    gate: human

  - id: implement
    worker: claude-code
    prompt: "Implement according to the plan"

  - id: test
    action: ace-test
    on_fail:
      worker: claude-code
      prompt: "Fix the failing tests"
      max_retries: 3
```

## The "Action vs Skill" Insight

From the field notes - agents confuse `/ace:commit` (skill) with `ace-git-commit` (action).

**Solution in workflow language:**

```yaml
# This runs a CLI command directly
- action: ace-git-commit --staged

# This invokes an agent with a prompt
- worker: claude-code
  prompt: "Generate a commit message and commit"
```

Clear semantic difference:
- `action:` = deterministic, run exactly this
- `worker:` = delegate to agent, may involve reasoning

## Key Decisions Needed

- [ ] How to invoke Claude Code programmatically (`claude` CLI? API?)
- [ ] Timeout handling for agent workers
- [ ] How to pass rich context to agents (task spec, codebase summary)
- [ ] Notification mechanism for human gates
- [ ] How to handle agent worker failures (retry? escalate?)

## Implementation Notes

### Dispatching to Claude Code

Option A: CLI invocation
```ruby
def dispatch_claude_code(prompt:, timeout:)
  Open3.capture3(
    "claude", "--print", "--message", prompt,
    timeout: timeout
  )
end
```

Option B: Skill-based (agent pulls work)
```markdown
# In Claude Code session
/ace:overseer-continue

# Skill reads state, executes current step, reports back
```

Recommendation: **Start with Option B** - fits existing skill pattern, agent controls execution.

### Worker Registry

Allow custom worker types:

```yaml
# .ace/overseer/workers.yml
workers:
  claude-code:
    command: claude --print --message "$PROMPT"
    timeout: 30m

  codex:
    command: codex --prompt "$PROMPT"
    timeout: 15m

  review-team:
    type: human
    notify: slack
    channel: "#code-review"
```

## Success Criteria

- [ ] CLI actions work as workers (exit code based)
- [ ] Claude Code can be invoked as worker
- [ ] Human gates pause and notify
- [ ] Worker failures are captured and reported
- [ ] Context flows correctly to workers
- [ ] `/ace:overseer-continue` skill works
