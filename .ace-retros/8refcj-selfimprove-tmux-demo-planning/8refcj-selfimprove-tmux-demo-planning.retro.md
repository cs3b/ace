---
id: 8refcj
title: selfimprove-tmux-demo-planning
type: standard
tags: [self-improvement, process-fix]
created_at: "2026-04-15 10:13:56"
status: active
---

# selfimprove-tmux-demo-planning

## What Went Well
- Traced the failure back to the planning stage instead of treating it as only a tape or recorder bug.
- Isolated the real user expectation clearly: the demo must show the visible tmux transition from the operator window into the fork window.

## What Could Be Improved
- I optimized for “produce a demo artifact” instead of validating the camera contract first.
- I accepted a recording path that proved commands and end state, but not the user-visible tmux behavior the feature is about.
- I left too much setup on camera and started from the wrong viewpoint, so the fork transition was never obvious.

## Action Items
- Update demo create workflow to require viewpoint, starting state, trigger action, visible reaction, and end-state planning before writing a tape.
- Update demo record workflow to reject tmux/UI demos that do not visibly show `before -> trigger -> visible effect -> after`.
- Re-record the tmux fork demo from a normal work window with setup staged off-camera, then replace the PR-facing artifact.
