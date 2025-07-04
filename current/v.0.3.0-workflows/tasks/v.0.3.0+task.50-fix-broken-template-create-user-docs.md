---
id: v.0.3.0+task.50
status: pending
priority: high
estimate: 1h
dependencies: []
---

# Fix Broken Template in Create User Docs Workflow

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook
    ├── guides
    ├── templates
    └── workflow-instructions
```

## Objective

Repair the broken template embedding/reference in create-user-docs.wf.md workflow to make it functional. This critical issue was identified by Google Pro reviewer and currently makes the workflow unusable.

## Scope of Work

* Investigate the current template embedding mechanism in create-user-docs.wf.md
* Identify the specific broken template reference
* Fix the template path or embedding syntax
* Verify the workflow functions correctly after fix

### Deliverables

#### Create

* None

#### Modify

* dev-handbook/workflow-instructions/create-user-docs.wf.md - Fix broken template reference

#### Delete

* None

## Phases

1. Investigate - Analyze the broken template reference
2. Fix - Correct the template embedding/path
3. Verify - Test the workflow functions correctly

## Implementation Plan

### Planning Steps

* [ ] Read create-user-docs.wf.md to identify the broken template reference
  > TEST: Template Issue Identified
  > Type: Pre-condition Check
  > Assert: Broken template reference located and understood
  > Command: bin/test --check-template-issue
* [ ] Check if referenced template exists in dev-handbook/templates/
* [ ] Understand the correct template embedding syntax from working workflows

### Execution Steps

* [ ] Fix the template path reference in create-user-docs.wf.md
  > TEST: Template Path Valid
  > Type: Path Validation
  > Assert: Template path points to existing file
  > Command: bin/test --check-template-path
* [ ] Ensure template embedding follows the standard format
* [ ] Verify the embedded template content is complete
  > TEST: Workflow Functional
  > Type: Syntax Validation
  > Assert: Workflow file passes linting with valid template
  > Command: bin/lint dev-handbook/workflow-instructions/create-user-docs.wf.md

## Acceptance Criteria

* [ ] AC 1: Template reference in create-user-docs.wf.md is fixed
* [ ] AC 2: Referenced template file exists and is accessible
* [ ] AC 3: Workflow passes linting and validation
* [ ] AC 4: Template embedding follows project standards

## Out of Scope

* ❌ Modifying the template content itself
* ❌ Changing the workflow logic
* ❌ Creating new templates

## References

* Review report: dev-taskflow/current/v.0.3.0-workflows/code_review/20250703-232338-handbook-workflows/cr-report.md (Google Pro finding)
* Template directory: dev-handbook/templates/
* Workflow file: dev-handbook/workflow-instructions/create-user-docs.wf.md