---
id: v.0.3.0+task.11
status: pending
priority: high
estimate: 16h
dependencies: [v.0.3.0+task.9]
---

# Audit and Refactor Remaining Workflows for Self-Containment

## 0. Directory Audit ✅

_Command run:_
```bash
tree -L 1 dev-handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_
```
dev-handbook/workflow-instructions/
├── README.md
├── *.wf.md files
└── [workflow files to be audited]
```

## Objective

Systematically audit and refactor ALL remaining workflow instruction files (`.wf.md`) that were not updated in the recent diff to ensure they comply with the new self-containment standard. Any workflow that doesn't follow the new embedded-content pattern is effectively broken and must be updated to prevent system failure.

**Original requirement**: Documentation review identified that all non-compliant workflows must be audited and refactored to align with the new self-containment principle.

## Scope of Work

- Audit every workflow file for compliance with new self-containment standard
- Identify workflows that still use reference-based patterns
- Refactor non-compliant workflows to embed all necessary content
- Ensure all workflows have required sections (Project Context Loading, etc.)
- Validate that no workflows have cross-dependencies

### Deliverables

#### Create
- None (refactoring existing files)

#### Modify
- All non-compliant workflow instruction files in dev-handbook/workflow-instructions/
- Any workflow files lacking required self-containment sections

#### Delete
- Any workflow files that are fully obsoleted by refactored workflows

## Phases

1. Research/Analysis - Complete audit of all workflow files against new standard
2. Design/Planning - Prioritize refactoring order and identify content to embed
3. Implementation - Refactor each non-compliant workflow systematically
4. Testing/Validation - Verify all workflows are self-contained and functional

## Implementation Plan

### Planning Steps

* [ ] Create comprehensive list of all workflow files in the system
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Complete inventory of all workflow files exists
  > Command: `find dev-handbook/workflow-instructions -name "*.wf.md" | sort`

* [ ] Audit each workflow against self-containment criteria:
  - Has Project Context Loading section
  - Has embedded templates (no external template references)
  - Has embedded common patterns (no guide references for procedures)
  - No cross-workflow dependencies in prerequisites
  - No procedural links to guides
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Audit results categorize all workflows as compliant/non-compliant
  > Command: `grep -L "Project Context Loading" dev-handbook/workflow-instructions/*.wf.md`

* [ ] Prioritize refactoring order based on workflow importance and complexity
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Refactoring plan exists with clear priorities
  > Command: `wc -l dev-handbook/workflow-instructions/*.wf.md | sort -n`

### Execution Steps

- [ ] For each non-compliant workflow, perform systematic refactoring:
  1. Add Project Context Loading section listing required files
  2. Identify and copy essential content from referenced guides
  3. Embed templates directly in workflow under Embedded Templates
  4. Convert cross-workflow dependencies to file/state prerequisites
  5. Add High-Level Execution Plan and Common Patterns sections
  6. Remove all procedural references to external guides
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Each refactored workflow has all required sections
  > Command: `grep -E "^## Project Context Loading|^## Embedded Templates|^## Common Patterns" $WORKFLOW_FILE | wc -l`

- [ ] Validate each refactored workflow is fully self-contained
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: No workflows contain procedural links to guides or other workflows
  > Command: `grep -E "\[.*\]\(.*\.g\.md\)|see.*workflow|run.*workflow" dev-handbook/workflow-instructions/*.wf.md`

- [ ] Remove or consolidate any workflows that are completely redundant after refactoring
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: No duplicate or obsolete workflows remain
  > Command: `find dev-handbook/workflow-instructions -name "*.wf.md" | xargs grep -l "DEPRECATED\|OBSOLETE"`

## Acceptance Criteria

- [ ] All workflow files audited against self-containment standard
- [ ] Every workflow has Project Context Loading section
- [ ] All templates and patterns embedded directly in workflows
- [ ] No workflows contain procedural references to guides
- [ ] No cross-workflow dependencies exist in prerequisites
- [ ] All workflows follow the new structure from workflow-instructions-definition.g.md
- [ ] Redundant or obsolete workflows removed or consolidated
- [ ] All workflows can be executed independently by AI agents

## Out of Scope

- ❌ Updating guides to remove procedural content (separate task)
- ❌ Fixing cross-references in guides (separate task)  
- ❌ Creating new conceptual guides (separate task)
- ❌ Building automated validation tools (future enhancement)

## References

- Original requirement: Documentation review report "CRITICAL UPDATES"
- New standard: dev-handbook/guides/.meta/workflow-instructions-definition.g.md
- Migration guide: Task v.0.3.0+task.9 (dependency)
- Examples: Recently refactored workflows in current diff