---
id: v.0.3.0+task.9
status: done
priority: high
estimate: 8h
dependencies: []
---

# Create Migration Guide for Self-Contained Workflows

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
dev-handbook/guides/
├── README.md
├── .meta/
├── migration/
└── [other guide directories...]
```

## Objective

Create a comprehensive migration guide (`guides/migration/migrating-to-self-contained-workflows.g.md`) to help developers and AI agents understand and implement the fundamental shift from reference-based workflows to self-contained, independent workflow instructions. This breaking change requires clear documentation to prevent system failure and ensure successful adoption of the new paradigm.

**Original requirement**: Documentation review identified critical need for migration guide due to breaking changes in workflow architecture.

## Scope of Work

- Create comprehensive migration documentation explaining the paradigm shift
- Document all deprecated workflows and their replacements
- Provide step-by-step refactoring checklist for legacy workflows
- Establish clear principles for the new self-containment standard

### Deliverables

#### Create

- dev-handbook/guides/migration/migrating-to-self-contained-workflows.g.md
- dev-handbook/guides/migration/ (directory if it doesn't exist)

#### Modify

- None

#### Delete

- None

## Phases

1. Research/Analysis - Review all workflow changes and identify migration patterns
2. Design/Planning - Structure comprehensive migration guide content
3. Implementation - Write detailed migration guide with examples and checklists
4. Testing/Validation - Verify guide completeness and accuracy

## Implementation Plan

### Planning Steps

- [x] Analyze all workflow changes from the diff to understand full scope of breaking changes
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: All workflow changes are documented and categorized
  > Command: `find dev-handbook/workflow-instructions -name "*.wf.md" | wc -l`

- [x] Identify all deprecated workflows and map to new replacements
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Complete mapping of old to new workflow patterns exists
  > Command: `ls dev-handbook/workflow-instructions/*.wf.md`

### Execution Steps

- [x] Create migration directory structure if needed
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Migration directory exists and is properly structured
  > Command: `ls -la dev-handbook/guides/migration/`

- [x] Write comprehensive migration guide with all required sections:
  - Introduction explaining the paradigm shift rationale
  - Core principles of self-containment (Embed, Don't Reference)
  - Deprecated workflows table with replacements
  - Step-by-step refactoring checklist
  - Examples of before/after workflow transformations
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Migration guide exists and contains all required sections
  > Command: `grep -E "^## |^### " dev-handbook/guides/migration/migrating-to-self-contained-workflows.g.md`

- [x] Include specific examples from actual workflow transformations
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Guide contains practical examples and checklists
  > Command: `grep -c "checklist\|example" dev-handbook/guides/migration/migrating-to-self-contained-workflows.g.md`

## Acceptance Criteria

- [x] Migration guide file created at specified path
- [x] Guide explains the "why" behind shift to self-containment
- [x] Complete table mapping deprecated workflows to replacements
- [x] Step-by-step refactoring checklist provided
- [x] Examples demonstrate transformation from reference-based to self-contained
- [x] Guide follows handbook formatting and style conventions
- [x] All deprecated workflow files are documented with migration paths
- [x] Guide addresses both human developers and AI agents

## Out of Scope

- ❌ Actually refactoring existing workflows (separate tasks)
- ❌ Updating other guides or cross-references (separate tasks)
- ❌ Creating new ADRs (separate task)
- ❌ Implementing automated validation tools (future enhancement)

## References

- Original requirement: Handbook review report section "CRITICAL UPDATES"
- Related workflow changes: All workflow instructions in current diff
- New principles: dev-handbook/guides/.meta/workflow-instructions-definition.g.md
