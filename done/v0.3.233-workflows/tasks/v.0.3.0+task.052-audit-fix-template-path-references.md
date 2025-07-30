---
id: v.0.3.0+task.52
status: done
priority: high
estimate: 3h
dependencies: []
---

# Audit and Fix Template Path References

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 dev-handbook/templates | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/templates
    ├── adrs
    │   └── adr.template.md
    ├── guides
    │   └── guide.template.md
    ├── release-tasks
    │   └── task.template.md
    └── workflows
        └── workflow.template.md
```

## Objective

Resolve all template path references across 17+ workflows to restore system integrity. This critical issue identified by Claude Opus affects the reliability of template embedding across the workflow system.

## Scope of Work

* Map all template dependencies across workflow files
* Identify incorrect or broken template path references
* Fix all template paths to point to correct locations
* Verify template embedding works correctly after fixes

### Deliverables

#### Create

* None

#### Modify

* dev-handbook/workflow-instructions/*.wf.md - Fix template path references as needed

#### Delete

* None

## Phases

1. Audit - Map all template references
2. Analyze - Identify broken paths
3. Fix - Correct all path issues
4. Verify - Ensure all templates load correctly

## Implementation Plan

### Planning Steps

* [x] Create comprehensive map of template usage across workflows
  > TEST: Template Map Complete
  > Type: Pre-condition Check
  > Assert: All template references documented
  > Command: rg "<template path=" dev-handbook/workflow-instructions/
* [x] Check each referenced template path for existence
* [x] Identify patterns in path errors (relative vs absolute, wrong directories)
* [x] Plan systematic fix approach

### Execution Steps

* [x] Fix template paths in workflow files (batch by error type)
  > TEST: Template Paths Valid
  > Type: Path Validation
  > Assert: All template paths point to existing files
  > Command: bin/test --check-template-paths
* [x] Ensure all paths follow consistent format (relative from handbook root)
* [x] Verify embedded template content loads correctly
* [x] Run linting on all modified workflow files
  > TEST: Workflows Valid
  > Type: Syntax Validation
  > Assert: All workflow files pass linting
  > Command: bin/lint dev-handbook/workflow-instructions/*.wf.md

## Acceptance Criteria

* [x] AC 1: All template path references audited and mapped
* [x] AC 2: Broken template paths identified and fixed
* [x] AC 3: Template paths follow consistent format
* [x] AC 4: All workflows pass linting after fixes
* [x] AC 5: Template embedding functions correctly

## Out of Scope

* ❌ Modifying template content
* ❌ Creating new templates
* ❌ Changing template embedding syntax

## References

* Review report: dev-taskflow/current/v.0.3.0-workflows/code_review/20250703-232338-handbook-workflows/cr-report.md (Claude Opus finding)
* Template directory: dev-handbook/templates/
* Workflow files: dev-handbook/workflow-instructions/*.wf.md
* Template embedding standard: dev-taskflow/current/v.0.3.0-workflows/docs/template-embedding-standard.md
