---
source: taskflow:v.0.9.0
id: 8nrjmi
status: pending
title: Idea
tags: []
created_at: '2025-12-28 13:05:00'
---

# Idea

Track agent-modified files for ace:commit - Use Claude Code PostToolUse hooks to track files modified by Edit/Write/Bash tools, store in .claude/sessions/<session-id>/modified-files.txt, then ace-git-commit --session reads that list to commit only agent-touched files. Prevents accidental commits/checkouts of other agents' work. See GitHub issue #9550 and GitButler's approach.

---
Captured: 2025-12-28 13:05:35