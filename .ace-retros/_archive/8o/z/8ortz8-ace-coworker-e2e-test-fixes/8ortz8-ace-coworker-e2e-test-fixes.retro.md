---
id: 8ortz8
title: ace-coworker E2E Test Feedback Fixes
type: conversation-analysis
tags: []
created_at: '2026-01-28 19:59:08'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8ortz8-ace-coworker-e2e-test-fixes.md"
---

# Reflection: ace-coworker E2E Test Feedback Fixes

**Date**: 2026-01-28
**Context**: Fixing 8 issues identified during the first ace-coworker E2E test run (task 229)
**Author**: Agent (task 237)
**Type**: Conversation Analysis

## What Went Well

- Thorough post-mortem analysis of the E2E test identified 8 distinct issues with clear root cause chains
- Root cause analysis traced the PR target branch bug through 5 layers: raw `gh pr create` -> skill behavior -> task metadata -> `ParentTaskResolver` -> `extract_parent_id` returning nil for non-subtasks
- The fix for `ParentTaskResolver` was minimal (3 lines changed) but high-impact, reusing the existing `current_branch_fallback` method that was already designed for this purpose but only wired into the subtask path
- The skill field pipeline change touched 7 source files but followed the existing atom/molecule/organism architecture cleanly, requiring no structural changes

## What Could Be Improved

- The E2E test was executed as a shortcut rather than following the designed workflow steps (issue #2, #8) — the agent made a trivial change instead of invoking `/ace:work-on-task 229`
- Job step files lacked metadata from job.yaml (skill field) because `WorkflowExecutor.start()` only passed `name` and `instructions`, discarding everything else
- The `coworker-prepare` workflow instruction documented `skill:` in presets but nothing in the pipeline actually persisted it — a spec/implementation gap
- Reports were manually written into a `reports/` directory inside the session cache instead of using `ace-coworker report` with temp files — agent didn't follow the designed data flow

## Key Learnings

- **Fallback chains need full coverage**: `current_branch_fallback` existed but was only reachable through the subtask path (`extract_parent_branch`). Non-subtask tasks hit `return DEFAULT_TARGET` before ever reaching it. Defensive fallbacks should be evaluated at every early-return point, not just the deepest fallback
- **Data passthrough > special-casing**: Using `step.except("name", "instructions")` to pass all remaining fields through as `extra` is more resilient than adding individual parameters for each new field (like `skill:`)
- **E2E tests expose integration gaps that unit tests miss**: Each component (StepWriter, StepFileParser, QueueScanner, Step model) worked correctly in isolation, but the skill field was never wired end-to-end
- **Issue cascading**: Issue #1 (wrong target branch) directly caused issue #4 (review analyzed wrong code). Fixing root causes is more valuable than fixing symptoms

## Action Items

### Stop Doing

- Shortcutting workflow steps during E2E tests — the point of E2E is to exercise the full workflow, not demonstrate that the tool starts
- Using raw `gh pr create` when `/ace:create-pr` skill exists and handles target branch resolution
- Manually managing files in the session cache directory — let ace-coworker manage its own state

### Continue Doing

- Root cause chain analysis that traces bugs through multiple layers
- Minimal fixes that reuse existing infrastructure (e.g., `current_branch_fallback` was already written)
- Running both package test suites after cross-cutting changes

### Start Doing

- Add integration tests that verify data flows end-to-end (e.g., job.yaml skill -> step file frontmatter -> Step model)
- Validate that workflow instructions and code stay in sync — if a WFI documents a field like `skill:`, the pipeline must persist it
- When adding fields to data models, trace the full read/write pipeline: writer -> file -> parser -> scanner -> model -> display

## Tool Proposals

- **ace-coworker validate**: A command that reads a job.yaml and validates that all referenced skills exist and all step fields will be persisted through the pipeline
- **ace-git-worktree create --dry-run**: Show what `target_branch` would be resolved to without actually creating the worktree, useful for debugging branch resolution

## Workflow Proposals

- **E2E test execution checklist**: A workflow instruction that enforces executing each step's `skill:` field rather than allowing shortcuts. The coworker status command now shows the skill, which helps but doesn't enforce it
- **Post-E2E review**: A structured review step after E2E testing that compares expected vs actual behavior for each workflow step

## Technical Details

### Files modified (11 total across 2 packages)

**ace-git-worktree (v0.12.4 -> v0.12.5)**:
- `parent_task_resolver.rb:52-57` — added `current_branch_fallback || DEFAULT_TARGET` for nil parent_id path
- `parent_task_resolver_test.rb` — replaced 1 test with 3 new tests covering current branch, nil branch, and detached HEAD

**ace-coworker (v0.1.0 -> v0.1.1)**:
- `step.rb` — added `skill` attr_reader, constructor param, `to_frontmatter` inclusion
- `step_file_parser.rb` — extract `skill` from frontmatter in `extract_fields`
- `queue_scanner.rb` — pass `skill` through to `Step.new`
- `step_writer.rb` — accept `extra: {}` parameter, merge into frontmatter
- `workflow_executor.rb` — pass `step.except("name", "instructions")` as extra
- `status.rb` — display `Skill: <skill>` for current step
- `coworker-prepare-job.wf.md` — updated default output path to task folder

## Additional Context

- Task: 237-ace-coworker-mvp-with-work-queue-model
- E2E test scenario: `.ace-taskflow/v.0.9.0/tasks/237-acecoworker-feat/ux/e2e-test-scenario.md`
- Original E2E run was task 229 (ace-cli-refactor used as test vehicle)
- PR #179 was manually corrected from `main` to `237-ace-coworker-mvp-with-work-queue-model` — the fix prevents this from recurring