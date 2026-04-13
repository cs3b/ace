---
id: 8rbqt5
title: 8r9.t.i05.o ace-tmux migration retrospective
type: standard
tags: [assignment, 8r9.t.i05.o, ace-tmux, migration]
created_at: "2026-04-12 17:52:23"
status: active
---

# 8r9.t.i05.o ace-tmux migration retrospective

## What Went Well
- Completed the `test/* -> test/fast/*` migration for `ace-tmux` with minimal blast radius and immediate green deterministic tests.
- Caught and fixed an E2E setup regression (`$PROJECT_ROOT_PATH/mise.toml`) by switching to `${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}`.
- Identified and corrected TC-003 runner ambiguity (session preset reused as window preset), then confirmed `ace-test-e2e ace-tmux` passed 3/3.
- Kept release flow consistent with sibling subtrees: package version bump, package changelog promotion, root changelog update, and lockfile refresh.

## What Could Be Improved
- `ace-task plan 8r9.t.i05.o` repeatedly stalled with no output after a context warning, requiring manual process kills and fallback to prior plan artifacts.
- Pre-commit review could not use native `/review` in this execution environment; fallback had no files to lint because all work was already committed.
- Task bundle references a directory path (`ace-tmux/test/e2e`) that triggers planner warnings in some contexts; bundle metadata could use explicit file paths.

## Action Items
- Add or refine planner stall detection in task-plan tooling so silent hangs are surfaced and aborted automatically with a clear fallback path.
- Prefer `${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}` in E2E scenario setup examples across packages to reduce sandbox-root coupling.
- Strengthen `ace-tmux` E2E runner guidance to always discover a window preset explicitly before invoking `ace-tmux window`.
