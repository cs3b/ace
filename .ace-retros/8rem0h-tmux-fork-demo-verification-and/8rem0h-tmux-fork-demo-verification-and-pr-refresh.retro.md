---
id: 8rem0h
title: tmux-fork-demo-verification-and-pr-refresh
type: standard
tags: [retro, tmux, demo, pr]
created_at: "2026-04-15 14:40:32"
status: active
---

# tmux-fork-demo-verification-and-pr-refresh

## What Went Well
- The real product path is now truthful: tmux forks open the `-fs` window, start an interactive agent, show the translated handoff, and the agent begins real work in the new pane.
- The cast-verification loop was valuable once used as the source of truth. It separated scenario defects from product bugs and prevented another misleading PR update.
- The runtime bug around `PROJECT_ROOT_PATH` leaking from the outer repo into the sandbox was isolated concretely by inspecting the generated tmux wrapper and replaying `ace-assign` inside the sandbox.
- Reorganizing the full PR history before the final PR refresh made the final description much easier to regenerate from evidence instead of patching the older launch-mode-only story.

## What Could Be Improved
- The recorder control path is still weaker than the runtime path. `ace-demo record` with asciinema plus `tmux attach` remains linear, so later scene commands cannot reliably control the attached client.
- I spent too long trying to make `ace-demo record` itself terminate cleanly before switching to the verified-cast path, even after the cast already proved the feature behavior.
- The tape verification marker was initially too strict and unstable (`Assignment subtree completed`) when the real user-visible proof was earlier: the fork window opens and the agent starts assignment work there.
- `ace-demo attach` failing on a `0x0` cast header was another reminder that generated artifacts need a final sanity pass before using them as release evidence.

## Key Learnings
- For tmux demos, there are three separate layers that must be debugged independently:
  1. product/runtime behavior
  2. cast semantics and verification markers
  3. recorder lifecycle/termination
- The correct escalation order is: prove the live runtime in the pane first, verify the cast directly second, and only then optimize the full `ace-demo record --pr` automation.
- Interactive fork launches must explicitly pin the execution root into the pane environment. Without that, a visually correct tmux launch can still drive the wrong assignment store and silently invalidate the demo.
- PR refresh should be delayed until both the branch history and the demo evidence are stable. Updating the PR body too early creates churn and hides the real shape of the change set.

## Action Items
- Add first-class support in `ace-demo` for tmux-attach recordings that need out-of-band detach/termination, instead of relying on linear post-attach shell commands.
- Add a final artifact sanity check in the demo workflow for cast terminal dimensions before `ace-demo attach`.
- Prefer stable “agent has started real work” markers in tmux demo verification over late terminal-state summaries when the feature is primarily about visible execution.
- Keep using direct inspection of generated wrapper scripts and sandbox-local command replays when diagnosing interactive tmux launch bugs; that was the fastest path to the real fix here.
