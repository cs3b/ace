---
id: v.0.3.0+task.49
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Create Workflow README Integration Guide

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
    ├── create-task.wf.md
    ├── create-user-docs.wf.md
    ├── initialize-project-structure.wf.md
    ├── log-session-compact.wf.md
    ├── release-complete.wf.md
    ├── release-prepare.wf.md
    ├── research-investigate.wf.md
    ├── review-code.wf.md
    ├── review-task.wf.md
    ├── select-next-task.wf.md
    ├── synchronize-embedded-documents.wf.md
    ├── update-claude-instructions.wf.md
    ├── update-docs.wf.md
    ├── update-roadmap.wf.md
    └── work-on-task.wf.md
```

## Objective

Create a comprehensive integration guide in dev-handbook/workflow-instructions/README.md that documents end-to-end workflow orchestration from project initialization to release for AI agents. This addresses the critical consensus issue identified by both reviewers about missing core development lifecycle documentation.

## Scope of Work

* Research existing workflows to understand integration points and dependencies
* Design workflow orchestration sequences for common development scenarios
* Create decision trees for AI agents to navigate workflow selection
* Document workflow entry/exit conditions and hand-off patterns
* Include error recovery and rollback procedures

### Deliverables

#### Create

* dev-handbook/workflow-instructions/README.md - Comprehensive workflow integration guide

#### Modify

* None

#### Delete

* None

## Phases

1. Research - Analyze all 18 workflows to map dependencies and integration points
2. Design - Create workflow orchestration patterns and decision trees
3. Document - Write comprehensive integration guide with examples

## Implementation Plan

### Planning Steps

* [ ] Analyze all workflow files to understand inputs, outputs, and dependencies
  > TEST: Workflow Analysis Complete
  > Type: Pre-condition Check
  > Assert: All 18 workflows analyzed with dependencies mapped
  > Command: bin/test --check-workflow-analysis
* [ ] Research common development scenarios (new feature, bug fix, release cycle)
* [ ] Design workflow sequence diagrams for each scenario
* [ ] Plan decision tree structure for AI agent navigation

### Execution Steps

* [ ] Create README.md structure with sections for overview, scenarios, and decision trees
* [ ] Document project initialization to first commit workflow sequence
* [ ] Document feature development workflow sequence (task selection → implementation → review → commit)
  > TEST: Feature Workflow Documentation
  > Type: Content Validation
  > Assert: Complete feature development sequence documented with decision points
  > Command: bin/test --check-feature-workflow-docs
* [ ] Document bug fix workflow sequence with expedited paths
* [ ] Document release preparation and completion workflow sequence
* [ ] Add workflow selection decision tree for AI agents
* [ ] Include error recovery procedures and rollback strategies
* [ ] Add examples of workflow transitions and hand-offs
  > TEST: Integration Guide Complete
  > Type: Documentation Validation
  > Assert: All workflow scenarios documented with examples
  > Command: bin/lint dev-handbook/workflow-instructions/README.md

## Acceptance Criteria

* [ ] AC 1: README.md provides clear end-to-end workflow orchestration guidance
* [ ] AC 2: All 18 workflows are integrated into coherent development scenarios
* [ ] AC 3: AI agents can navigate workflow selection using decision trees
* [ ] AC 4: Error recovery and rollback procedures are documented
* [ ] AC 5: Examples demonstrate practical workflow transitions

## Out of Scope

* ❌ Modifying existing workflow files
* ❌ Creating new workflows
* ❌ Implementing automation tools

## References

* Review synthesis report: dev-taskflow/current/v.0.3.0-workflows/code_review/20250703-232338-handbook-workflows/cr-report.md
* Existing workflows: dev-handbook/workflow-instructions/*.wf.md
* Architecture docs: docs/architecture.md