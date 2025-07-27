---
id: v.0.3.0+task.16
status: done
priority: high
estimate: 4h
dependencies: []
---

# Review and Update Initialize Project Structure Workflow

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/workflow-instructions
    ├── initialize-project-structure.wf.md
    └── [other workflow files]
```

## Objective

Review and update `dev-handbook/workflow-instructions/initialize-project-structure.wf.md` to fix outdated references and requirements that no longer align with the current project structure and standards.

**Original requirement**: The workflow contains several outdated references that need to be corrected to reflect the current project structure and eliminate references to deprecated directories and patterns.

## Scope of Work

- Replace old naming convention `docs-dev` with current `dev-handbook`
- Remove references to deprecated `dev-taskflow/decisions` directory (no longer used)
- Update documentation paths to reflect current structure (`docs/` not `dev-taskflow/`)
- Update submodule verification to only check for two modules (`dev-handbook` and `dev-tools`)
- Update binstubs creation to reference correct source path (`dev-tools/exe-old/_binstubs`)
- Remove branch switching requirements for submodules
- Update all embedded templates and examples to use correct paths
- Review workflow against workflow instruction standards and embedding tests

### Deliverables

#### Create

- None (updating existing file)

#### Modify

- `dev-handbook/workflow-instructions/initialize-project-structure.wf.md`

#### Delete

- None

## Phases

1. Research/Analysis - Identify all outdated references and patterns in the workflow
2. Design/Planning - Map old references to new correct paths and requirements  
3. Implementation - Update workflow with correct references and remove deprecated patterns
4. Testing/Validation - Verify all paths and references are accurate and functional

## Implementation Plan

### Planning Steps

- [x] Audit all references to `docs-dev` in the workflow file
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: All `docs-dev` references identified for replacement
  > Command: grep -n "docs-dev" dev-handbook/workflow-instructions/initialize-project-structure.wf.md

- [x] Identify all references to `dev-taskflow/decisions` directory
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: All deprecated decision directory references identified
  > Command: grep -n "dev-taskflow/decisions" dev-handbook/workflow-instructions/initialize-project-structure.wf.md

- [x] Locate documentation path references that need updating
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Outdated documentation paths identified
  > Command: grep -n "dev-taskflow/what-do-we-build\|dev-taskflow/architecture\|dev-taskflow/blueprint" dev-handbook/workflow-instructions/initialize-project-structure.wf.md

- [x] Find submodule verification references requiring updates
  > TEST: Pre-condition Check
  > Type: Pre-condition Check  
  > Assert: Submodule verification patterns identified
  > Command: grep -n -A5 -B5 "submodule" dev-handbook/workflow-instructions/initialize-project-structure.wf.md

- [x] Locate binstubs path references needing correction
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Outdated binstubs paths identified  
  > Command: grep -n "_binstubs\|tools/_binstubs" dev-handbook/workflow-instructions/initialize-project-structure.wf.md

- [x] Review workflow against workflow instruction standards
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Workflow standards guide available for reference
  > Command: ls -la dev-handbook/guides/.meta/workflow-instructions-definition.g.md

- [x] Review workflow against embedding tests guide
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Embedding tests guide available for reference
  > Command: ls -la dev-handbook/guides/.meta/workflow-instructions-embeding-tests.g.md

### Execution Steps

- [x] Replace all `docs-dev` references with `dev-handbook`
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: No `docs-dev` references remain in the workflow
  > Command: grep "docs-dev" dev-handbook/workflow-instructions/initialize-project-structure.wf.md || echo "No matches found"

- [x] Remove all references to `dev-taskflow/decisions` directory creation
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: No `dev-taskflow/decisions` references remain
  > Command: grep "dev-taskflow/decisions" dev-handbook/workflow-instructions/initialize-project-structure.wf.md || echo "No matches found"

- [x] Update documentation paths from `dev-taskflow/` to `docs/` for core docs
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Core documentation references use `docs/` paths
  > Command: grep -E "docs/(what-do-we-build|architecture|blueprint)\.md" dev-handbook/workflow-instructions/initialize-project-structure.wf.md

- [x] Update submodule verification to only check two modules (dev-handbook, dev-tools)
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Submodule references updated to current structure
  > Command: grep -C3 "submodule" dev-handbook/workflow-instructions/initialize-project-structure.wf.md

- [x] Update binstubs source path to `dev-tools/exe-old/_binstubs`
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Binstubs path references correct source location
  > Command: grep "dev-tools/exe-old/_binstubs" dev-handbook/workflow-instructions/initialize-project-structure.wf.md

- [x] Remove branch switching requirements for submodules
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: No branch switching instructions remain
  > Command: grep -i "checkout.*branch\|switch.*branch" dev-handbook/workflow-instructions/initialize-project-structure.wf.md || echo "No matches found"

- [x] Update Project Context Loading section to use correct paths
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Project Context Loading uses `docs/` paths
  > Command: grep -A5 "Project Context Loading" dev-handbook/workflow-instructions/initialize-project-structure.wf.md | grep "docs/"

- [x] Apply workflow instruction standards from definition guide
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Workflow follows standard structure and format
  > Command: diff -u <(grep "^##" dev-handbook/guides/.meta/workflow-instructions-definition.g.md) <(grep "^##" dev-handbook/workflow-instructions/initialize-project-structure.wf.md) || echo "Structure differences noted"

- [x] Apply embedding tests standards from embedding tests guide
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Workflow follows embedding test patterns
  > Command: grep -c "TEST:" dev-handbook/workflow-instructions/initialize-project-structure.wf.md || echo "No embedded tests found"

## Acceptance Criteria

- [x] All `docs-dev` references replaced with `dev-handbook`
- [x] All `dev-taskflow/decisions` references removed (directory no longer used)
- [x] Core documentation paths updated to use `docs/` instead of `dev-taskflow/`
- [x] Submodule verification updated to only check two modules (dev-handbook and dev-tools)
- [x] Binstubs creation references correct source path (`dev-tools/exe-old/_binstubs`)
- [x] Branch switching requirements for submodules removed
- [x] Project Context Loading section uses correct `docs/` paths
- [x] All embedded templates and examples use updated paths
- [x] Workflow is internally consistent with no contradictory path references
- [x] All referenced paths exist in the current project structure
- [x] Workflow follows workflow instruction definition standards
- [x] Workflow includes appropriate embedded tests following embedding tests guide

## Out of Scope

- ❌ Creating new workflow instructions (only updating existing)
- ❌ Updating other workflow files beyond initialize-project-structure.wf.md
- ❌ Modifying project structure to match old references
- ❌ Creating deprecated directories that are being removed from references
- ❌ Updating guides or other documentation files (separate tasks)

## References

- Current project structure: Root directory with dev-handbook/, dev-tools/, docs/ subdirectories
- Binstubs location: dev-tools/exe-old/_binstubs/
- Core documentation location: docs/ (what-do-we-build.md, architecture.md, blueprint.md)
- Current submodules: dev-handbook, dev-tools (not dev-taskflow)
- Task creation standard: Zero-padded task IDs (v.0.3.0+task.16)
- Workflow instruction standards: dev-handbook/guides/.meta/workflow-instructions-definition.g.md
- Embedding tests guide: dev-handbook/guides/.meta/workflow-instructions-embeding-tests.g.md
