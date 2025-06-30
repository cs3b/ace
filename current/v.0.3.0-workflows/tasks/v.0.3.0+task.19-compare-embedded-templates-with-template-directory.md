---
id: v.0.3.0+task.19
status: pending
priority: high
estimate: 4h
dependencies: [v.0.3.0+task.18]
---

# Compare Embedded Templates with Template Directory

## 0. Directory Audit ✅

_Command run:_
```bash
tree -L 3 dev-handbook/templates | sed 's/^/    /'
```

_Result excerpt:_

```
[To be populated during execution]
```

## Objective

Perform detailed comparison between embedded templates found in workflow instructions and existing template files in dev-handbook/templates/ directory. Identify matches, differences, and gaps to determine which templates need to be created, updated, or synchronized.

Link back to original requirement: Template unification and synchronization (improve-the-workflow-structure.md)

## Scope of Work

* Compare embedded templates from audit with existing template files
* Identify exact matches, partial matches, and missing templates
* Document differences and propose template creation locations
* Create mapping between embedded templates and corresponding template files

### Deliverables

#### Create

* template-comparison-report.md - detailed comparison analysis
* missing-templates-plan.md - proposal for creating missing templates

#### Modify  

* None (analysis task)

#### Delete

* None

## Phases

1. Research/Analysis - Load audit results and examine template directory
2. Design/Planning - Create comparison methodology and mapping approach
3. Implementation - Execute comparison and document findings
4. Testing/Validation - Verify accuracy of comparisons and recommendations

## Implementation Plan

### Planning Steps

* [ ] Review embedded templates audit results from previous task
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Embedded templates audit is complete and accessible
  > Command: test -f dev-taskflow/current/v.0.3.0-workflows/embedded-templates-audit.md

* [ ] Examine current template directory structure and contents
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Template directory exists and contains template files
  > Command: find dev-handbook/templates -name "*.md" | head -5

### Execution Steps

* [ ] Match embedded templates with existing template files by content similarity
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: All possible matches are identified and documented
  > Command: Review matching criteria and results

* [ ] Identify embedded templates with no corresponding template file
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Missing templates are clearly identified
  > Command: Verify missing templates list is complete

* [ ] Compare content differences between matched templates
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Content differences are documented for matched templates
  > Command: Review difference analysis completeness

* [ ] Propose locations for missing template files following project conventions
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Proposed locations follow dev-handbook/templates structure
  > Command: Verify proposed paths against existing template organization

* [ ] Create comprehensive comparison report with recommendations
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Report includes all findings and actionable recommendations
  > Command: Review report completeness and clarity

## Acceptance Criteria

* [ ] All embedded templates have been compared against existing template files
* [ ] Matches, partial matches, and missing templates clearly identified
* [ ] Content differences documented for matched templates
* [ ] Proposed locations for missing templates follow project conventions
* [ ] Comprehensive comparison report provides clear action plan
* [ ] Foundation established for template creation and synchronization

## Out of Scope

* ❌ Creating actual template files (covered in subsequent task)
* ❌ Modifying existing template files
* ❌ Implementing synchronization mechanisms

## References

* Original requirement: improve-the-workflow-structure.md
* Dependencies: v.0.3.0+task.18 (embedded templates audit)
* Related templates: dev-handbook/templates/