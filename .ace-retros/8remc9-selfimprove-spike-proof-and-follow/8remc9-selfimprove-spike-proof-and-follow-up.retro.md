---
id: 8remc9
title: selfimprove-spike-proof-and-follow-up
type: standard
tags: [self-improvement, process-fix, spike]
created_at: "2026-04-15 14:53:38"
status: active
---

# selfimprove-spike-proof-and-follow-up

## What Went Well
- The comparison between `8r6.t.u53.0` and the shipped runtime made the gap concrete instead of leaving it as a vague feeling that the spike was "useful but incomplete."
- The strongest parts of the spike were still valuable: it correctly identified the preserved assignment-state authority boundary and the need for a shared fork window surface.
- The follow-up retros from demo verification and PR refresh provided enough evidence to distinguish design drift from proof-of-concept gaps.

## What Could Be Improved
- The original spike validated a design contract, but it was later treated as if it had already proven a real runtime path.
- The process allowed the spike to finish without an explicit follow-up task that consumed the spike learnings immediately.
- Public-contract drift (mode names, window naming, fallback semantics, interactive-launch architecture) was handled during implementation, but the task lifecycle did not force the spec or a follow-up task to catch up before release/demo cleanup.
- The workflow had no explicit check that a spike affecting runtime UX produced a reusable proof artifact instead of only a concept inventory.

## Action Items
- Require spike tasks to declare whether they are design-contract spikes or proof-of-concept spikes.
- Require proof-of-concept spikes to carry a proof artifact plan and success criteria tied to runnable evidence.
- Require all spikes to include explicit follow-up tasks after the spike so adoption work is never implicit.
- Review completed spikes against shipped behavior, classify drift, and fail closed when a spike produced no reusable next task.
- Stop implementation flow when runtime work materially changes a spike-promised public contract until the spec or follow-up task is updated.
