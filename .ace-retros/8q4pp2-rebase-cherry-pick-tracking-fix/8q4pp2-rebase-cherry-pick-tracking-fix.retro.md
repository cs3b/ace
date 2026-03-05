---
id: 8q4pp2
title: rebase-cherry-pick-tracking-fix
type: self-improvement
tags: [process-fix, git, rebase]
created_at: "2026-03-05 17:07:52"
status: active
---

# rebase-cherry-pick-tracking-fix

## What Went Well

- Cherry-pick fallback handled the CHANGELOG conflict correctly
- Session state capture (metadata.yml, commits.txt) enabled clean recovery

## What Could Be Improved

**Issue 1: SHA-based skip in Phase 3.2 never worked**
Cherry-pick produces new SHAs, so `git log --format=%H | grep "^$sha"` never matched.
On resume, all commits were re-applied instead of being skipped.
Fix: use commit subject matching (`git log --format=%s | grep -qF "$subject"`).

**Issue 2: `git branch -m` silently drops upstream tracking**
Phase 3.3 renames the work branch back to the original name, but `git branch -m`
does not preserve the upstream config. The branch ended up with no tracking set,
requiring a manual `git branch --set-upstream-to` after the fact.
Fix: add `git branch --set-upstream-to="origin/${original_branch}"` immediately after rename.

**Issue 3: Phase 5 push didn't guarantee tracking**
Used explicit refspec `HEAD:refs/heads/<name>` without `-u`, so tracking was not
set even if the remote branch matched.
Fix: switch to `git push --force-with-lease -u origin "<branch>"`.

## Action Items

- [x] Fixed Phase 3.2 skip logic to use subject-based matching
- [x] Fixed Phase 3.3 to restore upstream tracking after branch rename
- [x] Fixed Phase 5 push to use `-u` flag
- [x] Updated `last-updated` in workflow frontmatter to 2026-03-05

