---
id: v.0.3.0+task.19
status: done
priority: high
estimate: 4h
dependencies: [v.0.3.0+task.18]
---

# Compare Embedded Templates with Template Directory

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 .ace/handbook/templates | sed 's/^/    /'
```

_Result excerpt:_

```
.ace/handbook/templates
├── project-docs
│   ├── architecture.template.md
│   ├── blueprint.template.md
│   ├── decisions
│   │   └── adr.template.md
│   ├── prd.template.md
│   └── vision.template.md
├── release-codemods
│   └── transformation.template.md
├── release-docs
│   └── documentation.template.md
├── release-planning
│   └── release-readme.template.md
├── release-reflections
│   └── retrospective.template.md
├── release-research
│   └── investigation.template.md
├── release-tasks
│   ├── example.md
│   └── task.template.md
├── release-testing
│   └── test-case.template.md
├── release-ux
│   └── user-experience.template.md
├── release-v.0.0.0
│   ├── 01-setup-structure.task.template.md
│   ├── 02-complete-documentation.task.template.md
│   ├── 03-complete-prd.task.template.md
│   ├── 04-create-roadmap.task.template.md
│   └── 05-archive-release.task.template.md
├── review-code
│   ├── diff.prompt.md
│   └── system.prompt.md
├── review-docs
│   ├── diff.prompt.md
│   └── system.prompt.md
├── review-synthesizer
│   ├── docs-system.prompt.md
│   ├── system.prompt.md
│   └── test-system.prompt.md
└── review-test
    └── system.prompt.md

16 directories, 27 files
```

## Objective

Perform detailed comparison between embedded templates found in workflow instructions and existing template files in .ace/handbook/templates/ directory. Identify matches, differences, and gaps to determine which templates need to be created, updated, or synchronized.

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

* [x] Review embedded templates audit results from previous task
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Embedded templates audit is complete and accessible
  > Command: test -f .ace/taskflow/current/v.0.3.0-workflows/docs/embedded-templates-audit.md
  > RESULT: ✅ Audit file exists and accessible

* [x] Examine current template directory structure and contents
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Template directory exists and contains template files
  > Command: find .ace/handbook/templates -name "*.md" | head -5
  > RESULT: ✅ 27 template files found in 16 directories

### Execution Steps

* [x] Match embedded templates with existing template files by content similarity
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: All possible matches are identified and documented
  > Command: Review matching criteria and results
  > RESULT: ✅ 6 partial matches identified, no exact matches found

* [x] Identify embedded templates with no corresponding template file
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Missing templates are clearly identified
  > Command: Verify missing templates list is complete
  > RESULT: ✅ 7 missing template categories identified with 21 total missing templates

* [x] Compare content differences between matched templates
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Content differences are documented for matched templates
  > Command: Review difference analysis completeness
  > RESULT: ✅ Detailed content differences documented for all 6 partial matches

* [x] Propose locations for missing template files following project conventions
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Proposed locations follow .ace/handbook/templates structure
  > Command: Verify proposed paths against existing template organization
  > RESULT: ✅ All proposed locations follow existing directory conventions and naming patterns

* [x] Create comprehensive comparison report with recommendations
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Report includes all findings and actionable recommendations
  > Command: Review report completeness and clarity
  > RESULT: ✅ Comprehensive comparison report and missing templates plan created

## Acceptance Criteria

* [x] All embedded templates have been compared against existing template files
* [x] Matches, partial matches, and missing templates clearly identified
* [x] Content differences documented for matched templates
* [x] Proposed locations for missing templates follow project conventions
* [x] Comprehensive comparison report provides clear action plan
* [x] Foundation established for template creation and synchronization

## Out of Scope

* ❌ Creating actual template files (covered in subsequent task)
* ❌ Modifying existing template files
* ❌ Implementing synchronization mechanisms

## References

* Original requirement: improve-the-workflow-structure.md
* Dependencies: v.0.3.0+task.18 (embedded templates audit)
* Related templates: .ace/handbook/templates/
