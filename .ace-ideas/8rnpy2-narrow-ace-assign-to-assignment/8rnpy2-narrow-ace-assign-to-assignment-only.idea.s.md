---
id: 8rnpy2
status: pending
title: Narrow ace-assign to assignment only
tags: []
created_at: "2026-04-24 17:17:51"
---

# Narrow ace-assign to assignment only

## What I Hope to Accomplish
Reduce `ace-assign` scope so it only handles assignment lifecycle concerns. Move any logic for forking, delegating work outside tmux, and agent-to-agent communication into a separate package if needed, so responsibilities are cleaner and easier to verify.

## What "Complete" Looks Like
`ace-assign` contains only assignment-focused behavior and no longer owns orchestration concerns outside that boundary. Any work that coordinates between agents, forks execution, or communicates outside tmux lives in a distinct package with a clearly defined contract.

## Success Criteria
- `ace-assign` only contains assignment-related logic.
- Forking and delegation outside tmux are removed from `ace-assign` or replaced with calls into a separate package.
- Inter-agent communication responsibilities are isolated in a dedicated module/package.
- The package boundaries are documented and easy to verify in code review.
- Existing assignment workflows still work after the split.
