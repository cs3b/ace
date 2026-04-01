---
id: 8r0se4
title: 8qs-t-x2b-2-canonical-cookbook-examples
type: standard
tags: []
created_at: "2026-04-01 18:55:42"
status: active
---

# 8qs-t-x2b-2-canonical-cookbook-examples

## What Went Well
- The assignment subtree flow successfully sequenced onboarding, task load, planning, implementation, review, verification, release, and retro without manual status edits.
- Forked `work-on-task` completed with clean commit discipline and produced both canonical cookbook examples with explicit provenance and propagation guidance.
- Release packaging for `ace-handbook` was completed in the same run, including version bump, package changelog, root changelog, lockfile refresh, and clean git status.

## What Could Be Improved
- Fork-run terminal sessions stayed open after subtree completion and required manual interruption to close the local TTY handle.
- Pre-commit review fallback (`ace-lint`) surfaced formatting warnings that could have been prevented by running lint auto-fix in the work step before release.
- `ace-task plan --content` stall behavior remains a reliability risk for unattended fork execution and should be reduced at the tool level.

## Key Learnings
- For scoped assignment driving, `ace-assign status --assignment <id>@<root>` is the reliable source of truth when fork-run stream output is quiet.
- In release-minor steps, explicitly scoping the release target avoids accidental package over-selection on long-lived branches with unrelated commits.
- Cookbook tasks benefit from enforcing provenance and propagation sections as first-class acceptance criteria; this keeps examples reusable and avoids project-diary drift.

## Action Items
- Add a fork-session cleanup improvement in `ace-assign` so completed fork-run sessions close cleanly in interactive terminals.
- Add `ace-lint --auto-fix` for cookbook markdown files before pre-commit-review in similar docs-focused task plans.
- Open a follow-up task to harden `ace-task plan --content` against long-hang cases in fork contexts.
