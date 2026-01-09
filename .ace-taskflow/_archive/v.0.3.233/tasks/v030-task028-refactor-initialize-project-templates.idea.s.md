---
id: v.0.3.0+task.28
status: done
priority: high
estimate: 8h
dependencies: []
---

# Refactor Initialize Project Templates

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/exe-old/_binstubs | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/tools/exe-old/_binstubs
    ├── build
    ├── lint
    ├── run
    └── test
```

## Objective

The initialize-project-structure.wf.md workflow uses outdated four-tick markdown blocks for embedding templates, which violates the template-embedding.g.md guide. This critical workflow must be refactored to use the standard XML `<templates>` format and clarify that binstubs should be sourced from `.ace/tools/exe-old/_binstubs`.

## Scope of Work

* Convert all four-tick markdown template embeddings to XML format
* Update binstub references to point to .ace/tools/exe-old/_binstubs
* Ensure single source of truth for all templates
* Maintain workflow functionality while improving compliance

### Deliverables

#### Create

* None - this is a refactoring task

#### Modify

* .ace/handbook/workflow-instructions/initialize-project-structure.wf.md

#### Delete

* None

## Phases

1. Analyze current template usage
2. Convert to XML template format
3. Update binstub references
4. Validate converted workflow

## Implementation Plan

### Planning Steps

* [x] Review current initialize-project-structure.wf.md content
  > TEST: Current State Analyzed
  > Type: Pre-condition Check
  > Assert: All embedded templates identified and catalogued
  > Command: bin/test --check-template-analysis
* [x] Count and list all four-tick markdown blocks to convert
* [x] Verify binstub templates exist in .ace/tools/exe-old/_binstubs

### Execution Steps

* [x] Convert each four-tick markdown block to XML `<templates>` format
  > TEST: Template Format Conversion
  > Type: Syntax Validation
  > Assert: No four-tick markdown blocks remain, all use XML format
  > Command: bin/test --check-xml-template-format
* [x] Update binstub creation instructions to reference .ace/tools/exe-old/_binstubs
* [x] Ensure each template has proper path attribute in XML
* [x] Remove any ambiguity about template source locations
  > TEST: Single Source of Truth
  > Type: Content Validation
  > Assert: Each template has one clear source location
  > Command: bin/test --check-template-sources
* [x] Verify workflow remains functionally correct after refactoring

## Acceptance Criteria

* [x] All templates use XML `<templates><template path="..."></template></templates>` format
* [x] No four-tick markdown blocks remain in the file
* [x] Binstub references clearly point to .ace/tools/exe-old/_binstubs
* [x] Single source of truth established for each template
* [x] Workflow remains executable by AI agents

## Out of Scope

* ❌ Changing workflow logic or process steps
* ❌ Creating new templates
* ❌ Modifying the actual template content
* ❌ Updating other workflow files

## References

* template-embedding.g.md (XML format specification)
* Workflow review reports identifying the violation
* .ace/tools/exe-old/_binstubs directory for binstub templates
