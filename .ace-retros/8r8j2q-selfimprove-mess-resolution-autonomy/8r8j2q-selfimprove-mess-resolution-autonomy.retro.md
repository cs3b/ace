---
title: Self-improve mess resolution autonomy
type: standard
tags:
  - self-improvement
  - process-fix
  - agent-autonomy
status: active
---

# What happened

During the E2E stabilization loop, the worktree contained a deleted tracked fixture, an untracked timestamped replacement, and stray generated `results/` output. The agent stopped to ask whether to include or ignore the mess instead of resolving the accidental churn directly.

# Actual result

The session slowed down on a cleanup decision that was already clear from repo state. The tracked scenario still referenced the original fixture path, so the best repair was to restore the tracked fixture and remove the stray replacement and generated output.

# Expected result

When the worktree is messy in an obviously accidental way, the agent should clean it up using the least destructive local judgment and continue. User escalation should be reserved for cases where cleanup could plausibly destroy intentional user-authored work.

# Root cause

- Ambiguous instructions
- Missing validation

Current guidance strongly emphasized not reverting unrelated work, but it did not include the complementary rule for handling obvious accidental churn decisively.

# Process change applied

Updated `AGENTS.md` with a `Mess Resolution Rule`:

- fix messy worktrees using best local judgment
- prefer the least destructive corrective action
- remove obvious generated leftovers and stray scenario artifacts
- restore deleted tracked files when the active scenario still depends on them
- escalate only when cleanup might destroy intentional user work

# Expected impact

- fewer unnecessary interruptions during messy E2E and fixture-debugging loops
- better local cleanup decisions without waiting for user approval
- clearer distinction between “plausibly intentional unrelated work” and “obvious accidental churn”
