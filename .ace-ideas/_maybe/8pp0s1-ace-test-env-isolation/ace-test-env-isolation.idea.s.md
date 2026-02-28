---

id: 8pp0s1
status: pending
title: Idea
tags: []
created_at: "2026-02-28 17:37:36"
source: "user"
---

# Idea

`ace-test` subprocess runners inherit the full parent process environment, including `ACE_ASSIGN_ID` and `ACE_ASSIGN_FORK_ROOT`. When tests run inside an active assignment fork session, these vars change assignment resolution behavior — causing tests that reference `Ace::Assign` to fail or behave differently than they would in a clean environment.

Observed in PR #216 task 281.04: `ace-test ace-assign` failed because `ACE_ASSIGN_ID=8posmc` was set. Workaround was `env -u ACE_ASSIGN_ID -u ACE_ASSIGN_FORK_ROOT ace-test ace-assign`.

## What to Fix

- `ace-test-runner/lib/ace/test_runner/molecules/test_executor.rb` — `Open3.capture3(env, command)` only injects `MT_NO_AUTORUN=1`; add explicit `nil` entries for `ACE_ASSIGN_ID` and `ACE_ASSIGN_FORK_ROOT` to suppress them in the child env
- `ace-test-runner/lib/ace/test_runner/suite/process_monitor.rb` — `Open3.popen3(cmd, chdir: ...)` passes no env hash; add one that strips assignment context vars
- Consider a general `ACE_ASSIGN_*` wildcard approach or an explicit allowlist of vars to sanitize

## Related

- `ace-assign/lib/ace/assign/molecules/fork_session_launcher.rb` — sets `ACE_ASSIGN_ID` and `ACE_ASSIGN_FORK_ROOT` via `with_env` for the forked session; these leak into all child processes including test runners

---
Captured: 2026-02-26 00:00:00
