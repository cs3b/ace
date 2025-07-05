---
id: v.0.3.0+task.65
status: done
priority: high
estimate: 6h
dependencies: []
---

# Create Version Control Message Guide

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

Create a dedicated guide for version control message standards, specifically documenting the Conventional Commits specification that is required by the commit.wf.md workflow. This guide will extract message formatting content from the commit workflow and establish it as a standalone reference that can be linked from multiple workflows.

## Scope of Work

* Extract Conventional Commits specification from commit workflow
* Create comprehensive guide covering message types, scopes, and formatting rules
* Document examples for different commit types (feat, fix, refactor, etc.)
* Provide guidance for writing clear, actionable commit messages

### Deliverables

#### Create

* dev-handbook/guides/development/version-control-message.g.md

#### Modify

* dev-handbook/guides/development/README.md (add reference to new guide)

#### Delete

* None

## Phases

1. Analyze existing commit message conventions in current guides
2. Extract Conventional Commits specification from commit workflow
3. Create comprehensive standalone guide
4. Validate guide covers all required message formats

## Implementation Plan

### Planning Steps

* [ ] Analyze current commit message documentation in existing guides
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current message conventions identified and documented
  > Command: bin/test --check-commit-conventions-analyzed
* [x] Review commit.wf.md workflow for Conventional Commits requirements
* [x] Plan guide structure covering types, scopes, format rules, and examples

### Execution Steps

* [x] Create version control message guide with Conventional Commits specification
  > TEST: Verify Guide Creation
  > Type: Action Validation
  > Assert: Guide file created with complete Conventional Commits specification
  > Command: bin/test --check-guide-completeness dev-handbook/guides/development/version-control-message.g.md
* [x] Include comprehensive examples for all commit types (feat, fix, refactor, docs, etc.)
* [x] Update development guides README to reference new guide
  > TEST: Verify README Reference
  > Type: Action Validation
  > Assert: README includes proper reference to new message guide
  > Command: bin/test --check-readme-reference version-control-message.g.md

## Acceptance Criteria

* [x] AC 1: Guide provides complete Conventional Commits specification with types, scopes, and format rules
* [x] AC 2: Examples included for all major commit types (feat, fix, refactor, docs, style, test, chore)
* [x] AC 3: Guide explains when to use each commit type with clear criteria
* [x] AC 4: Guide is referenced from development README and linkable from workflows

## Out of Scope

* ❌ Git-specific workflow implementation details (covered in separate git guide)
* ❌ Tool-specific commit message generation (covered in tool documentation)
* ❌ Project-specific commit message customizations

## References

* Review finding: "The commit workflow requires this format but does not link to a definitive guide explaining the types, scopes, and formatting rules"
* Source: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/gpro-review.md
* Related workflow: commit.wf.md
* User note: "the guide should go to dev-handbook/guides/version-control-system.g.md - we should split this guide to two parts: a) version-control-system-message.g.md b) version-control-system-git.g.md"

