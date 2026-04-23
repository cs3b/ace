---
id: 8rf317
title: 8re-t-n1d-2-demo-tmux-recording
type: standard
tags: [ace-demo, ace-tmux, assignment, task]
created_at: "2026-04-16 02:01:20"
status: active
---

# 8re-t-n1d-2-demo-tmux-recording

## What Went Well

- The additive command-shape approach kept the change bounded: existing `type:` scene commands remained intact while `tmux:` maps introduced structured recorder-control without forcing a new tape model.
- Reusing the shared `ace-tmux` surface kept demo-side behavior aligned with the earlier tmux control work. `ace-demo` only translated directive intent; it did not invent a second tmux contract.
- Focused parser/recorder tests caught the integration edges quickly, and the full `ace-demo` package suite still passed after the mixed-command runtime changes.
- The release remained scoped to `ace-demo` only, which kept the subtree release step simple and avoided re-releasing unrelated branch work from earlier subtrees.

## What Could Be Improved

- The first implementation pass hit a real constructor-time bug because `TmuxDirectiveExecutor` instantiated `ControlSurface` through a default that relied on an unqualified `TmuxExecutor` constant. The fix was small, but it is another reminder to avoid eager default object construction when cross-package constants are involved.
- The current implementation treats tmux `attach` as a shell command injected into the recorded PTY while other tmux actions run through host-side control calls. That split is pragmatic, but it should be revisited if later demos need a cleaner attach/detach abstraction.
- Canonical tape migration was intentionally deferred here; the task delivered the directive contract and docs, but not a full rewrite of every existing raw tmux demo tape.
- Native `/review` still was not available in this environment, so pre-commit review again depended on the `ace-lint` fallback rather than a deeper issue-finding pass.

## Action Items

- Continue using additive schema changes for tape features so existing demos remain valid while new recorder-control behavior is introduced incrementally.
- Be more explicit about lazy initialization boundaries when demo code instantiates shared package services at constructor time.
- Plan a follow-up sweep to migrate the highest-value canonical tmux tapes from raw shell glue to structured `tmux:` directives now that the runtime contract exists.
- Keep subtree releases explicitly scoped to the packages changed by that subtree when the branch already contains earlier release commits.
