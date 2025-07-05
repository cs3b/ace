---
id: v.0.3.0+task.69
status: pending
priority: high
estimate: 12h
dependencies: []
---

# Refactor Shell Logic from Workflows

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
├── synthesize-reflection-notes.wf.md
├── synthesize-reviews.wf.md
├── update-blueprint.wf.md
├── update-roadmap.wf.md
└── work-on-task.wf.md
```

## Objective

Extract complex shell script logic from workflow instruction files into dedicated executable scripts, particularly from `review-code.wf.md` and `synthesize-reviews.wf.md`. This will improve maintainability, testability, and clarity by separating the workflow instruction (what and why) from the implementation details (how).

## Scope of Work

* Identify complex shell logic embedded in workflow instructions
* Extract shell logic into dedicated bin/ scripts or dev-tools scripts
* Update workflows to call the new scripts with appropriate parameters
* Ensure new scripts are properly tested and documented

### Deliverables

#### Create

* bin/review-code or dev-tools/exe/review-code (extracted shell logic)
* bin/synthesize-reviews or dev-tools/exe/synthesize-reviews (extracted shell logic)
* Test files for new scripts

#### Modify

* dev-handbook/workflow-instructions/review-code.wf.md (update to call script)
* dev-handbook/workflow-instructions/synthesize-reviews.wf.md (update to call script)

#### Delete

* None

## Phases

1. Audit workflows for complex shell logic
2. Analyze and extract shell logic from identified workflows
3. Create dedicated scripts with proper error handling
4. Update workflows to use new scripts
5. Test and validate script functionality

## Implementation Plan

### Planning Steps

* [ ] Audit review-code.wf.md and synthesize-reviews.wf.md for shell logic
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Complex shell logic identified and catalogued for extraction
  > Command: bin/test --check-shell-logic-audit
* [ ] Analyze session management and LLM query patterns in the workflows
* [ ] Plan script architecture and parameter interfaces

### Execution Steps

* [ ] Extract shell logic from review-code.wf.md into dedicated script
  > TEST: Verify Script Creation
  > Type: Action Validation
  > Assert: Review code script created with proper functionality
  > Command: bin/test --check-script-functionality bin/review-code
* [ ] Extract shell logic from synthesize-reviews.wf.md into dedicated script
* [ ] Update review-code.wf.md to call the new script with parameters
  > TEST: Verify Workflow Update
  > Type: Action Validation
  > Assert: Workflow updated to use script and maintains functionality
  > Command: bin/test --check-workflow-script-integration review-code.wf.md
* [ ] Update synthesize-reviews.wf.md to call the new script with parameters
* [ ] Create test cases for new scripts to ensure reliability
  > TEST: Verify Script Testing
  > Type: Action Validation
  > Assert: Test cases created and scripts pass all tests
  > Command: bin/test --check-script-tests

## Acceptance Criteria

* [ ] AC 1: Complex shell logic extracted from review-code.wf.md and synthesize-reviews.wf.md
* [ ] AC 2: New scripts created with proper error handling and parameter interfaces
* [ ] AC 3: Workflows updated to call scripts and maintain original functionality
* [ ] AC 4: Scripts are tested and validated to work correctly

## Out of Scope

* ❌ Modifying the core logic or functionality of the workflows
* ❌ Extracting simple command calls (only complex shell logic)
* ❌ Creating new workflow features beyond current capabilities

## References

* Review finding: "thats a big one, yes we should have a plan to extract this logic inside the tool, to simplify this workflow"
* Source: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/gpro-review.md
* Problem: "The review-code and synthesize-reviews workflows contain extensive shell script logic. This blurs the line between a guide and a script"
* User note: Complex shell logic should be abstracted into dedicated scripts
