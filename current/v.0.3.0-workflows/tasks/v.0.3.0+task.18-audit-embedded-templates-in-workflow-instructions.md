---
id: v.0.3.0+task.18
status: pending
priority: high
estimate: 3h
dependencies: []
---

# Audit Embedded Templates in Workflow Instructions

## 0. Directory Audit ✅

_Command run:_
```bash
tree -L 2 dev-handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
[To be populated during execution]
```

## Objective

Create a comprehensive inventory of all embedded templates and documents within workflow instruction files. This audit will serve as the foundation for unified template management by identifying what templates are currently embedded directly in workflow files versus maintained separately in the template directory structure.

Link back to original requirement: Unified template embedding workflow structure improvement (improve-the-workflow-structure.md)

## Scope of Work

* All workflow instruction files in dev-handbook/workflow-instructions/
* Embedded templates and document fragments within workflow files
* Comparison framework for template matching
* Template location and format analysis

### Deliverables

#### Create

* embedded-templates-audit.md - comprehensive inventory report

#### Modify  

* None (this is a research/audit task)

#### Delete

* None

## Phases

1. Research/Analysis - Scan all workflow files for embedded templates
2. Design/Planning - Create categorization framework for findings
3. Implementation - Document all findings in structured format
4. Testing/Validation - Verify completeness and accuracy of audit

## Implementation Plan

### Planning Steps

* [ ] Review all workflow instruction files to understand current embedding patterns
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: All workflow files are accessible and readable
  > Command: find dev-handbook/workflow-instructions -name "*.wf.md" | wc -l

### Execution Steps

* [ ] Scan each workflow file for embedded template patterns (code blocks, template sections)
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: All embedded templates are identified and cataloged
  > Command: grep -r "```" dev-handbook/workflow-instructions/ | grep -v "bash"

* [ ] Identify template types (task templates, document templates, configuration templates)
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Templates are properly categorized by type and purpose
  > Command: Review categorization completeness

* [ ] Document file paths, line numbers, and template content for each embedded template
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Complete reference information captured for each template
  > Command: Verify audit document contains all required fields

* [ ] Create structured inventory report with findings
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Audit report is complete and properly formatted
  > Command: Review audit report against workflow files

## Acceptance Criteria

* [ ] All workflow instruction files have been thoroughly examined
* [ ] Complete inventory of embedded templates with file locations
* [ ] Templates categorized by type and purpose
* [ ] Structured audit report created in markdown format
* [ ] Foundation established for template comparison and synchronization

## Out of Scope

* ❌ Making changes to existing workflow files
* ❌ Creating or modifying template files
* ❌ Implementing synchronization mechanisms

## References

* Original requirement: improve-the-workflow-structure.md
* Related guides: dev-handbook/workflow-instructions/
* Dependencies: None (foundational task)