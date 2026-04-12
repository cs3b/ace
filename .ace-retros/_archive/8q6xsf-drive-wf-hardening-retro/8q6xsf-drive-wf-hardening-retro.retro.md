---
id: 8q6xsf
title: drive-wf-hardening-retro
type: standard
tags: []
created_at: "2026-03-07 22:31:36"
status: active
task_ref: 0m6.0
---

# drive-wf-hardening-retro

Self-improvement retro: hardening `drive.wf.md` based on retros `8q6uxs` (drive issues) and `8q6xku` (completion retro) from assignment `8q6tiz` (task 0m6.0).

## What Went Well

- **Retro-to-fix pipeline worked**: Two retros identified specific anti-patterns → plan created → 4 targeted insertions applied → zero test regressions. The retro system successfully fed back into the workflow instructions it was critiquing.
- **Surgical edits**: All changes were pure insertions (~29 lines added) with no existing content modified or removed. This minimized risk and kept the diff reviewable.
- **Placement strategy**: Edits targeted the most-read sections (Phase Execution Policy, Adaptation Assessment) rather than burying rules in obscure subsections — directly addressing the original complaint that rules existed but weren't prominent enough.

## What Could Be Improved

- **Prevention over patching**: The fork-delegation rule already existed in the file but was buried. The fix was to repeat it more prominently. A structural improvement would be to add a "Critical Rules" summary box at the top of the file that agents see first.
- **Testability of workflow instructions**: There's no automated way to verify that an agent follows drive.wf.md rules. These are prose-level constraints that rely on the agent reading and complying. Consider whether key constraints could be enforced programmatically (e.g., `ace-assign` CLI refusing inline execution of fork-marked phases).

## Key Learnings

- **Prominence matters more than existence**: The original file had the right rules but in low-visibility subsections. When a rule is critical, it must appear in the section agents read on every phase cycle (Phase Execution Policy), not just in edge-case handling sections.
- **Anti-pattern documentation is high-value**: The re-fork section's explicit "Anti-pattern" callout is more actionable than abstract rules. Showing what NOT to do with a concrete example prevents the exact mistake that occurred.

## Action Items

- **Continue**: Using retros to identify workflow instruction gaps and feeding fixes back into the handbook.
- **Consider**: Adding programmatic guardrails in `ace-assign` CLI to enforce fork-delegation constraints (e.g., warn/block when driver tries to finish a FORK:yes phase directly).
- **Consider**: A "Critical Rules" summary at the top of `drive.wf.md` that lists the 3-5 most important constraints in one visible block.
