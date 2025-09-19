---
id: v.0.2.0+task.33
status: done
priority: low
estimate: 2h
dependencies: [v.0.2.0+task.24, v.0.2.0+task.25, v.0.2.0+task.26, v.0.2.0+task.27, v.0.2.0+task.28, v.0.2.0+task.29, v.0.2.0+task.30, v.0.2.0+task.31, v.0.2.0+task.32]
---

# Add Cross-References Between Updated Documentation

## 0. Directory Audit ✅

_Command run:_

```bash
find . -name "*.md" -path "./docs*" -o -path "./README.md" | sort | sed 's/^/    /'
```

_Result excerpt:_

```
    ./README.md
    ./docs-dev/guides/atom-house-rules.md (to be created)
    ./docs-dev/guides/coding-standards.md
    ./docs-dev/guides/error-handling.md
    ./docs-dev/guides/performance.md
    ./docs-dev/guides/project-management.md
    ./docs-dev/guides/task-definition.g.md
    ./docs-dev/guides/testing.md
    ./docs-project/README.md
    ./docs-project/architecture.md
    ./docs-project/blueprint.md
    ./docs-project/what-do-we-build.md
    ./docs-project/why-do-we-build.md
    ./docs/DEVELOPMENT.md
    ./docs/SETUP.md
    ./docs/architecture/ADR-001-CI-Aware-VCR-Configuration.md
    ./docs/architecture/ADR-002-ATOM-Architecture-House-Rules.md (to be created)
    ./docs/model-management.md (to be created)
```

## Objective

Add cross-references between all documentation files updated in v.0.2.0 to ensure users and developers can easily navigate between related topics. This improves documentation discoverability and creates a cohesive documentation network.

## Scope of Work

- Add links from README.md to the new model-management.md guide
- Link architecture.md to the new ATOM house rules guide
- Ensure ADR-001 is referenced from DEVELOPMENT.md's testing section
- Add bidirectional links between related documentation
- Verify all cross-references use correct relative paths

### Deliverables

#### Modify

- README.md
- docs-project/architecture.md
- docs/DEVELOPMENT.md
- docs/model-management.md (once created)
- docs-dev/guides/atom-house-rules.md (once created)
- docs/architecture/ADR-002-ATOM-Architecture-House-Rules.md (once created)

## Phases

1. Map all cross-reference requirements
2. Identify optimal link placement in each document
3. Add forward references
4. Add backward references
5. Validate all links work correctly

## Implementation Plan

### Planning Steps

* [x] Create a cross-reference matrix showing which documents should link to each other
  > TEST: Cross-Reference Matrix Complete
  > Type: Pre-condition Check
  > Assert: All required cross-references are identified and documented
  > Command: grep -l "model-management\|atom-house-rules\|ADR-" docs*/*.md README.md | wc -l
* [x] Identify natural insertion points for links in each document
* [x] Plan bidirectional linking strategy

### Execution Steps

- [x] Add link from README.md to docs/model-management.md in relevant sections
  > TEST: README Links to Model Management
  > Type: Action Validation
  > Assert: README contains link to model management guide
  > Command: grep -E "\[.*\]\(.*model-management\.md\)" README.md
- [x] Add link from docs-project/architecture.md to docs-dev/guides/atom-house-rules.md
  > TEST: Architecture Links to ATOM Guide
  > Type: Action Validation
  > Assert: Architecture doc links to ATOM house rules guide
  > Command: grep -E "\[.*\]\(.*atom-house-rules\.md\)" docs-project/architecture.md
- [x] Add ADR-001 reference in docs/DEVELOPMENT.md testing section
  > TEST: Development Links to ADR-001
  > Type: Action Validation
  > Assert: DEVELOPMENT.md references ADR-001 in testing context
  > Command: grep -E "\[.*ADR-001.*\]|ADR-001" docs/DEVELOPMENT.md
- [x] Add backward reference from model-management.md to README.md and SETUP.md
- [x] Add reference from atom-house-rules.md to architecture.md and ADR-006
- [x] Add reference from ADR-006 to architecture.md and atom-house-rules.md
  > TEST: All Cross-References Valid
  > Type: Action Validation
  > Assert: All markdown links resolve to existing files
  > Command: find . -name "*.md" -exec grep -l "\[.*\](" {} \; | xargs -I {} sh -c 'grep -o "\[.*\]([^)]*)" {} | grep -v http'
- [x] Verify all relative paths are correct and follow project conventions

## Acceptance Criteria

- [x] README.md links to the new model-management.md guide
- [x] architecture.md links to the ATOM house rules guide
- [x] DEVELOPMENT.md references ADR-001 for localhost testing patterns
- [x] All new guides include appropriate back-references to parent documents
- [x] Cross-references use descriptive link text, not just "click here"
- [x] All links use correct relative paths from the project root
- [x] No broken links exist in the updated documentation
- [x] Related documents form a navigable network

## Out of Scope

- ❌ Adding external links or references
- ❌ Creating a central documentation index
- ❌ Updating links in documents not modified in v.0.2.0
- ❌ Adding navigation headers or footers to documents

## References

- Documentation Review: docs-project/current/v.0.2.0-synapse/code-review/task-4/docs-review-gemini-2.5-pro.md
- Cross-reference requirements from review:
  - README.md → docs/model-management.md
  - docs-project/architecture.md → docs-dev/guides/atom-house-rules.md
  - docs/DEVELOPMENT.md → docs/architecture/ADR-001
  - Bidirectional links between related guides and ADRs