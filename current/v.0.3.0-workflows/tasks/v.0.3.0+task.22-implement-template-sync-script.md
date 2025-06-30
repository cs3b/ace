---
id: v.0.3.0+task.22
status: pending
priority: medium
estimate: 8h
dependencies: [v.0.3.0+task.21]
---

# Implement Template Sync Script

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools | sed 's/^/    /'
```

_Result excerpt:_

```
[To be populated during execution]
```

## Objective

Create the `markdown-sync-embedded-documents` script that automatically synchronizes embedded template content in workflow instructions with their corresponding template files. This script will scan for embedded templates, compare content with template files, update differences, and commit changes automatically.

Link back to original requirement: Automated template synchronization script (improve-the-workflow-structure.md)

## Scope of Work

* Develop script to scan workflow instructions for embedded templates
* Implement content comparison between embedded templates and template files
* Create automatic update mechanism for out-of-sync content
* Add commit functionality with standardized commit message
* Include summary reporting of changes made

### Deliverables

#### Create

* dev-tools/exe-old/markdown-sync-embedded-documents - main script implementation
* dev-tools/exe-old/_binstubs/markdown-sync-embedded-documents - binstub for the script
* bin/markdown-sync-embedded-documents - thin wrapper pointing to exe-old script

#### Modify  

* None initially (new script creation)

#### Delete

* None

## Phases

1. Research/Analysis - Study template embedding format and determine sync algorithm
2. Design/Planning - Design script architecture and command-line interface
3. Implementation - Develop script with scanning, comparison, and update logic
4. Testing/Validation - Test script with various scenarios and edge cases

## Implementation Plan

### Planning Steps

* [ ] Analyze standardized template embedding format from previous task
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Template embedding format is clearly defined and implemented
  > Command: grep "````._\.template\.md)" dev-handbook/workflow-instructions/_.wf.md

* [ ] Design script architecture and command-line interface
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Script design covers all requirements and edge cases
  > Command: Review script design specification

### Execution Steps

* [ ] Create main script in dev-tools/exe-old/markdown-sync-embedded-documents
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script correctly identifies all embedded templates
  > Command: dev-tools/exe-old/markdown-sync-embedded-documents --dry-run --verbose

* [ ] Create binstub in dev-tools/exe-old/_binstubs/markdown-sync-embedded-documents
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Binstub follows project patterns and makes script accessible
  > Command: dev-tools/exe-old/_binstubs/markdown-sync-embedded-documents --help

* [ ] Create thin wrapper in bin/markdown-sync-embedded-documents
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Wrapper correctly delegates to exe-old script
  > Command: bin/markdown-sync-embedded-documents --dry-run --verbose

* [ ] Implement content comparison logic between embedded and template files
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script accurately detects content differences
  > Command: Test with known different content scenarios

* [ ] Add update mechanism to replace embedded content with template content
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script correctly updates embedded content
  > Command: Verify updated content matches template files

* [ ] Implement automatic commit functionality with standardized message
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script commits changes with proper message format
  > Command: git log --oneline | grep "chore: sync embede templates"

* [ ] Add summary reporting of changes made
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script provides clear summary of synchronization actions
  > Command: Review script output for completeness

* [ ] Create comprehensive error handling and validation
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script handles edge cases and provides helpful error messages
  > Command: Test script with various error scenarios

## Acceptance Criteria

* [ ] Main script created in dev-tools/exe-old/markdown-sync-embedded-documents
* [ ] Binstub created in dev-tools/exe-old/_binstubs/markdown-sync-embedded-documents
* [ ] Thin wrapper created in bin/markdown-sync-embedded-documents
* [ ] Script successfully scans all workflow instruction files
* [ ] Correctly identifies embedded templates using ````path (template_path) format
* [ ] Accurately compares embedded content with template file content
* [ ] Updates out-of-sync embedded templates with template file content
* [ ] Commits changes with standardized commit message format
* [ ] Provides comprehensive summary of changes made
* [ ] Handles error cases gracefully with helpful messages
* [ ] Can be run safely multiple times (idempotent)
* [ ] Follows project's dev-tools/exe-old organizational pattern

## Out of Scope

* ❌ Modifying template files (only updates embedded content)
* ❌ Creating missing template files (handled in previous task)
* ❌ Changing template embedding format (defined in previous task)

## References

* Original requirement: improve-the-workflow-structure.md
* Dependencies: v.0.3.0+task.21 (standardized template embedding format)
* Related tools: bin/gc script for commit functionality pattern
