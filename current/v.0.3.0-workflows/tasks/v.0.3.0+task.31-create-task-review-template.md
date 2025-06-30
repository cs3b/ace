---
id: v.0.3.0+task.31
status: pending
priority: medium
estimate: 2h
dependencies: []
---

# Create Task Review Template

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/templates/ | grep -E "review|task" | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── release-tasks/
    │   └── task.template.md
    ├── review-code/
    ├── review-docs/
```

## Objective

The review-task.wf.md workflow incorrectly embeds and references `release-docs/documentation.template.md`, which is a template for feature documentation, not for task review summaries. A proper task review summary template needs to be created and the workflow updated to use it.

## Scope of Work

* Create a new task-review-summary.template.md
* Update review-task.wf.md to embed the correct template
* Ensure the template captures all necessary review information
* Follow established template format standards

### Deliverables

#### Create

* dev-handbook/templates/review-tasks/task-review-summary.template.md

#### Modify

* dev-handbook/workflow-instructions/review-task.wf.md

#### Delete

* None

## Phases

1. Design task review template structure
2. Create the template file
3. Update workflow to use new template
4. Validate template usage

## Implementation Plan

### Planning Steps

* [ ] Review current review-task.wf.md to understand required output
  > TEST: Requirements Analyzed
  > Type: Pre-condition Check
  > Assert: Task review output requirements documented
  > Command: bin/test --check-requirements-analysis
* [ ] Examine existing review templates for consistent format
* [ ] Design appropriate structure for task review summaries

### Execution Steps

* [ ] Create dev-handbook/templates/review-tasks/ directory if needed
* [ ] Create task-review-summary.template.md with appropriate sections
  > TEST: Template Created
  > Type: File Check
  > Assert: Template file exists with required sections
  > Command: bin/test --check-template-created
* [ ] Update review-task.wf.md to remove incorrect template reference
* [ ] Add correct XML template embedding for new template
  > TEST: Correct Template Embedded
  > Type: Content Validation
  > Assert: review-task.wf.md embeds task-review-summary.template.md
  > Command: bin/test --check-correct-embedding
* [ ] Ensure template includes all necessary review elements

## Acceptance Criteria

* [ ] New task review summary template created
* [ ] Template includes sections for: task completion status, deliverables, issues found, recommendations
* [ ] review-task.wf.md updated to use the correct template
* [ ] No references to documentation.template.md in review-task workflow
* [ ] Template follows established format standards

## Out of Scope

* ❌ Modifying the review process logic
* ❌ Creating templates for other review types
* ❌ Changing existing templates
* ❌ Updating other workflow files

## References

* review-task.wf.md (current incorrect template usage)
* Existing templates for format consistency
* Workflow review reports identifying the issue