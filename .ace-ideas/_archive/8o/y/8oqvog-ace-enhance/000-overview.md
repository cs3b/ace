---
status: done
completed_at: 2026-01-28T01:24:11+00:00
---

# ACE Coworker: High-Level Overview

## Naming Clarification

| Component | Role | Status |
|-----------|------|--------|
| **ace-coworker** | Single session workflow executor | Build first (MVP) |
| **ace-overseer** | Multi-session orchestrator | Postponed (backlog) |

This matches natural meaning: an overseer supervises multiple coworkers.

## Core Value Proposition

ACE Coworker addresses three recurring failures in agentic workflows:
- **Context pollution**: a failure in step 5 contaminates step 6.
- **Lost state**: crashes or pauses force a full restart.
- **Role confusion**: one agent acts as architect, engineer, and tester in the same thread.

The value unlocked is reliability (resume and retry cleanly), quality (specialized workers with scoped context),
and observability (state and reports live in files, not chat logs).

## The Problem

Today, orchestrating multi-step agent workflows requires **manual copy-paste** of instruction sequences. Agents lose context between sessions, can't resume from failures, and have no shared state across steps.

The 8-step workflow pattern (work → commit → PR → review → fix → test → repeat) is executed manually, with humans serving as the orchestration layer.

## Goals

- Deliver a workflow executor with checkpoint/resume and human gates.
- Keep it CLI-first and agent-agnostic; workflows and state are file-based.
- Preserve clean context between steps and retries.
- Follow established ace-* patterns (handbook, config cascade, minimal deps).

## Non-Goals

- Not a job scheduler (cron, Sidekiq) - this is interactive and session-based.
- Not an agent framework (LangChain, AutoGPT) - agents are workers, not orchestrators.
- Not a CI/CD system (GitHub Actions) - this runs locally with human-in-loop gates.
- Not a worktree manager (ace-coworker works in current directory; future ace-overseer handles worktrees).

## Core Concepts

- **Workflow**: a YAML/markdown file that lists steps in order.
- **Step types**:
  - `action`: run a deterministic CLI command.
  - `worker`: delegate to an agent with a prompt/skill.
  - `gate`: pause and wait for human approval.
- **Session**: state + workflow in `.cache/ace-coworker/{timestamp}/`
- **Context bundle**: minimal, step-scoped inputs (spec + errors), not full chat history.

## Architecture

```
Agent (Claude Code / Codex / OpenCode)
    │
    │ invokes /ace:coworker-do <task>
    ▼
ace-coworker (CLI)
    ├── job.json       # plan + execution status
    ├── log.jsonl      # event log
    └── reports/       # delegation docs + returned reports
    │
    ▼
Workers (skills run by agent, CLI tools, humans)
```

**Key insight**: Agent is the driver. ace-coworker provides workflows/skills/CLI that agents use.

## Where Is The Value

| Pain Point | Impact | Solution Target |
|------------|--------|-----------------|
| Context loss between sessions | Agents restart from scratch | Persistent session state |
| No checkpoint/resume | Failures require full restart | Step-based checkpointing |
| Manual "what next" decisions | Human bottleneck | Declarative workflow definitions |
| Skill vs action confusion | Agents over-analyze | Imperative action language |
| Role confusion across phases | Blended responsibilities | Role-specific workers + clean context |

**80% of value** comes from: a simple workflow executor that runs steps, checkpoints after each, and can resume.

## Final Outcome

A developer or agent can:

```bash
# Start a workflow for a task (auto-resumes if session exists)
ace-coworker start --task 228 --workflow task-completion

# Check status
ace-coworker status

# Resume after interruption (agent crash, human gate, etc.)
ace-coworker resume

# List all sessions
ace-coworker list
```

The workflow file defines the steps:

```yaml
name: task-completion
steps:
  - name: implement
    instructions: ace-bundle wfi://work-on-task $task
    verifications:
      - ace-test passes

  - name: commit
    instructions: ace-bundle wfi://commit

  - name: review-gate
    gate: human
    prompt: "Review code before PR"

  - name: create-pr
    instructions: ace-bundle wfi://create-pr
```

## Context Hygiene (Non-Negotiable)

Workers receive only the inputs they need for the current step. On retries, pass the spec and the latest
error summary, not the entire prior conversation. This prevents context pollution and keeps responses focused.

## MVP Deliverables

1. **Agents** (markdown files) - single-purpose, composable
2. **Workflows** (markdown/yaml files) - self-contained step sequences
3. **Skills** (markdown files) - thin wrappers for Claude Code integration
4. **Supportive CLI** - state management, status, resume

**Core competencies to master:**
- Delegations (pass work to sub-agents)
- Verifications (check step success)
- Reporting (track what happened)
→ Run with confidence

## First Workflow

Full task completion cycle:
```
work → commit → test → release → pr → review → apply feedback → update pr/changelog
```

## Open Questions

See `questions/` for detailed analysis of each decision point (all 14 decided).

## Future: ace-overseer

When we need multi-session orchestration:
- Spawn multiple coworkers
- Manage worktrees
- Distribute work across sessions
- Coordinate parallel execution

This is explicitly postponed until ace-coworker is proven.
