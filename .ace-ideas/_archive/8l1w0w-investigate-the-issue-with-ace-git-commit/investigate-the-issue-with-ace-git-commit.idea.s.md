---
status: done
completed_at: 2025-11-01 19:26:39.000000000 +00:00
id: 8l1w0w
title: Idea
tags: []
created_at: '2025-10-02 21:20:59'
---

# Idea

Investigate the issue with ace-git-commit \
The issue was that ace-git-commit reported "Staging all changes" but didnt actually stage the unstaged files,
   resulting in "No changes to commit."

  Heres what happened:

  1. First attempt (ace-git-commit -i "..." -d):
    - Tool said "Staging all changes"
    - But then reported "No changes to commit"
    - The changes were still unstaged (they were "not staged for commit")
  2. Second attempt (git add -A && ace-git-commit -i "..."):
    - Manually staged with git add -A
    - Tool returned just "Error" (not very helpful)
    - But the commit actually succeeded (branch went from 19 to 20 commits ahead)
  3. Third attempt (git add -A && ace-git-commit -i "..." -d):
    - Tried to stage again, but everything was already committed
    - "No changes to commit" (correctly this time)

  The bug: Despite setting only_staged: false (which should stage all changes automatically), ace-git-commit
  didnt actually stage the unstaged files. It only reported that it was doing so.

  The workaround that succeeded was manually running git add -A first, though the error reporting was misleading
   (it succeeded but said "Error").

---
Captured: 2025-10-02 22:21:33