# ACE Overseer: High-Level Overview

## The Problem

Today, orchestrating multi-step agent workflows requires **manual copy-paste** of instruction sequences. Agents lose context between sessions, can't resume from failures, and have no shared state across steps.

The 8-step workflow pattern (work → commit → PR → review → fix → test → repeat) is executed manually, with humans serving as the orchestration layer.

## Where Is The Value

| Pain Point | Impact | Solution Target |
|------------|--------|-----------------|
| Context loss between sessions | Agents restart from scratch | Persistent session state |
| No checkpoint/resume | Failures require full restart | Step-based checkpointing |
| Manual "what next" decisions | Human bottleneck | Declarative workflow definitions |
| Skill vs action confusion | Agents over-analyze | Imperative action language |

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

## What This Is NOT

- **Not a job scheduler** (cron, Sidekiq) - this is interactive, session-based
- **Not an agent framework** (LangChain, AutoGPT) - agents are workers, not the orchestrator
- **Not a CI/CD system** (GitHub Actions) - this runs locally, human-in-loop

## Phases

1. **Workflow Executor** (001) - Core value: run steps, checkpoint, resume
2. **Session Management** (002) - Worktree isolation, session lifecycle
3. **Agent Integration** (003) - Worker interface, Claude Code integration

## Open Questions

See `questions/` for detailed analysis of each decision point.

## References

- Original idea: `../implement-ace-overseer-functionality.idea.s.md`
- Field notes: `../notes-from-running-long-sequence-of-high-level-instructions.md`
