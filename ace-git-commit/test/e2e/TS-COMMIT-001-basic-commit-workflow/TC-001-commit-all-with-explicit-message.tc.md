---
tc-id: TC-001
title: Commit All Changes with Explicit Message
mode: goal
---

## Objective

Verify that ace-git-commit commits all staged changes with a provided message (bypasses LLM).

## Available Tools

- `ace-git-commit`
- `git`
- standard shell tools

## Success Criteria

- Exit code: 0
- Commit created with message "Add stop and debug methods"
- Both app.rb and helper.rb appear in commit
- Working directory shows no pending changes

## Hints

- Stage concrete file changes first, then run `ace-git-commit -m ...`.
- Verify with both `git log --oneline -1` and `git show --stat HEAD`.
