---
id: 8roifd
title: 8ro-t-0ve-1-watch-startup-retained-e2e
type: standard
tags: []
created_at: "2026-04-25 12:17:05"
status: active
---

# 8ro-t-0ve-1-watch-startup-retained-e2e

## What Went Well
- The stalled subtree was recoverable from assignment reports and retained E2E artifacts without replaying the whole branch history.
- A focused fast regression around `AssignmentExecutor#start` exposed the real startup bug quickly: mapped `sub_steps` overrides were preserved by dynamic batch insertion but dropped during initial YAML assignment creation.
- Package verification was reliable once the scoped worker's live env (`ACE_ASSIGN_DEFAULT_TARGET`, `TMUX`, `ACE_ASSIGN_FORK_WINDOW`) was removed from the test process.

## What Could Be Improved
- Scoped worker environments should not leak assignment or tmux targeting variables into package/E2E verification runs; that pollution produced false failures unrelated to the task.
- Manual fixture reproductions wrote generated `jobs/` artifacts back into the repo fixture tree, which had to be cleaned before release prep.
- The retained E2E harness still mixes real product failures with environment/runtime failures (missing tmux runtime, stale local fixture copies), making TC-level diagnosis slower than necessary.

## Action Items
- Add an explicit clean-env helper or workflow note for subtree verification commands that must ignore worker-scoped assignment/tmux env vars.
- Keep generated retained-fixture job outputs outside tracked fixture directories so local reproductions cannot masquerade as source edits.
- Follow up on the retained watch E2E harness so sandbox-local fixture generation stays aligned with the repo fixtures and current runner guidance.
