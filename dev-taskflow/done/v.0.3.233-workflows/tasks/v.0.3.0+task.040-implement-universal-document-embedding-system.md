---
id: v.0.3.0+task.40
status: done
priority: high
estimate: 10h
dependencies: []
---

# Implement Universal Document Embedding System

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
.ace/handbook/guides/
├── README.md
├── api-development.g.md
├── documentation.g.md
├── embedded-testing-guide.g.md
├── error-handling.g.md
├── performance.g.md
├── quality-assurance.g.md
├── ruby/
├── security.g.md
├── template-synchronization.md
├── template-sync-operations.md
├── testing.g.md
├── testing-tdd-cycle.g.md
└── typescript/
```

## Objective

Transform the current template-only embedding system into a universal `<documents>` system that supports both guides and templates, eliminates duplication, and establishes consistent path standards across all workflow instructions.

## Scope of Work

* Replace `<templates>` with universal `<documents>` format
* Add support for both `<guide>` and `<template>` tags
* Eliminate template duplication (task.template.md used 3×, blueprint.template.md used 2×)
* Establish consistent path standards (always relative to project root)
* Extend sync script to handle universal document embedding

### Deliverables

#### Create

* docs/decisions/adr-XXX-universal-document-embedding-system.md
* docs/decisions/adr-XXX-consistent-path-standards.md

#### Modify

* handbook sync-templates (extend to support <documents> format)
* .ace/handbook/workflow-instructions/create-task.wf.md (update to new format)
* .ace/handbook/workflow-instructions/update-blueprint.wf.md (update to new format)
* .ace/handbook/workflow-instructions/update-roadmap.wf.md (update to new format)
* .ace/handbook/workflow-instructions/review-task.wf.md (update to new format)
* .ace/handbook/workflow-instructions/create-reflection-note.wf.md (update to new format)
* .ace/handbook/workflow-instructions/initialize-project-structure.wf.md (update to new format)
* .ace/handbook/workflow-instructions/draft-release.wf.md (update to new format)
* .ace/handbook/workflow-instructions/publish-release.wf.md (update to new format)
* .ace/handbook/workflow-instructions/create-test-cases.wf.md (update to new format)
* .ace/handbook/workflow-instructions/commit.wf.md (update to new format)
* .ace/handbook/workflow-instructions/create-api-docs.wf.md (update to new format)
* .ace/handbook/workflow-instructions/create-adr.wf.md (update to new format)
* .ace/handbook/workflow-instructions/save-session-context.wf.md (update to new format)
* .ace/handbook/workflow-instructions/create-user-docs.wf.md (update to new format)

#### Delete

* None

## Phases

1. Analysis and Standards
2. Enhance Sync System
3. Eliminate Duplication
4. Migration and Testing

## Implementation Plan

### Planning Steps

* [x] Analyze current template embedding patterns across all 14 workflow files
  > TEST: Template Analysis Complete
  > Type: Pre-condition Check
  > Assert: All template paths and duplications are documented
  > Command: rg "template path=" .ace/handbook/workflow-instructions/ | cut -d'"' -f2 | sort | uniq -c | sort -nr
* [x] Research universal document embedding architecture patterns
* [x] Design backward compatibility strategy for gradual migration

### Execution Steps

* [x] Step 1: Create ADR for consistent path standards (always relative to project root)
* [x] Step 2: Create ADR for universal document embedding system architecture
  > TEST: ADR Creation Validation
  > Type: Action Validation
  > Assert: Both ADRs are properly structured and address key decisions
  > Command: bin/lint docs/decisions/
* [x] Step 3: Extend sync script to support `<documents>` format with `<guide>` and `<template>` tags
* [x] Step 4: Maintain backward compatibility with existing `<templates>` format during transition
  > TEST: Sync Script Enhancement
  > Type: Action Validation
  > Assert: Script handles both old and new formats correctly
  > Command: handbook sync-templates --dry-run --verbose
* [x] Step 5: Update create-task.wf.md to use new `<documents>` format (eliminate 3× task.template.md duplication)
* [x] Step 6: Update update-blueprint.wf.md to use new format (eliminate 2× blueprint.template.md duplication)
* [x] Step 7: Update remaining 12 workflow files to use new `<documents>` format
* [x] Step 8: Test sync functionality with all updated workflow files
  > TEST: Migration Validation
  > Type: Action Validation
  > Assert: All workflow files use consistent document embedding format
  > Command: rg -c "<documents>" .ace/handbook/workflow-instructions/*.wf.md
* [x] Step 9: Validate all template paths are consistent (relative to project root)
* [x] Step 10: Run full sync to ensure all embedded content is up-to-date

## Acceptance Criteria

* [x] AC 1: All 14 workflow files use universal `<documents>` format instead of `<templates>`
* [x] AC 2: Universal document embedding system implemented (template references now use consistent <documents> format)
* [x] AC 3: All document paths are consistently relative to project root
* [x] AC 4: Sync script supports both `<guide>` and `<template>` tags within `<documents>`
* [x] AC 5: Backward compatibility maintained during transition period
* [x] AC 6: All embedded content synchronizes correctly with source files

## Out of Scope

* ❌ Creating new guides or templates (focus on embedding system only)
* ❌ Modifying template content (only paths and embedding format)
* ❌ Adding new document types beyond guides and templates
* ❌ Changing workflow instruction logic (only embedding format)

## References

* Current template embedding analysis showing 3× task.template.md, 2× blueprint.template.md duplication
* Existing sync script: handbook sync-templates
* 14 workflow files using template embedding: .ace/handbook/workflow-instructions/*.wf.md
* Template directory structure: .ace/handbook/templates/
* Guide directory structure: .ace/handbook/guides/
