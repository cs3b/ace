# Phase 3: Agent Integration (ace-coworker)

## Goal

Define how agents (Claude Code, Codex CLI, OpenCode, humans) interact with ace-coworker as workers.

## Key Insight: Agent is the Driver

The agent invokes `/ace:coworker-do <task>`. ace-coworker provides workflows/skills/CLI that agents use.
The CLI manages state; the agent executes steps.

```
User runs: claude '/ace:coworker-do work on task 225'
    │
    ▼
Agent loads skill → reads workflow → calls ace-coworker CLI
    │
    ▼
ace-coworker manages state (job.json, logs, reports)
    │
    ▼
Agent executes steps, reports back
```

## The Worker Model

A worker is a **skill run by an agent**. Workers receive:
- Simple English context (not complex protocols)
- Instructions (usually `ace-bundle wfi://...`)
- Last error (on retry)

Workers produce:
- Reports (markdown files stored in reports/)
- Verification outcomes

## Context Format (Plain English)

```
We work on: Task 228 - implement feature X

Current step is: test

Your instructions: ace-bundle wfi://run-tests

Previous attempt failed: 3 tests failed (test_a, test_b, test_c)
```

No JSON context files. No environment variable protocols. Just plain English that any agent can understand.

## Communication Style

| Type | Format | Example |
|------|--------|---------|
| Delegation | Plain English | "Your instructions: ace-bundle wfi://work-on-task 228" |
| Reports | Markdown | `reports/001-implement-report.md` |
| Hard data | JSONL | `log.jsonl` events |
| Status | JSON | `ace-coworker status --json` |

## Agent Types

### 1. Claude Code

```bash
# User invokes skill
claude '/ace:coworker-do work on task 228'

# Skill loads workflow, manages execution
# Agent runs steps, calls ace-coworker CLI for state
```

Skill file: `.claude/skills/ace_coworker/SKILL.md`

### 2. Codex CLI

Same pattern - skill/workflow file adapted for Codex prompting style.

### 3. OpenCode / Gemini CLI / Others

Any agent that can:
- Run CLI commands
- Read files
- Follow instructions

...can use ace-coworker. The workflow files are agent-agnostic.

### 4. Human Worker

Human gates are just steps where a human is the worker:

```yaml
steps:
  - name: review-gate
    gate: human
    prompt: "Review the code changes and approve"
```

Gate pauses workflow, human reviews, then:
```bash
ace-coworker resume --approve
# or
ace-coworker resume --reject --reason "Need to fix X"
```

## Skill Structure

Thin wrapper that loads the workflow and manages execution:

```markdown
# /ace:coworker-do

## Parameters
- task: Task ID to work on
- workflow: Workflow name (default: task-completion)

## Instructions

1. Start or resume session:
   \`ace-coworker start --task $task --workflow $workflow\`

2. Read current status:
   \`ace-coworker status --json\`

3. For each step:
   - Read step instructions from status
   - Execute the instructions
   - Store report: \`ace-coworker report <file>\`
   - Check verifications

4. If gate reached:
   - Notify user
   - Exit (workflow paused)

5. If complete:
   - Report final status
```

## Workflow Files

Workflows live in:
- `ace-coworker/handbook/workflow-instructions/` (defaults)
- `.ace/coworker/workflows/` (project overrides)

Example: `task-completion.wf.yml`

```yaml
name: task-completion
description: Complete a task through implementation, testing, and PR

steps:
  - name: implement
    context: "Task $task"
    instructions: ace-bundle wfi://work-on-task $task
    verifications:
      - ace-test passes
    retries: 5

  - name: commit
    instructions: ace-bundle wfi://commit

  - name: test
    instructions: ace-test
    retries: 5

  - name: review-gate
    gate: human
    prompt: "Review before PR"

  - name: create-pr
    instructions: ace-bundle wfi://create-pr

  - name: self-review
    instructions: ace-bundle wfi://review-pr

  - name: apply-feedback
    instructions: ace-bundle wfi://apply-feedback
    verifications:
      - ace-test passes

  - name: update-pr
    instructions: ace-bundle wfi://update-pr
```

## The "Action vs Skill" Clarity

From field notes - agents confuse `/ace:commit` (skill) with `ace-git-commit` (CLI).

**In workflow language:**

```yaml
# Deterministic CLI command
- name: test
  instructions: ace-test

# Agent skill (involves reasoning)
- name: implement
  instructions: ace-bundle wfi://work-on-task $task
```

Both are "instructions" - the workflow doesn't distinguish. The difference is in what the instruction does:
- `ace-test` → runs directly, returns exit code
- `ace-bundle wfi://...` → loads workflow for agent to follow

## Verification Mechanism

Each step can have verifications:

```yaml
verifications:
  - ace-test passes
  - no lint errors
  - commit created
```

Verifications are checked after step completion:
- Run verification commands
- Parse output
- Pass → advance to next step
- Fail → retry or stop based on config

## Reporting

Every delegation and result is logged:

```
reports/
├── 001-implement-delegation.md   # What we asked
├── 001-implement-report.md       # What came back
├── 002-test-delegation.md
├── 002-test-report.md            # Test results
└── ...
```

This creates an audit trail for debugging (by humans or agents).

## Agent-Agnostic Design

ace-coworker follows the established ace-* pattern:
- CLI tool (`exe/ace-coworker`)
- handbook/ (workflows, agents, guides)
- config (`.ace-defaults/`, `.ace/` cascade)
- Works standalone without any agent

**Philosophy:** Don't optimize FOR Claude Code → make sure it WORKS WITH Claude Code.

Integration is separate and thin. Core gem has zero Claude Code dependencies.

## Success Criteria

- [ ] Claude Code skill works end-to-end
- [ ] Workflow files are agent-agnostic
- [ ] Plain English context works for all agent types
- [ ] Reports are stored and readable
- [ ] Verifications run after each step
- [ ] Human gates pause and resume correctly
- [ ] Same workflows work with different agents
