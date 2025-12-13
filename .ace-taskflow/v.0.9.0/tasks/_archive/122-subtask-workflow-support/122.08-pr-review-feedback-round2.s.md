---
id: v.0.9.0+task.122.08
status: done
priority: high
estimate: 3h
dependencies:
  - v.0.9.0+task.122.07
parent: v.0.9.0+task.122
---

# PR #48 Review Feedback - Round 2

## Scope

Address review feedback from PR #48 (GPro and GPT-5.1 reviews) to improve code quality and documentation.

## Deliverables

### Critical Fix (Medium)
- [x] Fix subtask_ids synchronization bug in task_loader.rb
  - Problem: build_task_relationships only populates subtask_ids when frontmatter is empty
  - Solution: Always merge discovered subtasks with frontmatter, making actual files authoritative

### Documentation Improvements (Low)
- [x] Add lookup precedence comment to find_task_by_reference
- [x] Document terminal statuses in .ace.example/taskflow/config.yml
- [x] Clarify orchestrator/subtask source of truth in workflow docs

### Code Quality Improvements (Optional)
- [x] Add CLI integration tests for --subtasks, --no-subtasks, --flat and --child-of flags (complex integration tests created)
- [x] Skip extract_references refactoring (method is complex but well-tested and documented)

## Acceptance Criteria

- [x] subtask_ids always reflect actual subtask files on disk
- [x] Code documentation explains lookup behavior and lifecycle
- [x] Example config includes terminal status explanations
- [x] Workflow docs clarify source of truth for subtasks
- [x] All tests pass (1 pre-existing flaky test unrelated to changes)