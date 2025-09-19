---
id: v.0.3.0+task.56
status: done
priority: medium
estimate: 5h
dependencies: []
---

# Add Error Recovery Procedures to Workflows

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 1 .ace/handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/workflow-instructions
    ├── README.md
    ├── commit.wf.md
    ├── create-adr.wf.md
    ├── create-task.wf.md
    ├── create-user-docs.wf.md
    ├── initialize-project-structure.wf.md
    ├── log-session-compact.wf.md
    ├── release-complete.wf.md
    ├── release-prepare.wf.md
    ├── research-investigate.wf.md
    ├── review-code.wf.md
    ├── review-task.wf.md
    ├── select-next-task.wf.md
    ├── synchronize-embedded-documents.wf.md
    ├── update-claude-instructions.wf.md
    ├── update-docs.wf.md
    ├── update-roadmap.wf.md
    └── work-on-task.wf.md
```

## Objective

Add workflow failure handling and recovery guidance to improve robustness. This medium-priority enhancement identified by Claude Opus will help AI agents handle errors gracefully and recover from common failure scenarios.

## Scope of Work

* Analyze workflows to identify common failure points
* Research failure modes from reflections and experience
* Add error handling sections to critical workflows
* Create standard error recovery patterns
* Document rollback procedures where applicable

### Deliverables

#### Create

* None

#### Modify

* .ace/handbook/workflow-instructions/*.wf.md - Add error handling sections to critical workflows

#### Delete

* None

## Phases

1. Research - Identify common failure modes
2. Design - Create error handling patterns
3. Implement - Add to workflows
4. Document - Create recovery guide

## Implementation Plan

### Planning Steps

* [x] Analyze reflections for documented workflow failures
  > TEST: Failure Analysis Complete
  > Type: Pre-condition Check
  > Assert: Common failure modes identified
  > Command: rg -i "error|fail|issue" .ace/taskflow/current/v.0.3.0-workflows/reflections/
* [x] Review critical workflows (commit, release, review-code)
* [x] Design standard error handling section format
* [x] Create recovery procedure templates

### Execution Steps

* [x] Add error handling to commit.wf.md (git conflicts, pre-commit hooks)
  > TEST: Commit Error Handling
  > Type: Content Validation
  > Assert: Common git errors addressed
  > Command: rg "Error Handling" .ace/handbook/workflow-instructions/commit.wf.md
* [x] Add error handling to review-code.wf.md (LLM failures, rate limits)
* [x] Add error handling to release workflows (version conflicts, incomplete tasks)
* [x] Add error handling to work-on-task.wf.md (missing dependencies, test failures)
* [x] Create standardized error recovery patterns:
  * Retry strategies
  * Rollback procedures
  * State recovery
  * Manual intervention points
* [x] Document in each workflow's Error Handling section
  > TEST: Error Sections Complete
  > Type: Documentation Validation
  > Assert: Critical workflows have error handling
  > Command: rg "Error Handling" .ace/handbook/workflow-instructions/commit.wf.md .ace/handbook/workflow-instructions/review-code.wf.md .ace/handbook/workflow-instructions/draft-release.wf.md .ace/handbook/workflow-instructions/work-on-task.wf.md

## Acceptance Criteria

* [x] AC 1: Critical workflows have error handling sections
* [x] AC 2: Common failure modes are addressed
* [x] AC 3: Recovery procedures are clear and actionable
* [x] AC 4: AI agents can follow recovery steps autonomously
* [x] AC 5: Rollback procedures documented where needed

## Out of Scope

* ❌ Implementing automated error recovery
* ❌ Creating new error handling tools
* ❌ Modifying workflow core logic

## References

* Review report: .ace/taskflow/current/v.0.3.0-workflows/code_review/20250703-232338-handbook-workflows/cr-report.md
* Reflections: .ace/taskflow/current/v.0.3.0-workflows/reflections/
* Critical workflows: commit, release-*, review-code, work-on-task
