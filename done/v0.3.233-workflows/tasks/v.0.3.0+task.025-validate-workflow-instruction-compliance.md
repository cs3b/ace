---
id: v.0.3.0+task.25
status: done
priority: medium
estimate: 4h
dependencies: [v.0.3.0+task.21]
---

# Validate Workflow Instruction Compliance

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

Review all workflow instruction files to ensure they follow the standardized template embedding format and proper structural guidelines. This validation ensures consistency across all workflows and confirms they're ready for automated template synchronization.

Link back to original requirement: Ensure workflow instructions follow proper template call patterns and structure (improve-the-workflow-structure.md)

## Scope of Work

* Validate all workflow instructions use standardized template embedding format
* Check for proper template reference patterns (XML <templates> sections)
* Verify workflow structure follows established guidelines
* Identify and document any compliance issues
* Ensure embedded templates are properly positioned at document end

### Deliverables

#### Create

* workflow-compliance-report.md - detailed validation results
* workflow-compliance-fixes.md - action plan for any non-compliant workflows

#### Modify  

* Any non-compliant workflow instruction files (to fix identified issues)

#### Delete

* None

## Phases

1. Research/Analysis - Review standardized format requirements and existing workflows
2. Design/Planning - Create validation criteria and compliance checklist
3. Implementation - Validate all workflows against standards
4. Testing/Validation - Verify fixes resolve compliance issues

## Implementation Plan

### Planning Steps

* [x] Review standardized template embedding format specification
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Template embedding standards are clearly defined
  > Command: Review template embedding standard documentation

* [x] Create comprehensive validation criteria checklist
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Validation criteria cover all compliance requirements
  > Command: Review validation checklist completeness

### Execution Steps

* [x] Validate template embedding format across all workflow files
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: All embedded templates use XML <templates> sections format
  > Command: grep -r "<templates>" dev-handbook/workflow-instructions/

* [x] Check embedded templates are positioned at end of documents
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Templates follow end-of-document placement standard
  > Command: Review template positioning in workflow files

* [x] Verify proper template reference naming conventions
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Template references use consistent naming patterns
  > Command: Validate template path references against conventions

* [x] Check workflow structure follows established guidelines
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Workflows maintain proper section organization
  > Command: Review workflow structural compliance

* [x] Identify workflows requiring compliance fixes
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Non-compliant workflows are identified and documented
  > Command: Review compliance issues list

* [x] Apply fixes to non-compliant workflow instructions
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: All identified compliance issues are resolved
  > Command: Re-validate fixed workflows against standards

* [x] Generate comprehensive compliance report
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Report documents validation results and fixes applied
  > Command: Review compliance report completeness

## Acceptance Criteria

* [x] All workflow instruction files validated against standardized format
* [x] Template embedding format compliance verified (XML <templates> sections)
* [x] Embedded templates properly positioned at document end
* [x] Template reference naming follows project conventions
* [x] Workflow structural guidelines are followed
* [x] Non-compliant workflows identified and fixed
* [x] Comprehensive compliance report documents validation results
* [x] All workflows ready for automated template synchronization
* [x] Validation process is documented for future use

## Out of Scope

* ❌ Creating new template files (handled in previous tasks)
* ❌ Implementing the synchronization script
* ❌ Changing template embedding standards (already defined)

## References

* Original requirement: improve-the-workflow-structure.md
* Dependencies: v.0.3.0+task.21 (standardized template embedding format)
* Related guides: Template embedding standard specification
* Related workflows: All files in dev-handbook/workflow-instructions/
