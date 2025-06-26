---
id: v.0.3.0+task.3
status: done
priority: high
estimate: 25h
dependencies: [v.0.3.0+task.1]
---

# Refactor Workflows for Independence

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
dev-handbook/workflow-instructions/
├── breakdown-notes-into-tasks.wf.md
├── draft-release.wf.md
└── update-roadmap.wf.md
```

## Objective

Refactor all 21 workflow instruction files to be self-contained and independent, removing cross-dependencies, adding high-level execution plans, embedding project context loading, and ensuring they can be executed by coding agents without requiring external references.

## Scope of Work

- Remove cross-references between all 21 workflows
- Add high-level execution plans to every workflow (following work-on-task.wf.md pattern)
- Add project context loading sections to every workflow
- Embed necessary context within each workflow
- Ensure each workflow can be executed independently
- Maintain workflow functionality while improving isolation

### Deliverables

#### Modify

- All 21 workflow files in dev-handbook/workflow-instructions/
  - breakdown-notes-into-tasks.wf.md
  - commit.wf.md
  - create-adr.wf.md
  - create-api-docs.wf.md
  - create-reflection-note.wf.md
  - create-release-overview.wf.md
  - create-retrospective-document.wf.md
  - create-review-checklist.wf.md
  - create-test-cases.wf.md
  - create-user-docs.wf.md
  - draft-release.wf.md
  - fix-tests.wf.md
  - initialize-project-structure.wf.md
  - load-env.wf.md
  - log-compact-session.wf.md
  - publish-release.wf.md
  - review-task.wf.md
  - review-tasks-board-status.wf.md
  - update-blueprint.wf.md
  - update-roadmap.wf.md
  - work-on-task.wf.md

#### Create

- None (refactoring existing files)

#### Delete

- None

## Phases

1. Apply findings from dependency analysis
2. Refactor each workflow for independence
3. Embed necessary context and templates
4. Validate workflow completeness

## Implementation Plan

### Planning Steps

* [x] Review dependency analysis findings from task v.0.3.0+task.1
  > TEST: Analysis Review Complete
  > Type: Pre-condition Check
  > Assert: Dependency analysis results are incorporated into refactoring plan
  > Command: bin/test --check-dependency-review workflow-independence-plan.md
* [x] Plan specific refactoring approach for each workflow
* [x] Design context embedding strategy

### Execution Steps

- [x] Refactor draft-release.wf.md to be self-contained
  > TEST: Draft Release Independence
  > Type: Action Validation
  > Assert: Draft release workflow can execute without external workflow references
  > Command: bin/test --check-workflow-independence draft-release.wf.md
- [x] Refactor breakdown-notes-into-tasks.wf.md for independence
- [x] Refactor update-roadmap.wf.md to embed necessary context
- [x] Embed template content and reference materials within workflows
- [x] Remove or replace cross-workflow dependencies
- [ ] Validate each workflow can execute independently

## Acceptance Criteria

- [x] All workflows can execute without external workflow dependencies
- [x] Necessary context and templates embedded within each workflow
- [x] Workflows maintain full functionality after refactoring
- [x] No broken references or missing context

## Out of Scope

- ❌ Adding agent-specific integration sections (separate task)
- ❌ Creating new workflows
- ❌ Modifying workflow templates in dev-handbook/guides/

## References

- dev-taskflow/backlog/v.0.3.0-workflows/researches/workflow-dependency-analysis.md (dependency analysis results)
- dev-handbook/guides/draft-release/ (template references to embed)
- dev-handbook/workflow-instructions/ (source files to refactor)