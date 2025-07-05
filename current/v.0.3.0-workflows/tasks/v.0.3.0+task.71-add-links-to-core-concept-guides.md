---
id: v.0.3.0+task.71
status: done
priority: medium
estimate: 4h
dependencies: [v.0.3.0+task.65, v.0.3.0+task.67]
---

# Add Links to Core Concept Guides

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

Add explicit Markdown links to core concept guides (ATOM Architecture and Conventional Commits) from all workflows that reference these concepts. This will improve discoverability and ensure AI agents can easily access foundational information when working with workflows.

## Scope of Work

* Identify all workflows that reference "Conventional Commits" or "ATOM Architecture"
* Add proper markdown links to the respective guides
* Ensure links are contextually appropriate and helpful
* Validate all links are functional

### Deliverables

#### Create

* None

#### Modify

* All workflow files that reference core concepts (to add links)
* Any other documentation that references these concepts

#### Delete

* None

## Phases

1. Search for workflows mentioning "Conventional Commits" or "ATOM Architecture"
2. Identify appropriate link placement locations
3. Add markdown links to relevant guides
4. Validate all links are functional

## Implementation Plan

### Planning Steps

* [ ] Search all workflow files for references to "Conventional Commits" and "ATOM Architecture"
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All references to core concepts identified across workflows
  > Command: bin/test --check-core-concept-references
* [ ] Identify contextually appropriate locations for adding links
* [ ] Plan link format and placement strategy

### Execution Steps

* [ ] Add links to Conventional Commits guide in workflows that reference commit standards
  > TEST: Verify Conventional Commits Links
  > Type: Action Validation
  > Assert: Proper links added to version control message guide
  > Command: bin/test --check-conventional-commits-links
* [ ] Add links to ATOM Architecture guide in workflows that reference the pattern
  > TEST: Verify ATOM Architecture Links
  > Type: Action Validation
  > Assert: Proper links added to atom-pattern.g.md guide
  > Command: bin/test --check-atom-architecture-links
* [ ] Validate all added links are functional and point to correct guides
  > TEST: Verify Link Integrity
  > Type: Action Validation
  > Assert: All links functional and point to correct target guides
  > Command: bin/test --check-link-integrity-core-concepts

## Acceptance Criteria

* [ ] AC 1: All workflows referencing "Conventional Commits" include links to version control message guide
* [ ] AC 2: All workflows referencing "ATOM Architecture" include links to atom-pattern.g.md guide
* [ ] AC 3: Links are contextually appropriate and helpful
* [ ] AC 4: All links are functional and point to correct guides

## Out of Scope

* ❌ Adding links to workflows that don't reference these concepts
* ❌ Creating new concept guides (dependencies handle this)
* ❌ Modifying the content of existing guides

## References

* Review finding: "we should review links to guides"
* Source: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/gpro-review.md
* Problem: "Workflows mentioning 'Conventional Commits' or 'ATOM Architecture' should link to the (currently missing) guides for those concepts"
* Dependencies: Must wait for version-control-message.g.md and atom-pattern.g.md guides to be created/renamed
