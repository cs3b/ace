---
id: 8qeiak
title: selfimprove-task-review-orchestrator-promotion
type: self-improvement
tags: [process-fix]
created_at: "2026-03-15 12:11:45"
status: active
---

# selfimprove-task-review-orchestrator-promotion

## What Went Well

- The review workflow caught real spec issues in the `8qe.t.h5e` family and helped normalize the parent task plus subtasks before implementation began.
- The task hierarchy made it obvious that the parent orchestrator and subtasks should share a stricter readiness invariant.

## What Could Be Improved

- `task/review` only promoted the explicitly reviewed task and did not define orchestrator-specific recursion over draft subtasks.
- That allowed the parent task to move to `pending` while all child subtasks remained `draft`, which created a misleading lifecycle state.
- The workflow lacked a validation checkpoint preventing parent promotion when any child subtask had not yet passed review.

## Action Items

- Updated `ace-task/handbook/workflow-instructions/task/review.wf.md` to detect orchestrators, review draft child subtasks first, and promote the parent only after all child reviews pass.
- Applied the immediate fix by promoting the `8qe.t.h5e.*` subtasks to `pending` so the hierarchy now matches the intended parent-last policy.
- Use the updated workflow behavior for future orchestrator reviews to avoid parent-only promotion drift.
