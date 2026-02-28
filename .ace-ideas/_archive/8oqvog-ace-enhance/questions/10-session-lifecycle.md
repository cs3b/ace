# Question: Session Lifecycle

## The Question

Where are sessions created, resumed, and destroyed, and which component owns lifecycle responsibilities?

## Context

We want worktree isolation but must avoid double-ownership between coworker and overseer.

## Prompts

- Who creates the session worktree: coworker or overseer?
- What is the "attach" behavior if multiple sessions exist?
- How do we resume a paused workflow deterministically?
- What is the cleanup policy for completed/abandoned sessions?

## Decision Status

- [x] Decided: **Simplified for MVP**

| Responsibility | Owner |
|----------------|-------|
| Worktree creation | Manual (user) for now. Future ace-overseer. |
| Session creation | ace-coworker (in current directory) |
| Multiple sessions | Supported via `.cache/ace-coworker/{timestamp}/` |
| Resume | `ace-coworker resume` reads state from session dir |
| Cleanup | Manual for now (simple TTL later) |

**Session lifecycle (MVP):**
1. User starts in worktree (or main)
2. `ace-coworker start --task 225` → creates session in .cache/
3. Workflow runs, checkpoints after each step
4. Gate reached → exits, can resume later
5. `ace-coworker resume` → continues from checkpoint
6. Complete → session stays for debugging (manual cleanup)
