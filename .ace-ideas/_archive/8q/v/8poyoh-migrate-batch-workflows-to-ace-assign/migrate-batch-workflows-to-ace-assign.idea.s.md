---
title: Migrate Batch Processing Workflows to ace-assign
filename_suggestion: refactor-taskflow-batch-to-assign
enhanced_at: 2026-02-25 23:07:12 +0000
llm_model: "pi:glm"
id: 8poyoh
status: done
tags: []
created_at: "2026-02-25 23:07:11"
---

# Migrate Batch Processing Workflows to ace-assign

## What I Hope to Accomplish
Remove batch processing workflows (work-on-tasks, review-tasks, and similar) from the codebase and migrate their functionality to ace-assign. This simplifies the workflow system by centralizing batch operations in a single tool designed for creating and executing lists of actions, with optional forking support for parallel execution.

## What "Complete" Looks Like
All batch processing workflow files removed from handbook/workflow-instructions/, their capabilities migrated to ace-assign with equivalent functionality, any dependent agents or skills updated to use ace-assign, and tests passing with no regressions in batch operation capabilities.

## Success Criteria
- Batch processing workflows (work-on-tasks.wf.md, review-tasks.wf.md, and equivalents) removed from all gems
- ace-assign accepts list-based action definitions with optional forking parameter
- All existing consumers of batch workflows migrated to ace-assign
- Test coverage validates batch operations via ace-assign produce identical results
- No broken references or missing capabilities after migration

---

## Original Idea

```
we need to remove all the batch processing workflows work-on-tasks, review-tasks, so on - we should migrate any batch operations to ace-assing - that allow us to create list of actions that need to be done with forking or not
```