# Question: Scope & Outcome (v0.9.0)

## The Question

What is the smallest overseer capability targeted for v0.9.0, and what is explicitly out of scope?

## Context

Multiple phases and components are possible. We need a crisp "minimal useful" definition to avoid overbuilding.

## Prompts

- Which single workflow should v0.9.0 support end-to-end?
- Is human gating included in the MVP or deferred?
- Are sessions/worktrees required for v0.9.0, or can it run in the current repo?
- Is agent integration required or optional?

## Decision Status

- [x] Decided: **Agent-first MVP**

**How it works:**
- Agent is the driver: `claude '/ace:coworker-do work on task 225'`
- ace-coworker provides workflows/skills/CLI that agents use
- `ace-coworker start` = start agent with proper workflows/skills for the agent type

**MVP deliverables:**
- Agents (markdown files)
- Workflows (markdown/yaml files)
- Skills (markdown files)
- Supportive CLI

**Core competencies to master:**
- Delegations (pass work to sub-agents)
- Verifications (check step success)
- Reporting (track what happened)
→ Run with confidence

**First workflow:** Full task completion cycle
```
work → commit → test → release → pr → review → apply feedback → update pr/changelog
```

**Out of scope for MVP:**
- Worktree management (start manually, future ace-overseer territory)
- Multi-session orchestration (ace-overseer, postponed)
