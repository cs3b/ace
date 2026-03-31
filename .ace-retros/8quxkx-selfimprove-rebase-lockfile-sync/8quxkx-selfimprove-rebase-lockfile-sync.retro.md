---
id: 8quxkx
title: selfimprove-rebase-lockfile-sync
type: standard
tags: [self-improvement, process-fix]
created_at: "2026-03-31 22:23:16"
status: active
---

# selfimprove-rebase-lockfile-sync

## Root Cause

**Category**: Missing validation

During rebase of branch `zoz-roles-first-llm-configuration-rollout` onto `origin/main`, version.rb conflicts were resolved across multiple gems. The rebase workflow had no step to regenerate `Gemfile.lock` via `bundle install` after version changes, leaving the lockfile stale (16 version entries out of sync).

The `wfi://release/bump-version` workflow already handles this correctly (Step 5: "Update Gemfile.lock"), but the rebase workflow assumed lockfile consistency survives conflict resolution — it doesn't in a mono-repo where multiple gem versions change.

## What Went Well

- The rebase itself completed cleanly with all 19 commits replayed and commit count verified.
- The `bump-version` workflow already had the correct pattern to follow.

## What Could Be Improved

- The rebase workflow lacked a lockfile sync step between verification and push.
- Taking `Gemfile.lock` via `git checkout --theirs` during conflict resolution compounds the problem — main's lockfile won't have branch gem versions.

## Process Fix Applied

**File**: `ace-git/handbook/workflow-instructions/git/rebase.wf.md`
**Change**: Added a "Sync lockfile after version changes" block at the top of Phase 5 (Push Changes) that runs `bundle install` and commits `Gemfile.lock` if changed. This runs before tests, so stale lockfile issues surface as test failures rather than silent drift.

## Action Items

- [x] Updated rebase workflow with Gemfile.lock sync step
- [x] Committed synced Gemfile.lock for current rebase

