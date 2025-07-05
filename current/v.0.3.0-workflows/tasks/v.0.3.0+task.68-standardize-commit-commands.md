---
id: v.0.3.0+task.68
status: pending
priority: high
estimate: 4h
dependencies: []
---

# Standardize Commit Commands

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

Resolve the inconsistency between documented commit commands by standardizing on `bin/gc -i` (git commit with intention) as the default approach throughout all workflows and documentation. This addresses the conflict between the Project Blueprint advocating for `bin/git-commit-with-message` and `commit.wf.md` detailing the use of standard `git commit`.

## Scope of Work

* Update commit.wf.md to use `bin/gc -i` as the primary commit method
* Update Project Blueprint to reflect the standardized commit approach
* Search for and update any other references to inconsistent commit commands
* Ensure all documentation consistently references the intention-based commit approach

### Deliverables

#### Create

* None

#### Modify

* dev-handbook/workflow-instructions/commit.wf.md (update to use bin/gc -i)
* docs/blueprint.md (update commit command references)
* Any other files referencing inconsistent commit commands

#### Delete

* None

## Phases

1. Audit current commit command usage across all documentation
2. Identify all inconsistencies between different commit approaches
3. Update all references to use standardized bin/gc -i approach
4. Validate consistency across all documentation

## Implementation Plan

### Planning Steps

* [ ] Audit all commit command references in workflows and documentation
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All commit command inconsistencies identified and catalogued
  > Command: bin/test --check-commit-command-audit
* [ ] Analyze the intention-based commit approach in existing bin/gc script
* [ ] Plan systematic update approach for all affected files

### Execution Steps

* [ ] Update commit.wf.md to use bin/gc -i as primary commit method
  > TEST: Verify Commit Workflow Update
  > Type: Action Validation
  > Assert: Commit workflow updated to use bin/gc -i consistently
  > Command: bin/test --check-commit-workflow-standardized
* [ ] Update Project Blueprint to reference standardized commit approach
* [ ] Search for and update any other references to inconsistent commit commands
  > TEST: Verify Command Consistency
  > Type: Action Validation
  > Assert: All documentation consistently references bin/gc -i approach
  > Command: bin/test --check-commit-command-consistency

## Acceptance Criteria

* [ ] AC 1: commit.wf.md updated to use bin/gc -i as primary commit method
* [ ] AC 2: Project Blueprint updated to reflect standardized commit approach
* [ ] AC 3: All documentation consistently references intention-based commit approach
* [ ] AC 4: No conflicting commit command references remain in documentation

## Out of Scope

* ❌ Modifying the actual bin/gc script implementation
* ❌ Creating new commit command variations
* ❌ Changing git workflow patterns beyond command standardization

## References

* Review finding: "we should standardize use of bin/gc -i as default way"
* Source: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/gpro-review.md
* Inconsistency: "The Project Blueprint references bin/git-commit-with-message, but commit.wf.md details using the standard git commit command"
* User note: "we should standardize use of bin/gc -i as default way"