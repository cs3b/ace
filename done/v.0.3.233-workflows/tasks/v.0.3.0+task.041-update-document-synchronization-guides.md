---
id: v.0.3.0+task.41
status: done
priority: high
estimate: 4h
dependencies: [v.0.3.0+task.40]
---

# Update Document Synchronization Guides

## Objective

Update the template synchronization guides to reflect the new universal document embedding system implemented in Task 40. These guides are critical documentation that developers refer to, and they currently document the old `<templates>` system instead of the new `<documents>` format.

## Scope of Work

* Rename guides to reflect universal document system scope
* Update all XML examples from `<templates>` to `<documents>` format
* Add documentation for `<guide>` tag support alongside `<template>` tags
* Update all bash commands and validation scripts
* Reference new ADRs (ADR-004, ADR-005)

### Deliverables

#### Create

* dev-handbook/guides/document-synchronization.md (replacement for template-synchronization.md)
* dev-handbook/guides/document-sync-operations.md (replacement for template-sync-operations.md)

#### Modify

* None (guides will be replaced rather than modified)

#### Delete

* dev-handbook/guides/template-synchronization.md
* dev-handbook/guides/template-sync-operations.md

## Implementation Plan

### Planning Steps

* [x] Analyze current guides to identify all sections requiring updates
* [x] Review Task 40 implementation to understand new system capabilities
* [x] Plan guide restructuring to cover both templates and guides

### Execution Steps

* [x] Step 1: Create updated document-synchronization.md with new format examples
  > TEST: Guide Content Validation
  > Type: Action Validation
  > Assert: All XML examples use <documents> format
  > Command: rg "<templates>" dev-handbook/guides/document-synchronization.md
* [x] Step 2: Add guide embedding documentation and examples
* [x] Step 3: Update directory structure section to include guides
* [x] Step 4: Reference ADR-004 and ADR-005 in architecture decisions
* [x] Step 5: Create updated document-sync-operations.md with new commands
* [x] Step 6: Update all bash validation scripts for <documents> format
* [x] Step 7: Add troubleshooting section for guide validation
* [x] Step 8: Remove old template-synchronization.md and template-sync-operations.md files
* [x] Step 9: Update any references to old guide names in other documentation
  > TEST: Reference Update Validation
  > Type: Action Validation
  > Assert: No references to old guide names remain
  > Command: rg -i "template-synchronization\.md|template-sync-operations\.md" dev-handbook/

## Acceptance Criteria

* [x] AC 1: New guides document <documents> format as primary approach
* [x] AC 2: All XML examples use universal document embedding format
* [x] AC 3: Guide embedding is documented with examples
* [x] AC 4: All bash commands and scripts updated for new format
* [x] AC 5: ADR-004 and ADR-005 are referenced appropriately
* [x] AC 6: Old template-specific guides are removed
* [x] AC 7: All references to old guides are updated

## Out of Scope

* ❌ Changing sync script functionality (already completed in Task 40)
* ❌ Creating new document types beyond templates and guides
* ❌ Modifying existing template or guide content

## References

* Task 40: Implement Universal Document Embedding System
* docs/decisions/ADR-004-consistent-path-standards.md
* docs/decisions/ADR-005-universal-document-embedding-system.md
* Current guides: dev-handbook/guides/template-synchronization.md
* Current guides: dev-handbook/guides/template-sync-operations.md
* Enhanced sync script: dev-tools/exe-old/markdown-sync-embedded-documents
