---
id: v.0.3.0+task.68
status: pending
priority: high
estimate: 2h
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

Complete the standardization of commit commands by updating remaining inconsistencies to use `bin/gc -i` (git commit with intention) as the default approach. Recent version control documentation consolidation work (commit 2121aa8) has already updated `commit.wf.md` to reference proper commit message standards, but some inconsistencies remain, particularly in the Project Blueprint which still references `bin/git-commit-with-message`.

## Scope of Work

* Update commit.wf.md to use `bin/gc -i` for actual commit commands (workflow already references proper message standards)
* Update Project Blueprint to replace `bin/git-commit-with-message` with standardized `bin/gc -i` approach
* Search for and update any remaining references to inconsistent commit commands
* Validate that all documentation consistently references the intention-based commit approach

**Note**: Recent consolidation work (commit 2121aa8) has already streamlined commit.wf.md to reference the Version Control Message Guide, but the actual commit commands in the workflow still use standard `git commit`.

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

1. Verify current state post-consolidation (commit 2121aa8)
2. Focus on remaining inconsistencies (primarily blueprint.md)
3. Update commit.wf.md to use bin/gc -i for actual commit commands
4. Validate final consistency across all documentation

## Implementation Plan

### Planning Steps

* [ ] Verify bin/gc -i command functionality and behavior
  > TEST: Command Functionality Check
  > Type: Pre-condition Check
  > Assert: bin/gc -i command exists and works as expected
  > Command: bin/gc -i "test: verify commit command functionality"
* [ ] Audit remaining commit command inconsistencies post-consolidation
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All remaining inconsistencies identified (focus on blueprint.md)
  > Command: bin/test --check-remaining-commit-inconsistencies
* [ ] Plan focused update approach for remaining files

### Execution Steps

* [ ] Update Project Blueprint to replace bin/git-commit-with-message with bin/gc -i
  > TEST: Verify Blueprint Update
  > Type: Action Validation
  > Assert: Blueprint updated to reference bin/gc -i approach
  > Command: bin/test --check-blueprint-commit-command
* [ ] Update commit.wf.md to use bin/gc -i for actual commit commands
  > TEST: Verify Commit Workflow Update
  > Type: Action Validation
  > Assert: Commit workflow updated to use bin/gc -i consistently
  > Command: bin/test --check-commit-workflow-standardized
* [ ] Search for and update any remaining references to inconsistent commit commands
  > TEST: Verify Final Consistency
  > Type: Action Validation
  > Assert: All documentation consistently references bin/gc -i approach
  > Command: bin/test --check-final-commit-command-consistency

## Acceptance Criteria

* [ ] AC 1: Project Blueprint updated to use bin/gc -i instead of bin/git-commit-with-message
* [ ] AC 2: commit.wf.md updated to use bin/gc -i for actual commit commands
* [ ] AC 3: All documentation consistently references intention-based commit approach
* [ ] AC 4: No conflicting commit command references remain in documentation
* [ ] AC 5: bin/gc -i command verified to work correctly

## Out of Scope

* ❌ Modifying the actual bin/gc script implementation
* ❌ Creating new commit command variations
* ❌ Changing git workflow patterns beyond command standardization

## References

* Review finding: "we should standardize use of bin/gc -i as default way"
* Source: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/gpro-review.md
* Inconsistency: "The Project Blueprint references bin/git-commit-with-message, but commit.wf.md details using the standard git commit command"
* User note: "we should standardize use of bin/gc -i as default way"
* **Recent context**: Version control documentation consolidation completed (commit 2121aa8, 2025-07-05)
* **Current state**: commit.wf.md already references proper message standards but uses standard git commands
* **Remaining gap**: blueprint.md still references bin/git-commit-with-message (line 133)
