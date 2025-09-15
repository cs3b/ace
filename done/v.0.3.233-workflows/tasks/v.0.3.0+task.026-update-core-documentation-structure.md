---
id: v.0.3.0+task.26
status: done
priority: high
estimate: 6h
dependencies: []
---

# Update Core Documentation Structure

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs/ | sed 's/^/    /'
```

_Result excerpt:_

```
    docs/
    ├── architecture.md
    ├── blueprint.md
    ├── decisions/
    │   └── ADR-001-workflow-self-containment-principle.md
    ├── migrations/
    │   └── 20250627-workflow-self-containment-migration.md
    └── what-do-we-build.md
```

## Objective

Update the core project documentation files to properly embrace and reference the current `docs/**/*.md` directory structure. These files were identified in workflow reviews as potentially containing outdated references or not properly acknowledging the established documentation hierarchy.

## Scope of Work

* Update docs/architecture.md to reflect current docs/ structure
* Update docs/blueprint.md to reference subdirectories correctly
* Update docs/what-do-we-build.md with proper internal links
* Find and fix any places that incorrectly suggest not linking to docs/
* Ensure consistency between permanent context (docs/) vs point-in-time (.ace/taskflow/)

### Deliverables

#### Create

* None - this is an update task

#### Modify

* docs/architecture.md
* docs/blueprint.md
* docs/what-do-we-build.md
* Any workflow files with incorrect guidance about docs/ linking

#### Delete

* None

## Phases

1. Audit current content and references
2. Update core documentation files
3. Search for anti-patterns regarding docs/ linking
4. Fix any incorrect guidance found

## Implementation Plan

### Planning Steps

* [x] Review current content of all three core docs to understand existing structure
  > TEST: Core Docs Review Complete
  > Type: Pre-condition Check
  > Assert: All three core docs have been read and their current state understood
  > Command: bin/test --check-docs-reviewed
* [x] Search codebase for any guidance suggesting not to link to docs/
* [x] Identify all references that need updating

### Execution Steps

* [x] Update docs/architecture.md to properly describe the docs/ directory structure
  > TEST: Architecture Doc Updated
  > Type: Content Validation
  > Assert: architecture.md contains accurate description of docs/ subdirectories
  > Command: bin/test --check-architecture-structure
* [x] Update docs/blueprint.md to reference the correct paths for decisions/, migrations/
* [x] Update docs/what-do-we-build.md with proper internal document references
* [x] Fix any workflow instructions that incorrectly advise against docs/ linking
  > TEST: No Anti-Pattern References
  > Type: Content Search
  > Assert: No files contain guidance against linking to docs/
  > Command: bin/test --check-no-anti-docs-patterns
* [x] Ensure all files distinguish between permanent (docs/) and temporal (.ace/taskflow/) content

## Acceptance Criteria

* [x] All three core docs accurately describe the docs/ directory structure
* [x] No conflicting guidance about linking to docs/ exists in the codebase
* [x] Clear distinction documented between docs/ (permanent) and .ace/taskflow/ (point-in-time)
* [x] All internal references use correct paths

## Out of Scope

* ❌ Moving files between directories
* ❌ Creating new documentation files
* ❌ Updating workflow logic (only fixing incorrect guidance)

## References

* Workflow review reports: dr-report-o3.md, dr-report-gpro.md
* Current docs/ structure audit
* Architecture decision: ADR-001-workflow-self-containment-principle.md
