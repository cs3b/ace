---
id: v.0.3.0+task.51
status: pending
priority: high
estimate: 3h
dependencies: []
---

# Migrate Deprecated Tool Dependencies

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools
    ├── bin
    ├── exe
    ├── exe-old
    ├── lib
    └── spec
```

## Objective

Investigate and resolve the dev-tools/exe-old/ dependency in initialize-project-structure.wf.md workflow. Create a migration plan to move from deprecated tools to current versions, addressing the security/stability risk identified by Google Pro reviewer.

## Scope of Work

* Audit all references to exe-old directory across the codebase
* Identify which tools are being used from exe-old
* Create migration plan to current exe/ directory tools
* Update workflows to use non-deprecated tool paths
* Document the migration approach for future reference

### Deliverables

#### Create

* dev-taskflow/current/v.0.3.0-workflows/researches/tool-migration-plan.md - Migration strategy document

#### Modify

* dev-handbook/workflow-instructions/initialize-project-structure.wf.md - Update tool references
* Any other workflows using exe-old tools

#### Delete

* None (exe-old removal is out of scope - may be needed for backward compatibility)

## Phases

1. Audit - Find all exe-old dependencies
2. Analyze - Compare exe-old vs exe tools
3. Plan - Create migration strategy
4. Migrate - Update tool references
5. Document - Record migration approach

## Implementation Plan

### Planning Steps

* [ ] Search for all references to exe-old across the codebase
  > TEST: Dependency Audit Complete
  > Type: Pre-condition Check
  > Assert: All exe-old references identified
  > Command: rg "exe-old" --type md
* [ ] List tools in exe-old and their exe equivalents
* [ ] Analyze differences between old and new tool versions
* [ ] Design migration approach that maintains functionality

### Execution Steps

* [ ] Create tool migration plan document
* [ ] Update initialize-project-structure.wf.md to use current tools
  > TEST: Workflow Updated
  > Type: Path Validation
  > Assert: No exe-old references remain in workflow
  > Command: rg "exe-old" dev-handbook/workflow-instructions/initialize-project-structure.wf.md
* [ ] Update any other workflows using deprecated tools
* [ ] Test updated workflows function correctly
* [ ] Document tool mapping for future reference
  > TEST: Migration Complete
  > Type: Integration Test
  > Assert: All workflows use current tool paths
  > Command: bin/test --check-tool-migration

## Acceptance Criteria

* [ ] AC 1: All exe-old dependencies identified and documented
* [ ] AC 2: Migration plan created with tool mappings
* [ ] AC 3: initialize-project-structure.wf.md uses only current tools
* [ ] AC 4: All workflows updated to remove deprecated dependencies
* [ ] AC 5: Migration approach documented for future reference

## Out of Scope

* ❌ Deleting exe-old directory (may break backward compatibility)
* ❌ Modifying the tools themselves
* ❌ Creating new tools

## References

* Review report: dev-taskflow/current/v.0.3.0-workflows/code_review/20250703-232338-handbook-workflows/cr-report.md
* Deprecated tools: dev-tools/exe-old/
* Current tools: dev-tools/exe/
* Affected workflow: dev-handbook/workflow-instructions/initialize-project-structure.wf.md