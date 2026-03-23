---
id: 8qmykd
status: pending
title: Show stats footer in ace-task list when empty
tags: []
created_at: "2026-03-23 23:02:38"
---

# Show stats footer in ace-task list when empty

## What I Hope to Accomplish
Improve user experience consistency by ensuring that `ace-task list` always provides feedback about the state of the task list, even when no tasks are present. This mirrors the behavior of `ace-idea list` and confirms the command executed successfully against an empty set rather than just returning no output.

## What "Complete" Looks Like
When executing `ace-task list` in a workspace with no tasks, the CLI displays a summary footer (e.g., "0 tasks") instead of a completely empty output or just a header.

## Success Criteria
- Running `ace-task list` with no tasks displays a footer with statistics.
- The footer formatting matches the existing `ace-task list` footer style used for non-empty lists.
- The behavior is consistent with `ace-idea list` footer visibility.
