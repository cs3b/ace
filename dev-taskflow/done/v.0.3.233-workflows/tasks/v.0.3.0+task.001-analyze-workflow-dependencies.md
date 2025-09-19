---
id: v.0.3.0+task.1
status: done
priority: high
estimate: 8h
dependencies: [v.0.3.0+task.8]
---

# Analyze Current Workflow Dependencies

## 0. Directory Audit ✅

_Command run:_

```bash
find .ace/handbook/workflow-instructions -name "*.wf.md" | sort | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/workflow-instructions/breakdown-notes-into-tasks.wf.md
    .ace/handbook/workflow-instructions/commit.wf.md
    .ace/handbook/workflow-instructions/create-adr.wf.md
    .ace/handbook/workflow-instructions/create-api-docs.wf.md
    .ace/handbook/workflow-instructions/create-reflection-note.wf.md
    .ace/handbook/workflow-instructions/create-release-overview.wf.md
    .ace/handbook/workflow-instructions/create-retrospective-document.wf.md
    .ace/handbook/workflow-instructions/create-review-checklist.wf.md
    .ace/handbook/workflow-instructions/create-test-cases.wf.md
    .ace/handbook/workflow-instructions/create-user-docs.wf.md
    .ace/handbook/workflow-instructions/draft-release.wf.md
    .ace/handbook/workflow-instructions/fix-tests.wf.md
    .ace/handbook/workflow-instructions/initialize-project-structure.wf.md
    .ace/handbook/workflow-instructions/load-env.wf.md
    .ace/handbook/workflow-instructions/save-session-context.md
    .ace/handbook/workflow-instructions/publish-release.wf.md
    .ace/handbook/workflow-instructions/review-task.wf.md
    .ace/handbook/workflow-instructions/review-tasks-board-status.wf.md
    .ace/handbook/workflow-instructions/update-blueprint.wf.md
    .ace/handbook/workflow-instructions/update-roadmap.wf.md
    .ace/handbook/workflow-instructions/work-on-task.wf.md

Total files: 21
```

## Objective

Analyze all 21 existing workflow instruction files to identify cross-dependencies, external references, and missing context that prevents workflows from being self-contained and independently executable by coding agents.

## Scope of Work

- Audit all 21 workflow instruction files for external dependencies and cross-references
- Document missing high-level execution plans in workflows
- Identify workflows lacking project context loading sections
- Analyze patterns for standardizing workflow structure across all files
- Create comprehensive dependency mapping and refactoring plan

### Deliverables

#### Create

- .ace/taskflow/backlog/v.0.3.0-workflows/researches/workflow-dependency-analysis.md

#### Modify

- None (analysis phase)

#### Delete

- None

## Phases

1. Audit existing workflow files
2. Map dependencies and references
3. Identify missing context areas
4. Document findings and recommendations

## Implementation Plan

### Planning Steps

- [x] Survey all workflow instruction files in .ace/handbook/workflow-instructions/
  > TEST: Complete Workflow Inventory
  > Type: Pre-condition Check
  > Assert: All workflow files are identified and catalogued
  > Command: bin/test --check-file-exists .ace/taskflow/backlog/v.0.3.0-workflows/researches/workflow-inventory.md
- [x] Research coding agent integration requirements for Claude Code, Windsurf, and Zed
- [x] Analyze patterns in current workflow cross-references

### Execution Steps

- [x] Read and analyze each workflow instruction file for external dependencies
- [x] Document all cross-references to other workflows, guides, and templates
  > TEST: Cross-Reference Documentation Complete
  > Type: Action Validation
  > Assert: All workflow cross-references are documented
  > Command: bin/test --check-analysis-completeness workflow-dependency-analysis.md
- [x] Identify context gaps that prevent independent execution
- [x] Create dependency mapping visualization
- [x] Write comprehensive analysis report with recommendations

## Acceptance Criteria

- [x] All workflow files analyzed for dependencies
- [x] Cross-reference mapping complete and documented
- [x] Context gaps identified with specific recommendations
- [x] Analysis report provides clear refactoring roadmap

## Out of Scope

- ❌ Actually refactoring workflows (separate task)
- ❌ Creating new workflow templates
- ❌ Agent-specific integration implementation

## References

- .ace/handbook/workflow-instructions/ (all workflow files)
- .ace/handbook/guides/draft-release/ (template references)
- CLAUDE.md (project context)
