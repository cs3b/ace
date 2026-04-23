---
id: 8rf2uj
title: 8re-t-n1d-1-assign-tmux-delegation
type: standard
tags: [ace-assign, ace-tmux, assignment, task]
created_at: "2026-04-16 01:53:56"
status: active
---

# 8re-t-n1d-1-assign-tmux-delegation

## What Went Well

- The migration removed the private `TmuxForkRunner` without regressing the fork-launch contract: `ace-assign` now consumes `ace-tmux` for target resolution, pane dispatch, and pane-id capture while assignment state remains the completion source of truth.
- The adapter boundary stayed narrow. `ForkSessionLauncher` kept wrapper generation and subtree polling, while tmux-specific behavior moved behind one shared-surface-backed runner.
- Focused tests caught the integration edges quickly, and the broader verification held: `ace-test ace-assign`, `cd ace-assign && ace-test all --profile 6`, and `cd ace-tmux && ace-test all --profile 6` all passed cleanly.
- Release follow-through stayed explicit. `ace-assign` was bumped to `0.53.0`, `ace-tmux` to `0.14.1`, and the coordinated release metadata landed without dragging unrelated packages into the release set.

## What Could Be Improved

- The first scoped implementation commit missed the deletion of the obsolete `tmux_fork_runner.rb` source file, so the pre-commit review step had to catch and clean up that leftover deletion.
- Native `/review` was still unavailable in this execution environment, so pre-commit review had to fall back to `ace-lint` again. That keeps hygiene but not the same issue-detection depth as a real review pass.
- Release auto-detection from `origin/main...HEAD` would have pulled in packages already released by the earlier subtree on the same branch. Explicit subtree-scoped package selection was required to avoid a duplicate release surface.
- The subtree release step again only handled local version/changelog commits. RubyGems propagation proof was correctly documented as not run, but that verification remains deferred to a later publish stage.

## Action Items

- Add a lightweight check before work-step completion that compares `git status --short` against the intended deletion list so removed files do not leak into pre-commit review.
- Keep using explicit package selection for release steps when multiple subtrees on one branch have already produced earlier release commits.
- Continue preferring shared package primitives over consumer-local wrappers when adoption work exposes a missing capability; the small `ace-tmux` `split-window` print-format addition was a good example of the right boundary.
- Keep documenting when subtree release steps stop at local metadata/commit updates and do not prove RubyGems propagation.
