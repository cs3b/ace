---
id: 8r6qti
title: 8r4-th3e-canonical-skill-assignment-batch
type: standard
tags: []
created_at: "2026-04-07 17:52:48"
status: active
---

# 8r4-th3e-canonical-skill-assignment-batch

## What Went Well
- Breaking the assignment into five forked task subtrees kept the implementation phase parallelizable enough to move quickly while still giving the driver one clear guard point after each subtree.
- The review ladder added real value instead of generating only nits. `code-valid` caught missing `assign.steps` support, missing internal skill headers, and lost step descriptions; `code-fit` caught canonical merge-order and raw opt-out problems; `code-shine` still produced useful cleanup even with one reviewer misconfigured.
- The closeout discipline worked: review fixes were released incrementally, the branch was reorganized into five logical commits before push, the PR description was regenerated from diff evidence, and the final task archive state was verified rather than assumed.

## What Could Be Improved
- The review preset configuration is brittle. The `code-shine` cycle referenced `role:review-geminie`, which failed immediately because that role does not exist. The subtree recovered because `review-codex` completed, but the preset typo should have been caught earlier.
- Task archival has an edge case when archiving a parent with remaining active children. Archiving `8r4.t.h3e.0` auto-archived the parent assignment and relocated the remaining child files into a different archive bucket, leaving an extra `.ace-tasks` move commit to clean up.
- Assignment queue advancement after forked subtrees is still awkward. After finishing forked review cycles, the driver had to detect the missing active step and explicitly run `ace-assign start` before continuing inline closeout work.

## Key Learnings
- Moving assignment discovery metadata into canonical skills only pays off if the runtime, validator, and projection layers all consume the same contract. The valuable fixes in this batch were mostly about eliminating places where one layer still had special-case fallback behavior.
- Internal helper skills need the same structural hygiene as public skills. Missing `# bundle`, `# agent`, and tool-permission declarations are easy to overlook because helpers are not user-facing, but review proved they still affect execution reliability.
- Release-after-review works well when it is scoped to review-cycle deltas instead of re-bumping the whole branch each time. The branch ended with clean patch-line progression for `ace-assign` and `ace-lint` without losing traceability.

### Review Cycle Analysis
- Across the three review cycles, 11 findings were extracted from reports: 3 medium+ fixes in `valid`, 2 medium+ fixes plus 1 false positive and 1 low-priority skip in `fit`, and 3 medium+ fixes in `shine`.
- False-positive rate stayed low but non-zero: `code-fit` produced one medium-severity false positive (`8r6me722`) that was invalidated without code changes. That is a useful signal that the later-cycle presets still need verification discipline, not blind application.
- Severity calibration was directionally good. `code-valid` focused on broken contracts and missing metadata, `code-fit` focused on merge-order/runtime correctness, and `code-shine` focused on polish-level contract cleanup while still surfacing real issues.
- The biggest non-code failure came from tooling configuration, not the models: `review-geminie` in `code-shine` failed immediately due to an invalid alias, while the earlier cycles completed with two successful reviewers each.
- About three quarters of the cross-cycle findings turned into code changes. Eight findings were implemented, one was invalid, and two were intentionally archived as non-blocking.

## Action Items
- Stop shipping review presets with unverified reviewer aliases. Add a lightweight preset validation check so invalid role names fail before a long-running subtree starts.
- Continue using staged review cycles with explicit guard review after each fork subtree. The `valid` -> `fit` -> `shine` sequence found different classes of issues and improved the final branch materially.
- Start hardening `ace-task update --move-to archive --gc` for parent-child archival moves so batch task completion does not require a second cleanup commit when archive bucket paths shift.
