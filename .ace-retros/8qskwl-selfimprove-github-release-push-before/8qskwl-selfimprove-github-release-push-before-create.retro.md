---
id: 8qskwl
title: selfimprove-github-release-push-before-create
type: standard
tags: [self-improvement, process-fix, release, github]
created_at: "2026-03-29 13:56:13"
status: active
---

# selfimprove-github-release-push-before-create

## What Went Well

- The failure surfaced immediately with a specific GitHub API validation error instead of silently creating a malformed release.
- RubyGems publishing was already complete and unaffected, so the issue was isolated to the GitHub release workflow.
- Retrying after `git push` confirmed the missing remote commit was the actual blocker.

## What Could Be Improved

- `github/release-publish` finalized `[Unreleased]` into a new versioned changelog commit and then proceeded directly to `gh release create` without ensuring that commit existed on GitHub.
- The workflow lacked an explicit validation checkpoint for remote commit availability before using `--target`.
- The process relied on operator memory to push after local finalization, which is exactly the kind of release-step omission a workflow should prevent.

## Action Items

- Updated `ace-git/handbook/workflow-instructions/github/release-publish.wf.md` to require `git push` immediately after changelog finalization commits created during step 1.5.
- Added live-mode validation guidance to stop and push the missing commit when `gh release create` reports `tag_name is not a valid tag` or `target_commitish is invalid`.
- Keep future GitHub release runs on the workflow path instead of ad-hoc retries so the remote-target precondition is always satisfied before release creation.
