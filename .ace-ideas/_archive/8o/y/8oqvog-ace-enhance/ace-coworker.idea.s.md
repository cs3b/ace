---
title: Implement ace-coworker (single session workflow executor)
enhanced_at: 2026-01-28 00:15
tags:
- ace-coworker
- workflow
- agent-integration
id: 8oqvog
status: done
created_at: '2026-01-27 21:07:09'
---

## Summary

**ace-coworker**: Single session workflow executor (MVP - build first)
**ace-overseer**: Multi-session orchestrator (postponed to backlog)

All 14 questions decided. Ready for task creation.

## The Plan

/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/000-overview.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/001-workflow-executor.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/002-session-management.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/003-agent-integration.md


## Questions (All Decided)

/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/01-scope-and-boundaries.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/02-state-persistence.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/03-orchestration-model.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/04-worker-interface.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/05-agent-agnostic-vs-native.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/06-gate-mechanics.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/07-context-hygiene.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/08-coworker-overseer-boundary.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/09-scope-and-outcome.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/10-session-lifecycle.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/11-failure-modes.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/12-observability.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/13-integration-surface.md
/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/8oqvog-ace-enhance/questions/14-constraints.md

## Key Decisions Summary

| # | Topic | Decision |
|---|-------|----------|
| 1 | Components | Two: ace-coworker (build first) + external workers |
| 2 | State | `.cache/ace-coworker/{timestamp}/` with job.json, log.jsonl, reports/ |
| 3 | Orchestration | Push model, state machine with verifications |
| 4 | Workers | Skills run by agents, simple English context |
| 5 | Agent-agnostic | Independent gem, works with any CLI agent |
| 6 | Gates | Exit on gate, resume via CLI |
| 7 | Context | Step-scoped, workflow-defined |
| 8 | Naming | Flipped: coworker=session, overseer=multi (postponed) |
| 9 | MVP | Workflows/skills/agents (markdown) + CLI |
| 10 | Lifecycle | Manual worktree, coworker creates session |
| 11 | Failures | Per-step config, generous defaults |
| 12 | Observability | job.json + log.jsonl + reports/ |
| 13 | Integration | Simple CLI + file contract |
| 14 | Constraints | Minimal deps, optional taskflow, new gem |

## Future: ace-overseer (Backlog)

When multi-session orchestration is needed:
- Spawn multiple coworkers
- Manage worktrees
- Distribute work across sessions
- Coordinate parallel execution

Create as separate idea/task when ace-coworker is proven.