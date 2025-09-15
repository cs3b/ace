---
id: v.0.3.0+task.66
status: done
priority: high
estimate: 5h
dependencies: [v.0.3.0+task.65]
---

# Create Version Control Git Guide

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

Create a dedicated guide for Git-specific version control operations and workflows, complementing the version control message guide. This guide will focus on Git command patterns, branching strategies, and workflow procedures while referencing the separate message guide for commit formatting.

## Scope of Work

* Create comprehensive Git workflow guide covering branching, merging, and collaboration patterns
* Document best practices for Git operations in development workflows
* Reference the version control message guide for commit formatting
* Include troubleshooting section for common Git issues

### Deliverables

#### Create

* dev-handbook/guides/development/version-control-git.g.md

#### Modify

* dev-handbook/guides/development/README.md (add reference to new guide)

#### Delete

* None

## Phases

1. Analyze existing Git workflow documentation
2. Extract Git-specific procedures from existing guides
3. Create comprehensive Git operations guide
4. Validate guide complements message guide without overlap

## Implementation Plan

### Planning Steps

* [ ] Analyze current Git workflow documentation in existing guides
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current Git procedures identified and documented
  > Command: bin/test --check-git-workflows-analyzed
* [x] Review commit.wf.md and other workflows for Git operation patterns
* [x] Plan guide structure covering branching, merging, collaboration, and troubleshooting

### Execution Steps

* [x] Create version control Git guide with comprehensive workflow procedures
  > TEST: Verify Guide Creation
  > Type: Action Validation
  > Assert: Guide file created with complete Git workflow procedures
  > Command: bin/test --check-guide-completeness dev-handbook/guides/development/version-control-git.g.md
* [x] Include cross-reference to version control message guide for commit formatting
* [x] Add troubleshooting section for common Git workflow issues
  > TEST: Verify Cross-Reference
  > Type: Action Validation
  > Assert: Guide properly references version control message guide
  > Command: bin/test --check-cross-reference version-control-git.g.md version-control-message.g.md
* [x] Update development guides README to reference new guide

## Acceptance Criteria

* [x] AC 1: Guide provides comprehensive Git workflow procedures (branching, merging, collaboration)
* [x] AC 2: Guide includes troubleshooting section for common Git issues
* [x] AC 3: Guide properly cross-references version control message guide for commit formatting
* [x] AC 4: Guide is referenced from development README for discoverability

## Out of Scope

* ❌ Commit message formatting details (covered in version control message guide)
* ❌ Project-specific Git configurations
* ❌ Advanced Git internals or low-level operations

## References

* Review finding: "we should split this guide to two parts: a) version-control-system-message.g.md b) version-control-system-git.g.md"
* Source: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/gpro-review.md
* Related workflow: commit.wf.md
* Dependency: version-control-message.g.md guide must be completed first
