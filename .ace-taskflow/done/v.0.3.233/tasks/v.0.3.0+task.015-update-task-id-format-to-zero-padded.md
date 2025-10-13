---
id: v.0.3.0+task.15
status: done
priority: high
estimate: 2h
dependencies: []
---

# Update Task ID Format to Use Zero-Padded Numbers

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/workflow-instructions
    ├── breakdown-notes-into-tasks.wf.md
    ├── commit.wf.md
    ├── create-adr.wf.md
    ├── create-api-docs.wf.md
    ├── create-reflection-note.wf.md
    ├── create-test-cases.wf.md
    ├── create-user-docs.wf.md
    ├── draft-release.wf.md
    ├── fix-tests.wf.md
    ├── initialize-project-structure.wf.md
    ├── load-project-context.wf.md
    ├── save-session-context.md
    ├── publish-release.wf.md
    ├── README.md
    ├── review-task.wf.md
    ├── update-blueprint.wf.md
    ├── update-roadmap.wf.md
    └── work-on-task.wf.md
    
    1 directory, 18 files
```

## Objective

Update the task creation workflow (breakdown-notes-into-tasks.wf.md, which will be renamed to create-task.md) and the bin/tnid command to ensure consistent zero-padded task ID formatting. Currently, task IDs may use single digits (v.0.3.0+task.1) but should use zero-padded format (v.0.3.0+task.01) for better sorting and organization.

## Scope of Work

* Update the workflow instructions to specify zero-padded task ID format
* Update the task template to show zero-padded format in examples
* Modify the bin/tnid command to generate zero-padded task IDs
* Ensure consistency in task ID generation guidelines
* Update documentation references to use the new format

### Deliverables

#### Create

* (None - modifying existing files)

#### Modify  

* .ace/handbook/workflow-instructions/breakdown-notes-into-tasks.wf.md (or create-task.md if already renamed)
* bin/tnid

#### Delete

* (None)

## Phases

1. Research/Analysis - Review current task ID formats and identify inconsistencies
2. Design/Planning - Define the standard zero-padded format requirements
3. Implementation - Update workflow instructions and bin/tnid command with correct format
4. Testing/Validation - Verify examples use consistent zero-padded format and bin/tnid generates correct IDs

## Implementation Plan

### Planning Steps

* [ ] Review current task ID format in the workflow instruction file
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Current format identified and inconsistencies documented
  > Command: grep -n "task\." .ace/handbook/workflow-instructions/breakdown-notes-into-tasks.wf.md

* [ ] Check existing task files to understand current naming conventions
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Existing task naming patterns identified
  > Command: ls .ace/taskflow/current/v.0.3.0-workflows/tasks/ | grep -E "task\.[0-9]+"

* [ ] Examine the current bin/tnid implementation
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Current ID generation logic understood
  > Command: cat bin/tnid

### Execution Steps

* [x] Update the workflow template to use zero-padded task IDs in examples
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Template shows zero-padded format (e.g., task.01, task.02)
  > Command: grep -n "task\." .ace/handbook/workflow-instructions/create-task.md

* [x] Update the task ID generation section to specify zero-padding requirement
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Instructions specify zero-padded format for task IDs
  > Command: grep -A5 -B5 "bin/tnid" .ace/handbook/workflow-instructions/create-task.md

* [x] Update filename creation instructions to use zero-padded format
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Filename examples show zero-padded task IDs
  > Command: grep -n "kebab-case-title" .ace/handbook/workflow-instructions/create-task.md

* [x] Modify bin/tnid to generate zero-padded task IDs
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: bin/tnid generates IDs with zero-padding (e.g., task.01, task.02)
  > Command: bin/tnid v.0.3.0 | grep -E "task\.[0-9]{2}"

## Acceptance Criteria

* [x] All task ID examples in the workflow use zero-padded format (01, 02, etc.)
* [x] Task ID generation instructions specify zero-padding requirement
* [x] Filename creation examples show zero-padded task IDs
* [x] bin/tnid command generates zero-padded task IDs consistently
* [x] No inconsistent single-digit task ID references remain in the workflow
* [x] Documentation clearly explains the zero-padded format standard

## Out of Scope

* ❌ Renaming existing task files to use zero-padded format (separate task)
* ❌ Updating other workflow instruction files beyond the create-task workflow
* ❌ Modifying completed task files in .ace/taskflow/done/
* ❌ Changing the underlying task numbering sequence (still incremental, just zero-padded)

## References

* Original requirement: Ensure we use prefixed IDs for tasks and filenames (not v.0.3.0+task.1 instead of v.0.3.0+task.01)
* Related workflow: breakdown-notes-into-tasks.wf.md (the file being updated)
* Related command: bin/tnid (the command being updated)
* Task ID standard: Zero-padded format for consistent sorting and organization
