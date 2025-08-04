---
id: v.0.3.0+task.13
status: done
priority: medium
estimate: 1h
dependencies: []
---

# Rename breakdown-notes-into-tasks.wf.md to create-task.md

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/workflow-instructions
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

Rename the workflow instruction file `breakdown-notes-into-tasks.wf.md` to `create-task.md` to better reflect its purpose and align with standard naming conventions. The current name is verbose and doesn't clearly indicate that this is the primary task creation workflow.

## Scope of Work

* Rename the workflow instruction file in dev-handbook/workflow-instructions/
* Ensure the file maintains its current functionality and content
* Update any references to the old filename if they exist in other documentation

### Deliverables

#### Create

* dev-handbook/workflow-instructions/create-task.md

#### Modify  

* (None expected, but check for references)

#### Delete

* dev-handbook/workflow-instructions/breakdown-notes-into-tasks.wf.md

## Phases

1. Research/Analysis - Check for any references to the current filename in documentation
2. Implementation - Rename the file using git mv to preserve history
3. Validation - Verify the rename was successful and no references are broken

## Implementation Plan

### Planning Steps

* [x] Search for references to "breakdown-notes-into-tasks.wf.md" in the codebase
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: No broken references will result from the rename
  > Command: grep -r "breakdown-notes-into-tasks" . --exclude-dir=.git

### Execution Steps

* [x] Rename the file using git mv for history preservation
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: File successfully renamed and git history preserved
  > Command: ls -la dev-handbook/workflow-instructions/create-task.md

* [x] Update any found references to use the new filename
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: All references updated to new filename
  > Command: grep -r "create-task.md" . --exclude-dir=.git

## Acceptance Criteria

* [x] File successfully renamed from breakdown-notes-into-tasks.wf.md to create-task.md
* [x] Git history preserved through proper git mv usage
* [x] All references to the old filename updated (if any exist)
* [x] File content remains unchanged
* [x] No broken links or references result from the rename

## Out of Scope

* ❌ Modifying the content or structure of the workflow instruction
* ❌ Renaming other workflow instruction files in this task
* ❌ Updating documentation beyond fixing direct references

## References

* Original requirement: Rename dev-handbook/workflow-instructions/breakdown-notes-into-tasks.wf.md -> create-task.md
* Related workflow: This file itself contains the workflow instructions for task creation
