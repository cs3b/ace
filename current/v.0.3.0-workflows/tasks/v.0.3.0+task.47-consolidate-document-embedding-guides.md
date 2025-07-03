---
id: v.0.3.0+task.47
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# Consolidate Document Embedding Guides

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la dev-handbook/.meta/gds/template-embedding.g.md dev-handbook/guides/document-synchronization.md dev-handbook/guides/document-sync-operations.md
```

_Result excerpt:_

```
-rw-r--r--@ 1 michalczyz  staff  15247 Dec 30 18:42 dev-handbook/.meta/gds/template-embedding.g.md
-rw-r--r--@ 1 michalczyz  staff  25678 Dec 30 18:42 dev-handbook/guides/document-synchronization.md
-rw-r--r--@ 1 michalczyz  staff  19823 Dec 30 18:42 dev-handbook/guides/document-sync-operations.md
```

## Objective

Consolidate three overlapping document embedding guides into two comprehensive guides using current `<documents>` format standards. Create focused guides: one for embedding principles/standards and one specifically for the `bin/markdown-sync-embedded-documents` tool usage.

## Scope of Work

* Combine overlapping content from three guides into two focused guides
* Maintain current `<documents>` container format with `<template>` and `<guide>` tags
* Center second guide around the synchronization tool
* Update all cross-references to point to new guide locations
* Preserve all operational workflows and tool documentation

### Deliverables

#### Create

* dev-handbook/guides/documents-embedding.g.md
* dev-handbook/guides/documents-embedded-sync.g.md

#### Delete

* dev-handbook/.meta/gds/template-embedding.g.md
* dev-handbook/guides/document-synchronization.md
* dev-handbook/guides/document-sync-operations.md

#### Modify

* All workflow instruction files that reference the deleted guides (update path references)

## Phases

1. Audit existing content and identify overlap/gaps
2. Create new consolidated guides with proper content organization
3. Update all cross-references and path dependencies
4. Remove obsolete guide files

## Implementation Plan

### Planning Steps

* [ ] Analyze content overlap between the three source guides
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Content organization plan is clear and no content will be lost
  > Command: grep -r "template-embedding\|document-synchronization\|document-sync-operations" dev-handbook/workflow-instructions/
* [ ] Identify all cross-references to guides being deleted
* [ ] Plan content distribution between embedding principles and tool usage

### Execution Steps

* [ ] Create documents-embedding.g.md combining XML standards and principles
  > TEST: Verify Embedding Guide Content
  > Type: Content Validation
  > Assert: All XML format standards and embedding principles are preserved
  > Command: grep -E "<documents>|<template>|<guide>" dev-handbook/guides/documents-embedding.g.md
* [ ] Create documents-embedded-sync.g.md focused on bin/markdown-sync-embedded-documents tool
  > TEST: Verify Tool Documentation
  > Type: Tool Reference Validation
  > Assert: All tool commands and operational workflows are documented
  > Command: grep "bin/markdown-sync-embedded-documents" dev-handbook/guides/documents-embedded-sync.g.md
* [ ] Update all workflow instruction files with new guide path references
  > TEST: Verify Reference Updates
  > Type: Reference Integrity Check
  > Assert: No broken references to deleted guides remain
  > Command: grep -r "template-embedding\|document-synchronization\|document-sync-operations" dev-handbook/workflow-instructions/
* [ ] Remove the three obsolete guide files
* [ ] Validate all cross-references and ensure no content loss
  > TEST: Verify No Content Loss
  > Type: Content Completeness Check
  > Assert: All essential content from source guides is preserved in new guides
  > Command: wc -l dev-handbook/guides/documents-*.g.md

## Acceptance Criteria

* [ ] AC 1: Two new consolidated guides created with comprehensive content
* [ ] AC 2: documents-embedding.g.md covers XML standards and embedding principles
* [ ] AC 3: documents-embedded-sync.g.md focuses on bin/markdown-sync-embedded-documents tool
* [ ] AC 4: All cross-references updated to point to new guide locations
* [ ] AC 5: Three obsolete guide files removed
* [ ] AC 6: No content lost during consolidation process

## Out of Scope

* ❌ Changing the `<documents>` container format itself
* ❌ Modifying the bin/markdown-sync-embedded-documents tool functionality
* ❌ Adding new embedding features or capabilities

## References

* Source files: template-embedding.g.md, document-synchronization.md, document-sync-operations.md
* Current format: `<documents>` container with `<template>` and `<guide>` tags
* Tool reference: bin/markdown-sync-embedded-documents