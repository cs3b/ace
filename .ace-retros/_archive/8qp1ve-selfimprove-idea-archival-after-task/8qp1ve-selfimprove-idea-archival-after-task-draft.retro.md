---
id: 8qp1ve
title: selfimprove-idea-archival-after-task-draft
type: self-improvement
tags: [process-fix]
created_at: "2026-03-26 01:14:53"
status: active
---

# selfimprove-idea-archival-after-task-draft

## Root Cause Analysis

**What happened:** After creating task `8qp.t.1fn` from ideas `8qmowi` and `8qmpfo`, agent ran `ace-idea update <id> --set status=done` but omitted `--move-to archive`. Ideas got status `done` but remained in active folder.

**Root cause category:** Scope narrowing — agent followed the "mark done" part but missed the "move to archive" part. The compressed bundle format collapsed the exact CLI syntax (`--set status=done --move-to archive`) into keyword tokens, making it easy to execute only half the operation.

**Source:** `ace-task/handbook/workflow-instructions/task/draft.wf.md` line 207

## What Went Well

- The workflow instruction was already correct and explicit in the uncompressed source
- `ace-idea update --move-to archive` worked cleanly when run

## What Could Be Improved

- The validation checkpoint on line 218 said "All source idea files marked as done and moved to _archive/" but provided no verification command to catch the mistake

## Process Fix Applied

**File:** `ace-task/handbook/workflow-instructions/task/draft.wf.md`
**Change:** Added verification command to validation checkpoint:
```
- [ ] All source idea files marked as done and moved to _archive/ — verify: `ace-idea list --status done` should return zero results (done ideas must be in archive, not active)
```
**Commit:** `34f9b692a`

## Immediate Fix Applied

- Archived both ideas: `ace-idea update 8qmowi --move-to archive` and `ace-idea update 8qmpfo --move-to archive`
- Verified: `ace-idea list --status done` returns zero results
- **Commit:** `e75ea0541`

## Action Items

- [x] Add verification command to draft workflow validation checkpoint
- [x] Archive the two source ideas
- [x] Commit both fixes

