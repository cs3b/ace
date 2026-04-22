---
id: 8rlkf7
title: selfimprove-github-issue-task-linking
type: standard
tags: [self-improvement, process-fix]
created_at: "2026-04-22 13:36:53"
status: active
---

# selfimprove-github-issue-task-linking

## What Went Well

- The user caught the missing `--github-issue` linkage before implementation work started.
- The existing `ace-task` CLI and docs already had the correct create-time option and issue lifecycle model.
- The immediate task could be repaired with `ace-task update 8rl.t.k5a --set github_issue=298` and `ace-task github-sync 8rl.t.k5a`.

## What Could Be Improved

- The task draft workflow showed generic `ace-task create` examples that omitted the documented `--github-issue` option.
- I treated the GitHub issue URL only as source context instead of also extracting the issue number for task lifecycle metadata.
- The workflow lacked a validation checkpoint requiring `github_issue` frontmatter and GitHub sync when drafting from a GitHub issue URL.

## Action Items

- Updated `ace-task/handbook/workflow-instructions/task/draft.wf.md` so GitHub issue URL inputs require `--github-issue <number>` on the parent or single task create command.
- Added a draft workflow completion check for `github_issue` frontmatter and `ace-task github-sync <ref>`.
- Added an `ace-task` changelog entry describing the process fix.
