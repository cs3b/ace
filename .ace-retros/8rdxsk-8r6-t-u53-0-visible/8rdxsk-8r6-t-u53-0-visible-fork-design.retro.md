---
id: 8rdxsk
title: 8r6-t-u53-0-visible-fork-design-spike
type: standard
tags: []
created_at: "2026-04-14 22:31:45"
status: active
---

# 8r6-t-u53-0-visible-fork-design-spike

## What Went Well

- The spike stayed anchored to the current implementation surface instead of inventing a new fork orchestration model.
- Reviewing `fork_run.rb`, `fork_session_launcher.rb`, tmux window management, and provider CLI clients made the boundary decisions concrete quickly.
- The final task edits turned vague candidate concepts into an explicit validated scenario plus a kept/changed/new/rejected inventory, which should make follow-on implementation subtasks easier to draft.
- Keeping the work scoped to `.ace-tasks/...` avoided accidental package-release churn and made verification straightforward.

## What Could Be Improved

- `ace-bundle project` and `ace-bundle project-base` did not return their expected bundle-path output in this shell session, so onboarding had to fall back to canonical project docs and the task bundle's embedded context.
- The parent task spec had existing markdown-spacing issues that only surfaced during the fallback lint pass; fixing them added a small amount of cleanup work unrelated to the spike decision itself.
- The pre-commit review step could not use a native `/review` slash command in this environment, so it relied on manual scoped review plus lint fallback.

## Key Learnings

- Visible mode should be treated as a presentation layer over the existing provider-backed fork session, not as a replacement execution path.
- Assignment state must stay authoritative for subtree completion and failure even when tmux panes are available for live inspection.
- Generic tmux inspectability and recording concerns are substantial enough that they need to stay isolated in sibling task `8r6.t.xeu`; mixing them into visible-fork design would make later implementation boundaries unstable.
- A concept inventory is especially useful for design spikes that bridge multiple packages because it prevents later subtasks from re-litigating ownership questions.

## Action Items

- Continue decomposing parent task `8r6.t.u53` from the validated concept inventory rather than re-opening the visible-mode contract.
- Investigate why `ace-bundle project` and `ace-bundle project-base` hung without emitting their normal output path in this environment.
- Preserve the documented no-op handling for release/verification steps when a subtree changes only task specs and retrospective artifacts.
