# Post-HITL source integration verification — 2026-10-05

Source revision: 9f2aaf75dbbe0738809064f6ce8063c6f06628d7 (reviewed vs2 merge
0d9590097). During this run only task metadata/review records changed on main,
through e35074c42; no source/package configuration changed.

Executed `bin/ace-test-suite --parallel 2`, root session 16456, exit 0:
- 51 configured package entries passed, zero failed; ace-lab is listed twice
  in existing configuration, so this is not a claim of 51 unique gems.
- 11,161 tests, 33,859 assertions passed; 24 skips.
- Duration 188.73 seconds; unchanged default per-package timeout.
- Assign fast target: 786 tests / 2,885 assertions, 109.93 seconds.

Skipped entries: ace-lab 1 twice; ace-bundle 1; ace-git-worktree 17;
ace-prompt-prep 1; ace-support-test-helpers 1; ace-task 2.

This deterministic source suite does not substitute for installed Lab users,
native Codex/Pi observation, cross-UID policy, Telegram or end-to-end receipt
acceptance. It predates the pending journal primitive integration and qjz/09j
implementation. No gem release or whole-program completion is claimed.
