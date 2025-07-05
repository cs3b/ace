---
id: v.0.3.0+task.67
status: pending
priority: high
estimate: 2h
dependencies: []
---

# Rename ATOM Architecture Guide

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
dev-handbook/guides
├── README.md
├── ai-agent-integration.g.md
├── atom-house-rules.md
├── development
│   ├── README.md
│   ├── commit-message-conventions.md
│   ├── dependency-management.md
│   ├── git-workflow.md
│   ├── testing-guidelines.md
│   └── version-control.md
```

## Objective

Rename the existing ATOM architecture guide from `atom-house-rules.md` to `atom-pattern.g.md` to align with the standard guide naming convention and make it more discoverable. This guide documents the core architectural pattern used throughout the project and is referenced by multiple workflows.

## Scope of Work

* Rename existing ATOM architecture guide to follow standard naming convention
* Update any references to the old filename throughout the project
* Ensure guide is properly indexed and discoverable

### Deliverables

#### Create

* dev-handbook/guides/atom-pattern.g.md (renamed from atom-house-rules.md)

#### Modify

* dev-handbook/guides/README.md (update reference to renamed guide)
* Any other files that reference the old filename

#### Delete

* dev-handbook/guides/atom-house-rules.md (original file)

## Phases

1. Locate and analyze current ATOM architecture guide
2. Search for references to old filename
3. Rename file and update all references
4. Validate all links are functional

## Implementation Plan

### Planning Steps

* [ ] Locate existing ATOM architecture guide and analyze content
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current ATOM guide identified and content analyzed
  > Command: bin/test --check-atom-guide-analyzed
* [ ] Search for all references to atom-house-rules.md in project files
* [ ] Plan systematic renaming approach to avoid broken links

### Execution Steps

* [ ] Rename atom-house-rules.md to atom-pattern.g.md
  > TEST: Verify File Rename
  > Type: Action Validation
  > Assert: File successfully renamed and content preserved
  > Command: bin/test --check-file-rename atom-house-rules.md atom-pattern.g.md
* [ ] Update all references to old filename throughout project
* [ ] Update guides README to reference renamed guide
  > TEST: Verify Reference Updates
  > Type: Action Validation
  > Assert: All references updated and functional
  > Command: bin/test --check-link-integrity atom-pattern.g.md

## Acceptance Criteria

* [ ] AC 1: File renamed from atom-house-rules.md to atom-pattern.g.md
* [ ] AC 2: All references to old filename updated throughout project
* [ ] AC 3: Guide is properly indexed in guides README
* [ ] AC 4: All links to the guide are functional

## Out of Scope

* ❌ Modifying the content of the ATOM architecture guide itself
* ❌ Adding new content to the guide
* ❌ Restructuring the guide's organization

## References

* Review finding: "we already have dev-handbook/guides/atom-house-rules.md -> lets rename it to atom-pattern.g.md"
* Source: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/gpro-review.md
* Current file: dev-handbook/guides/atom-house-rules.md
* User note: Existing guide should be renamed to follow standard naming convention
