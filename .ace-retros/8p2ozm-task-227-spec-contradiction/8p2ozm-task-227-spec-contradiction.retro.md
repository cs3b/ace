---
id: 8p2ozm
title: Task 227 Spec Contradiction - Replace vs Preserve
type: conversation-analysis
tags: []
created_at: "2026-02-03 16:39:34"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8p2ozm-task-227-spec-contradiction.md
---
# Reflection: Task 227 Spec Contradiction - Replace vs Preserve

**Date**: 2026-02-03
**Context**: Task 227 "Feedback-Based Review Output Architecture" had a fundamental spec contradiction that led to incorrect implementation
**Author**: Claude (analysis session)
**Type**: Conversation Analysis

## What Went Well

- The feedback system components (FeedbackItem, FeedbackManager, FeedbackSynthesizer) were implemented correctly
- ATOM architecture was followed properly for new components
- File locking and atomic writes were implemented for concurrent access
- CLI commands for feedback management were created

## What Could Be Improved

- **Spec clarity**: The task spec contained contradictory requirements that went undetected
- **Workflow updates**: The `review.wf.md` and `review-pr.wf.md` workflows were never updated to use feedback files
- **Config simplification**: Config toggles were added when they shouldn't exist for a replacement architecture

## Key Learnings

- **Spec contradiction detection**: When a spec says "replace X with Y" in the overview but then says "preserve X (Y is additive)" in design decisions, that's a critical contradiction that must be resolved before implementation
- **Replace means remove**: If the goal is to replace synthesis-report.md with feedback files, there should be no config toggle for synthesis - it should be removed entirely
- **Workflow-first thinking**: When changing output formats, workflows that consume those outputs must be updated as part of the same task

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Spec Self-Contradiction**: The orchestrator spec contained contradictory statements
  - Occurrences: 1 (but affected entire implementation)
  - Impact: Complete implementation went in wrong direction - made feedback additive instead of replacement
  - Root Cause: Spec writer (likely AI) hedged with "backward compatibility" instead of committing to the replacement design

- **Workflows Not Updated**: review.wf.md and review-pr.wf.md still reference synthesis-report.md
  - Occurrences: 2 files
  - Impact: Agents following workflows still look for synthesis-report.md instead of feedback/
  - Root Cause: Workflow updates weren't listed as explicit subtask, only "Documentation" in 227.08

#### Medium Impact Issues

- **Unnecessary Config Options**: Config toggles for synthesis.enabled and feedback.enabled were added
  - Occurrences: Multiple config files affected
  - Impact: User confusion about what's the "right" configuration
  - Root Cause: Spec said "can be disabled" when it should have said "remove entirely"

### Improvement Proposals

#### Process Improvements

- **Spec consistency check**: Before implementation, verify that Overview and Design Decisions sections are aligned
- **Replacement spec template**: Create a template for "replace X with Y" tasks that explicitly:
  1. States what is being removed
  2. States there are NO config toggles for the old behavior
  3. Lists all consumers (workflows, docs) that must be updated

#### Tool Enhancements

- **ace-taskflow spec validate**: Add validation that checks for contradictory language patterns like "replace X" vs "preserve X"

#### Communication Protocols

- When spec says "replace", explicitly confirm: "This means removing the old thing entirely, correct? No backward compatibility?"

## Action Items

### Stop Doing

- Writing specs that hedge with "backward compatibility" when the intent is replacement
- Adding config toggles for features being replaced
- Assuming workflows will be "updated later" - they must be part of the task

### Continue Doing

- Following ATOM architecture for new components
- Implementing proper file locking for concurrent access
- Creating CLI commands for new functionality

### Start Doing

- **Spec consistency review**: Check Overview vs Design Decisions alignment before implementation
- **Consumer audit**: List ALL consumers (workflows, configs, docs) of changed outputs as explicit subtasks
- **Replacement checklist**: For "replace X with Y" tasks:
  - [ ] Remove X code path
  - [ ] Remove X config options
  - [ ] Update all workflows referencing X
  - [ ] Update all docs referencing X

## Technical Details

### The Contradiction (from 227.00-orchestrator.s.md)

**Line 20 (Overview):**
```
Replace the monolithic `synthesis-report.md` with a structured feedback file system.
```

**Line 104 (Design Decision #4):**
```
4. **Synthesis preserved** (feedback is additive, `--no-feedback` to disable)
```

**Line 85-86 (Directory Structure):**
```
└── 8o7ab2-synthesis.md  (optional, can be disabled)
```

### What Should Have Been Written

Design Decision #4 should have been:
```
4. **Synthesis removed** (feedback replaces synthesis-report.md entirely)
```

And subtask 227.08 Documentation should have explicitly included:
```
- Update review.wf.md to use feedback/ directory
- Update review-pr.wf.md to use feedback/ directory
- Remove synthesis-report.md references from workflows
```

## Additional Context

- PR: #189 (current open PR for task 227)
- Files needing correction:
  - `.ace-taskflow/v.0.9.0/tasks/227-feedback-review-arch/227.00-orchestrator.s.md`
  - `ace-review/handbook/workflow-instructions/review.wf.md`
  - `ace-review/handbook/workflow-instructions/review-pr.wf.md`
  - `ace-review/.ace-defaults/review/config.yml` (remove synthesis config)
  - `.ace/review/config.yml` (remove synthesis override)
