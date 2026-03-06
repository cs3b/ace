---
id: 8q4xts
title: 8q4-reviewer-focus-ownership-gap
type: standard
tags: []
created_at: "2026-03-05 22:33:07"
status: active
task_ref: 8q4.t.ssx
---

# 8q4-reviewer-focus-ownership-gap

## What Went Well

- The redesign did land the major structural pieces: reviewer/provider/pipeline decomposition, `ace-llm` preset-qualified model targets, and risk-based review selection.
- The task tree was sliced well enough to ship the large change incrementally without stalling delivery.
- Verification surfaced the architectural miss quickly because the runtime still exposed preset-owned review instructions.

## What Could Be Improved

- The task described the goal of focused reviewers, but it did not define a reviewer-owned prompt schema.
- The task never stated the negative constraint: review presets must not contain review instructions, focus bundles, or prompt composition blocks.
- "Thin presets" was treated as a size goal instead of an ownership rule, so prompts stayed in preset inheritance while reviewer files remained shallow metadata.
- Review questions focused on lane policy, defaults, and rollout, but did not ask the critical runtime question: can review run with preset instructions removed?
- The slice boundary encouraged a safe partial refactor: add reviewer/provider/pipeline structure while preserving the old preset prompt engine.

## Key Learnings

- Structural decomposition is not enough for a refactor like this. The task must explicitly transfer ownership of behavior from the old layer to the new layer.
- A refactor spec needs both positive goals and negative constraints. "Reviewers should be focused" is insufficient without "presets must not own review instructions."
- Acceptance criteria must include one proof that the old path is no longer required. In this case, one canonical preset should have been runnable with zero review instructions in the preset.
- Inheritance can hide architectural drift. A preset wrapper can look thin while still keeping the real source of truth in an inherited preset.

## Action Items

- Update future refactor task specs to include an `ownership transfer` section naming what layer becomes the new source of truth.
- Add a mandatory `must not remain in old layer` checklist item to task reviews for architectural migrations.
- Require at least one acceptance test that proves the new layer works after removing the old layer's behavioral configuration.
- Follow up on `8q4.t.ssx` with a targeted task that moves prompt composition sections from presets into reviewer definitions and makes presets orchestration-only.
