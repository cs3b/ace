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

- [ ] Pending discussion
- [ ] Decided: _____________
