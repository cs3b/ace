---
id: 8r1fig
status: pending
title: "ace-mayor: Tmux-based Agent Observability & Orchestration"
tags: []
created_at: "2026-04-02 10:20:31"
---

# ace-mayor: Tmux-based Agent Observability & Orchestration

## What I Hope to Accomplish
Establish `ace-mayor` as a high-level orchestrator that leverages `ace-tmux` to provide "ultimate observability" over parallel agent activities. By reading terminal buffers and tracking recent changes across multiple panes, the system will monitor autonomous workflows in real-time, allowing for better coordination, faster intervention, and a centralized "command center" for complex assignments.

## What "Complete" Looks Like
A functional `ace-mayor` utility that can inspect all active tmux panes within a session, identifying which agents are running in specific worktrees. It provides a unified view merging `ace-git` status, task/assignment progress, and live terminal output deltas (e.g., changes in the last 15 seconds), with the ability to programmatically fork new assignment tasks into dedicated tmux panes.

## Success Criteria
- `ace-mayor` successfully retrieves and parses the last 15 seconds of terminal activity from any `ace-tmux` pane.
- The system provides a unified dashboard showing git status and task state for all active worktrees.
- New assignment forks can be programmatically launched into dedicated, named tmux panes.
- The orchestrator can detect and report on agent progress by analyzing pane activity over a rolling time window.
