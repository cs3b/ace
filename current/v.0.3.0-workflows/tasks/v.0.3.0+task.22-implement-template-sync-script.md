---
id: v.0.3.0+task.22
status: done
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

Create the `markdown-sync-embedded-documents` script that automatically synchronizes XML-embedded template content in workflow instructions with their corresponding template files. This script will scan for XML `<templates>` sections, parse embedded templates using the simplified single `path` attribute format, compare content with template files, update differences, and commit changes automatically.

Link back to original requirement: Automated template synchronization script (improve-the-workflow-structure.md)

## Scope of Work

* Update template embedding guide to use simplified single `path` attribute format
* Update all workflow instructions to remove `template-path` and use only `path`
* Develop script to scan workflow instructions for XML `<templates>` sections
* Implement XML parsing to extract template content using single `path` attribute
* Create content comparison between embedded templates and template files
* Implement automatic update mechanism for out-of-sync content
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

* [x] Update template embedding guide to use single `path` attribute
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Guide uses only `path` attribute pointing to template file
  > Command: grep -A 5 -B 5 'template-path' dev-handbook/guides/.meta/template-embedding.g.md

* [x] Update all workflow instructions to use single `path` attribute
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: All workflow files use simplified XML format with single `path` attribute
  > Command: grep -r 'template-path' dev-handbook/workflow-instructions/*.wf.md

* [x] Analyze simplified XML template embedding format
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Simplified XML template embedding format is clearly defined and implemented
  > Command: grep -r "<templates>" dev-handbook/workflow-instructions/*.wf.md

* [x] Design script architecture and command-line interface
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Script design covers all requirements and edge cases
  > Command: Review script design specification

### Execution Steps

* [x] Create main script in dev-tools/exe-old/markdown-sync-embedded-documents
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script correctly identifies all XML template sections
  > Command: dev-tools/exe-old/markdown-sync-embedded-documents --dry-run --verbose

* [x] Create binstub in dev-tools/exe-old/_binstubs/markdown-sync-embedded-documents
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Binstub follows project patterns and makes script accessible
  > Command: dev-tools/exe-old/_binstubs/markdown-sync-embedded-documents --help

* [x] Create thin wrapper in bin/markdown-sync-embedded-documents
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Wrapper correctly delegates to exe-old script
  > Command: bin/markdown-sync-embedded-documents --dry-run --verbose

* [x] Implement XML parsing for simplified format and content comparison logic
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script accurately parses simplified XML format and detects content differences
  > Command: Test with known different XML template content scenarios using single path attribute

* [x] Add XML-aware update mechanism to replace embedded content with template content
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script correctly updates XML-embedded content while preserving single path attribute
  > Command: Verify updated content matches template files and simplified XML structure is maintained

* [x] Implement automatic commit functionality with standardized message
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script commits changes with proper message format
  > Command: git log --oneline | grep "chore: sync embede templates"

* [x] Add summary reporting of changes made
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script provides clear summary of synchronization actions
  > Command: Review script output for completeness

* [x] Create comprehensive XML validation and error handling
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Script validates simplified XML structure and handles edge cases with helpful error messages
  > Command: Test script with malformed XML, missing path attribute, and various error scenarios

## Acceptance Criteria

* [x] Main script created in dev-tools/exe-old/markdown-sync-embedded-documents
* [x] Binstub created in dev-tools/exe-old/_binstubs/markdown-sync-embedded-documents
* [x] Thin wrapper created in bin/markdown-sync-embedded-documents
* [x] Script successfully scans all workflow instruction files
* [x] Correctly identifies XML template sections using simplified `<templates>` format with single `path` attribute
* [x] Accurately parses single `path` attribute and compares embedded content with template file content
* [x] Updates out-of-sync XML-embedded templates with template file content
* [x] Commits changes with standardized commit message format
* [x] Provides comprehensive summary of changes made
* [x] Handles error cases gracefully with helpful messages
* [x] Can be run safely multiple times (idempotent)
* [x] Follows project's dev-tools/exe-old organizational pattern
* [x] Template embedding guide updated to use single `path` attribute format
* [x] All workflow instructions updated to remove `template-path` and use only `path`
* [x] Validates simplified XML template structure using updated regex patterns
* [x] Supports single `path` attribute validation pointing to template files
* [x] Handles variable substitution in paths (e.g., `{current-release-path}`)
* [x] Preserves XML formatting and indentation during updates

## Out of Scope

* ❌ Modifying template files (only updates embedded content)
* ❌ Creating missing template files (handled in previous task)
* ❌ Reverting to old four-tick format templates (XML format is standard)
❌ Adding back dual-attribute system (simplified to single `path` attribute)

## References

* Original requirement: improve-the-workflow-structure.md
* Dependencies: v.0.3.0+task.21 (standardized template embedding format)
* Related tools: bin/gc script for commit functionality pattern
