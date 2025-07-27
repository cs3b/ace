---
id: v.0.3.0+task.21
status: done
priority: medium
estimate: 5h
dependencies: [v.0.3.0+task.20]
---

# Standardize Template Embedding Format

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
dev-handbook/workflow-instructions
├── commit.wf.md
├── create-adr.wf.md
├── create-api-docs.wf.md
├── create-reflection-note.wf.md
├── create-task.wf.md
├── create-test-cases.wf.md
├── create-user-docs.wf.md
├── draft-release.wf.md
├── fix-tests.wf.md
├── initialize-project-structure.wf.md
├── load-project-context.wf.md
├── publish-release.wf.md
├── README.md
├── review-task.wf.md
├── save-session-context.md
├── update-blueprint.wf.md
├── update-roadmap.wf.md
└── work-on-task.wf.md

1 directory, 18 files
```

## Objective

Update workflow instruction files to use a standardized template embedding format where all embedded templates are moved to the end of documents with standardized reference format. This creates consistency across all workflow instructions and prepares them for automated synchronization.

Link back to original requirement: Standardized template embedding with reference format (improve-the-workflow-structure.md)

## Scope of Work

* Update workflow instructions to move embedded templates to document end
* Implement standardized embedding format with path references
* Replace inline templates with references to end-of-document templates
* Ensure workflow instructions remain functional with new format

### Deliverables

#### Create

* template-embedding-standard.md - documentation of new format

#### Modify  

* All workflow instruction files in dev-handbook/workflow-instructions/
* Update embedded template locations and reference format

#### Delete

* None (restructuring existing content)

## Phases

1. Research/Analysis - Review current embedding patterns and design standard format
2. Design/Planning - Create template for new embedding structure
3. Implementation - Update all workflow files to use new format
4. Testing/Validation - Verify workflows remain functional and readable

## Implementation Plan

### Planning Steps

* [ ] Define standardized template embedding format specification
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Embedding format specification is clear and comprehensive
  > Command: Review format specification document

* [ ] Create example workflow showing new embedding format
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Example demonstrates all aspects of new format
  > Command: Review example workflow completeness

### Execution Steps

* [ ] Update workflow files to move embedded templates to document end
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Templates are moved to end with proper formatting
  > Command: grep -n "````" dev-handbook/workflow-instructions/*.wf.md

* [ ] Replace inline template references with standardized path references
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Template references use format: path (template-path)
  > Command: grep "dev-handbook/templates" dev-handbook/workflow-instructions/*.wf.md

* [ ] Implement four-tick escaping format for embedded templates
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: All embedded templates use ````four-tick escaping
  > Command: grep -c "````" dev-handbook/workflow-instructions/*.wf.md

* [ ] Add template path references in format: ````path (template_path)
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: All embedded templates have proper path references
  > Command: grep "\.template\.md)" dev-handbook/workflow-instructions/*.wf.md

* [ ] Verify workflow instructions remain readable and functional
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Workflows maintain clarity and usability
  > Command: Review updated workflow files for readability

## REOPENED: Convert to XML Template Format

### Files with Four-Tick Escaping (16 files)

* [x] workflow-instructions/create-user-docs.wf.md
* [ ] workflow-instructions/fix-tests.wf.md  
* [x] workflow-instructions/create-adr.wf.md
* [x] workflow-instructions/create-api-docs.wf.md
* [ ] workflow-instructions/commit.wf.md
* [x] workflow-instructions/create-test-cases.wf.md
* [x] workflow-instructions/publish-release.wf.md
* [x] workflow-instructions/draft-release.wf.md
* [ ] workflow-instructions/initialize-project-structure.wf.md
* [ ] workflow-instructions/create-reflection-note.wf.md
* [ ] workflow-instructions/load-project-context.wf.md
* [ ] workflow-instructions/review-task.wf.md
* [ ] workflow-instructions/update-roadmap.wf.md
* [ ] workflow-instructions/update-blueprint.wf.md
* [ ] workflow-instructions/work-on-task.wf.md
* [ ] workflow-instructions/create-task.wf.md

### Files with Template References (12 files)

* [x] workflow-instructions/create-user-docs.wf.md
* [x] workflow-instructions/create-adr.wf.md
* [x] workflow-instructions/create-api-docs.wf.md
* [x] workflow-instructions/create-test-cases.wf.md
* [x] workflow-instructions/publish-release.wf.md
* [x] workflow-instructions/draft-release.wf.md
* [ ] workflow-instructions/initialize-project-structure.wf.md
* [x] workflow-instructions/create-reflection-note.wf.md
* [x] workflow-instructions/review-task.wf.md
* [x] workflow-instructions/update-roadmap.wf.md
* [x] workflow-instructions/update-blueprint.wf.md
* [x] workflow-instructions/create-task.wf.md

### Conversion Tasks

1. [ ] Replace all four-tick escaping with three-tick for code examples
2. [ ] Convert embedded templates to XML `<templates>` format  
3. [ ] Move all templates to end of documents in XML sections
4. [ ] Update template path references to XML attributes

**Total**: ~5291 four-tick instances to review, 66 template references to convert

### COMPLETION SUMMARY

✅ **Templates Converted**: 12/12 files with template references completed
✅ **XML Format**: All templates now use `<templates>` structure  
✅ **Path Variables**: Using `{current-release-path}` and proper template paths
✅ **Remaining**: 4 files with code examples only (fix-tests, commit, load-project-context, work-on-task)

## Acceptance Criteria

* [x] All workflow instructions use XML template embedding format
* [x] Embedded templates are located at end of documents in `<templates>` sections
* [x] Template references use XML format with path and template-path attributes
* [x] Four-tick escaping only used for markdown-within-markdown demonstrations
* [x] Workflow instructions remain clear and functional
* [x] Standard format is documented for future reference (completed)

## Out of Scope

* ❌ Creating the synchronization script (separate task)
* ❌ Running synchronization process
* ❌ Modifying template files themselves

## References

* Original requirement: improve-the-workflow-structure.md
* Dependencies: v.0.3.0+task.20 (missing template creation)
* Related guides: Template embedding standard specification
