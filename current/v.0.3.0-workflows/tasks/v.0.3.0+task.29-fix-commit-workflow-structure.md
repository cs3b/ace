---
id: v.0.3.0+task.29
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# Fix Commit Workflow Structure

## 0. Directory Audit ✅

_Command run:_

```bash
grep -n "Let's\|checkbox\|\- \[ \]" dev-handbook/workflow-instructions/commit.wf.md | head -10 | sed 's/^/    /'
```

_Result excerpt:_

```
    1:# Let's Commit Workflow Instruction
    (checkboxes found in Process Steps section)
```

## Objective

The commit.wf.md workflow violates multiple structural standards defined in workflow-instructions-definition.g.md. It uses checkboxes within the Process Steps section (explicitly forbidden), has an improperly formatted High-Level Execution Plan, and uses a conversational title. This task will refactor the workflow to comply with all standards.

## Scope of Work

* Remove checkboxes from Process Steps section
* Change H1 title from "Let's Commit..." to standard format
* Restructure High-Level Execution Plan properly
* Ensure compliance with workflow-instructions-definition.g.md

### Deliverables

#### Create

* None - this is a refactoring task

#### Modify

* dev-handbook/workflow-instructions/commit.wf.md

#### Delete

* None

## Phases

1. Analyze current violations
2. Refactor to standard structure
3. Validate compliance
4. Test workflow functionality

## Implementation Plan

### Planning Steps

* [ ] Review workflow-instructions-definition.g.md for exact standards
  > TEST: Standards Reviewed
  > Type: Pre-condition Check
  > Assert: All structural requirements understood
  > Command: bin/test --check-standards-review
* [ ] Identify all structural violations in commit.wf.md
* [ ] Plan the refactored structure

### Execution Steps

* [ ] Change H1 title from "Let's Commit Workflow Instruction" to "Commit Workflow Instruction"
  > TEST: Title Format Correct
  > Type: Content Check
  > Assert: H1 follows verb-first naming convention
  > Command: bin/test --check-title-format
* [ ] Convert all checkboxes in Process Steps to numbered or bullet lists
* [ ] Restructure High-Level Execution Plan section to match standards
  > TEST: No Checkboxes in Process
  > Type: Content Validation
  > Assert: Process Steps section contains no checkboxes
  > Command: bin/test --check-no-process-checkboxes
* [ ] Ensure all sections follow the required workflow structure
* [ ] Verify the workflow remains functionally correct

## Acceptance Criteria

* [ ] H1 title follows "Verb + Context" format without conversational elements
* [ ] No checkboxes appear in the Process Steps section
* [ ] High-Level Execution Plan properly formatted
* [ ] All sections comply with workflow-instructions-definition.g.md
* [ ] Workflow remains executable by AI agents

## Out of Scope

* ❌ Changing the commit process logic
* ❌ Adding new functionality
* ❌ Modifying embedded templates (if any)
* ❌ Updating other workflow files

## References

* workflow-instructions-definition.g.md (structural standards)
* Workflow review reports identifying violations
* Best practices for workflow instruction format
