# ACE Overseer: High-Level Overview

## Core Value Proposition

ACE Overseer addresses three recurring failures in agentic workflows:
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
- Be incremental: Phase 1 is useful on its own, Phases 2-3 add sessions and agents.

## Non-Goals

- Not a job scheduler (cron, Sidekiq) - this is interactive and session-based.
- Not an agent framework (LangChain, AutoGPT) - agents are workers, not orchestrators.
- Not a CI/CD system (GitHub Actions) - this runs locally with human-in-loop gates.
- Not a full TUI/dashboard in Phase 1 (optional future layer).

## Core Concepts

- **Workflow**: a YAML file that lists steps in order.
- **Step types**:
  - `action`: run a deterministic CLI command.
  - `worker`: delegate to an agent or human with a prompt.
  - `gate`: pause and wait for human approval.
- **Session** (Phase 2): worktree + state + workflow, isolated from the main repo.
- **Context bundle**: minimal, step-scoped inputs (spec + errors), not full chat history.

## Target Architecture (Three Components)

Long-term, the system separates concerns cleanly:

1. **Coworker (Office/UI)**: session lifecycle + user interaction.
2. **Overseer (Supervisor)**: state machine and workflow execution.
3. **Workers (Hands)**: CLI tools, agents, or humans that perform steps.

This keeps the CLI-first core intact while allowing a thin UI/command layer for human gates and session control.
Phase 1-3 can still be built incrementally, but the design should preserve this separation.

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
# Start a workflow for a task
ace-overseer start --task 228 --workflow task-completion

# Check status
ace-overseer status

# Resume after interruption (agent crash, human gate, etc.)
ace-overseer resume
```

The workflow file defines the steps imperatively:

```yaml
name: task-completion
steps:
  - action: ace-git-commit --staged
  - action: ace-test
    on_fail: retry 3
  - gate: human
    prompt: "Review code before PR"
  - action: gh pr create
```

This same workflow language can encode the higher-level sequence (plan -> review gate -> implement -> test -> review)
without hard-coding phases into the engine.

## Context Hygiene (Non-Negotiable)

Workers should receive only the inputs they need for the current step. On retries, pass the spec and the latest
error summary, not the entire prior conversation. This prevents context pollution and keeps responses focused.

## Phases

1. **Workflow Executor** (001) - Core value: run steps, checkpoint, resume
2. **Session Management** (002) - Worktree isolation, session lifecycle
3. **Agent Integration** (003) - Worker interface, Claude Code integration

## Open Questions

See `questions/` for detailed analysis of each decision point.

## References

- Original idea: `../implement-ace-overseer-functionality.idea.s.md`
- Field notes: `../notes-from-running-long-sequence-of-high-level-instructions.md`
