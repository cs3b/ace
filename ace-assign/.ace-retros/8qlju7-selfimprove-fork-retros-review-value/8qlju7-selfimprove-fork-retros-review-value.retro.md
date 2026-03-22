---
id: 8qlju7
title: selfimprove-fork-retros-review-value
type: self-improvement
tags: [process-fix, retro, review]
created_at: "2026-03-22 13:13:33"
status: active
---

# Self-Improvement: Fork Retros + Review Value Extraction

Source: Assignment `8ql46r` (docs overhaul for ace-git family + ace-idea)

## Root Cause Analysis

**Problem 1 — No retros inside fork subtrees**
- Fork subtrees (work-on-task × 4, review cycles × 3) completed without capturing per-fork learnings
- The top-level retro at assignment end lost fork-specific context (what the fork agent learned, obstacles encountered)
- Root cause category: **Missing step** — retro creation was only wired at the assignment level, not inside fork subtrees

**Problem 2 — Review data underutilized**
- 3 review cycles generated 20 feedback items across 3 sessions with rich metadata (severity, model attribution, resolution status)
- No systematic cross-cycle analysis was performed — patterns like recurring findings, model-specific strengths, and false-positive rates went unexamined
- Root cause category: **Missing guidance** — the retro workflow had no prompts for analyzing review session data

## Process Changes Applied

1. **Added `create-retro` as last step in fork subtrees**
   - `ace-task/handbook/workflow-instructions/task/work.wf.md` — added to sub-steps after `release-minor`
   - `ace-assign/.ace-defaults/assign/catalog/recipes/implement-with-pr.recipe.yml` — added to review-cycle sub_steps
   - `ace-assign/.ace-defaults/assign/catalog/recipes/batch-tasks.recipe.yml` — same
   - `ace-assign/.ace-defaults/assign/catalog/composition-rules.yml` — added ordering rules

2. **Added commit step to retro creation workflow**
   - `ace-retro/handbook/workflow-instructions/retro/create.wf.md` — new step 7 commits `.ace-retros/` so fork retros are preserved

3. **Added review-aware reflection prompts to retro workflow**
   - Same file — new guidance under step 5 for analyzing review sessions when available
   - `ace-assign/.ace-defaults/assign/catalog/steps/create-retro.step.yml` — declared `review-sessions` as consumed input

## Expected Impact

- Each fork subtree now produces a committed retro capturing fork-specific learnings
- Review cycle retros will include cross-cycle analysis (recurring patterns, model strengths, false-positive rates)
- The top-level assignment retro can synthesize fork retros for a complete picture

## Action Items

- **CONTINUE**: Using the self-improve workflow when process gaps are identified
- **MONITOR**: Whether fork retros produce meaningful content or just add noise (adjust `when_to_skip` if needed)

