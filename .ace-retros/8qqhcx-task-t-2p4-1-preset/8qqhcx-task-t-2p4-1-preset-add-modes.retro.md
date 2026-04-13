---
id: 8qqhcx
title: task-t-2p4-1-preset-add-modes
type: standard
tags: [ace-assign, assignment]
created_at: "2026-03-27 11:34:22"
status: active
---

# task-t-2p4-1-preset-add-modes

## What Went Well

- The `ace-assign add` contract rewrite landed cleanly with explicit mutually exclusive modes (`--yaml`, `--step`, `--task`).
- Reused existing `AssignmentExecutor#add_batch` and canonical subtree materialization, which reduced regression risk.
- Added focused helper modules (`PresetLoader`, `PresetStepResolver`, `PresetInferrer`) with isolated tests, improving readability and future extension points.
- Validation and package tests stayed stable (`ace-test ace-assign` passed with no failures).
- Release follow-through was completed in the same run (`ace-assign v0.39.0`, root changelog + lockfile update).

## What Could Be Improved

- Branch-level package auto-detection for release is noisy when unrelated historical commits exist; subtree-specific release scope still required human judgment.
- The retro template is minimal by default (missing Key Learnings structure), which invites inconsistent retros unless manually expanded.
- Pre-commit fallback (`ace-lint`) reported many warnings on task spec metadata; warnings were non-blocking but high volume reduces signal.

## Key Learnings

- Explicit mode contracts in CLI commands significantly simplify error handling and prevent ambiguous behavior.
- Base-name matching plus auto-iteration naming provides a practical bridge from preset-defined review cycles to runtime queue insertion.
- Keeping insertion behavior centralized in executor paths avoids duplicated numbering/parent-child logic and protects against drift.
- Scoped release commits using `ace-git-commit <paths...>` work well in dirty assignment trees and avoid accidental inclusion of task metadata files.

## Action Items

- Add a small helper in release workflows to optionally scope package detection to commits created within the current assignment subtree.
- Expand the default retro template to include an explicit `Key Learnings` section so retrospective quality is more uniform.
- Consider introducing a warning-threshold summary mode for `ace-lint` fallback in pre-commit-review to improve triage signal.
