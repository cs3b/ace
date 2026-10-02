---
id: 8x106f
title: tmux-runtime-adapter
type: standard
tags: [ace-tmux, runtime, assignment]
created_at: "2026-10-02 00:07:09"
status: active
---

# tmux-runtime-adapter

## What Went Well

- Implemented the shared `ace-runtime` tmux intent contract through the existing `ace-tmux` control surface, then verified `ace-tmux` (314 tests) and `ace-runtime` (150 tests).
- Kept release preparation coordinated: `ace-tmux` 0.18.0 and three dependency followers received matching versions, changelogs, and lockfile entries.
- The review follow-up added focused tests for literal sends, missing targets, and completion waits.

## What Could Be Improved

- The initial adapter relied on the control surface's text-send behavior, which interpreted message text as keys. The backend needed a literal `send-keys -l` path.
- Wait polling and error classification needed review-driven corrections. These boundary behaviors deserve explicit cases during the first implementation pass.
- The release attempt was interrupted after its commit and became uncertain. Reconciliation required checking the actual release files and attaching a receipt before advancing the assignment.

## Key Learnings

- Adapter tests should cover the native boundary as well as the shared contract. A contract can pass while command encoding and target errors differ from expected behavior.
- Local release preparation is a repository change. Its receipt should describe the prepared versions and current commit without claiming a RubyGems publication.

## Action Items

- Continue using command-level fake executor tests for tmux send, capture, and wait behavior when adding adapter intents.
- Validate supported wait states, short timeouts, and target disappearance in future runtime adapter changes.
- For interrupted release steps, inspect commit history and reconcile the recorded attempt against current files before retrying work.
