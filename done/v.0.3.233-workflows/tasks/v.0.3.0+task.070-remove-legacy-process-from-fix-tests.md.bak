---
id: v.0.3.0+task.70
status: done
priority: medium
estimate: 3h
dependencies: []
---

# Remove Legacy Process from fix-tests.wf.md

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
dev-handbook/workflow-instructions
├── README.md
├── commit.wf.md
├── create-adr.wf.md
├── create-api-docs.wf.md
├── create-reflection-note.wf.md
├── create-task.wf.md
├── create-test-cases.wf.md
├── create-user-docs.wf.md
├── draft-release.wf.md
├── fix-tests.wf.md
├── initialize-project-structure.wf.md
├── load-project-context.wf.md
├── publish-release.wf.md
├── review-code.wf.md
├── review-task.wf.md
├── save-session-context.wf.md
├── synthesize-reflection-notes.wf.md
├── synthesize-reviews.wf.md
├── update-blueprint.wf.md
├── update-roadmap.wf.md
└── work-on-task.wf.md
```

## Objective

Remove the confusing "Legacy Process Steps" section from `fix-tests.wf.md` and streamline the workflow to use only the modern "Iterative Fix Process" approach. This will eliminate confusion for AI agents and provide a single, clear path for fixing test failures.

## Scope of Work

* Remove "Legacy Process Steps" section from fix-tests.wf.md
* Ensure the modern "Iterative Fix Process" is clearly positioned as the primary approach
* Review workflow structure for clarity and consistency
* Update any references to the legacy process

### Deliverables

#### Create

* None

#### Modify

* dev-handbook/workflow-instructions/fix-tests.wf.md (remove legacy section)

#### Delete

* "Legacy Process Steps" section from fix-tests.wf.md

## Phases

1. Analyze current fix-tests.wf.md workflow structure
2. Identify legacy process content to remove
3. Clean up workflow and improve clarity
4. Validate workflow maintains functionality

## Implementation Plan

### Planning Steps

* [x] Analyze fix-tests.wf.md workflow structure and identify legacy content
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Legacy process section identified and modern process confirmed as superior
  > Command: bin/test --check-fix-tests-analysis
* [x] Review modern iterative process to ensure it's comprehensive
* [x] Plan cleanup approach to maintain workflow integrity

### Execution Steps

* [x] Remove "Legacy Process Steps" section from fix-tests.wf.md
  > TEST: Verify Legacy Removal
  > Type: Action Validation
  > Assert: Legacy process section removed and workflow structure improved
  > Command: bin/test --check-legacy-removal fix-tests.wf.md
* [x] Ensure modern "Iterative Fix Process" is clearly positioned as primary approach
* [x] Review and improve overall workflow clarity and structure
  > TEST: Verify Workflow Clarity
  > Type: Action Validation
  > Assert: Workflow provides clear, single path for fixing test failures
  > Command: bin/test --check-workflow-clarity fix-tests.wf.md

## Acceptance Criteria

* [x] AC 1: "Legacy Process Steps" section removed from fix-tests.wf.md
* [x] AC 2: Modern "Iterative Fix Process" clearly positioned as the primary approach
* [x] AC 3: Workflow structure improved for clarity and consistency
* [x] AC 4: No references to legacy process remain in the workflow

## Out of Scope

* ❌ Modifying the core logic of the iterative fix process
* ❌ Adding new test fixing approaches
* ❌ Restructuring the entire workflow beyond legacy removal

## References

* Review finding: "yes we should remove legacy process step and keep one iterative way"
* Source: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/gpro-review.md
* Problem: "This workflow contains a 'Legacy Process Steps' section which is confusing. The modern 'Iterative Fix Process' is superior and should be the sole recommended approach"
* User note: Keep only the iterative approach for clarity
