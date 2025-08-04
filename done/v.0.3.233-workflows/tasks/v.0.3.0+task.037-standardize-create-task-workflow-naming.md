---
id: v.0.3.0+task.37
status: done
priority: medium
estimate: 2h
dependencies: []
---

# Standardize Create Task Workflow Naming

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/guides
    ├── atom-house-rules.md
    ├── changelog.g.md
    ├── code-review
    │   └── README.md
    ├── code-review-diff-for-docs-update.g.md
    ├── coding-standards
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── coding-standards.g.md
    ├── debug-troubleshooting.g.md
    ├── documentation
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── documentation.g.md
    ├── draft-release
    │   ├── README.md
    │   └── v.x.x.x
    ├── error-handling
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── error-handling.g.md
    ├── initialize-project-templates
    │   ├── README.md
    │   └── v.0.0.0
    ├── migration
    ├── performance
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── performance.g.md
    ├── project-management.g.md
    ├── quality-assurance
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── quality-assurance.g.md
    ├── README.md
    ├── release-codenames.g.md
    ├── release-publish
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── release-publish.g.md
    ├── roadmap-definition.g.md
    ├── security
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── security.g.md
    ├── strategic-planning.g.md
    ├── task-definition.g.md
    ├── template-sync-operations.md
    ├── template-synchronization.md
    ├── temporary-file-management.g.md
    ├── test-driven-development-cycle
    │   ├── meta-documentation.md
    │   ├── ruby-application.md
    │   ├── ruby-gem.md
    │   ├── rust-cli.md
    │   ├── rust-wasm-zed.md
    │   ├── typescript-nuxt.md
    │   └── typescript-vue.md
    ├── testing
    │   ├── ruby-rspec-config-examples.md
    │   ├── ruby-rspec.md
    │   ├── rust.md
    │   └── typescript-bun.md
    ├── testing-tdd-cycle.g.md
    ├── testing.g.md
    ├── troubleshooting
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── version-control
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    └── version-control-system.g.md
```

## Objective

Standardize the naming inconsistency in `create-task.wf.md` by updating the H1 title from "Breakdown Notes into Tasks" to "Create Tasks" to match the filename, and generalize the overly specific "Directory Audit" step to be more flexible and applicable to different project contexts.

## Scope of Work

* Update the H1 title in `create-task.wf.md` from "Breakdown Notes into Tasks" to "Create Tasks"
* Generalize the "Directory Audit" step to be less specific than just `dev-handbook/guides`
* Make the directory audit step more contextually appropriate or optional
* Ensure naming consistency between filename and workflow title

### Deliverables

#### Modify

* dev-handbook/workflow-instructions/create-task.wf.md

## Phases

1. Update workflow title for naming consistency
2. Generalize directory audit step
3. Verify workflow usability across different contexts

## Implementation Plan

### Planning Steps

* [x] Review current create-task.wf.md structure and identify naming inconsistencies
  > TEST: Naming Consistency Analysis
  > Type: Pre-condition Check
  > Assert: Title-filename mismatch and overly specific audit step are identified
  > Command: bin/test --check-workflow-naming-consistency
* [x] Determine appropriate generalization for directory audit step
* [x] Consider making directory audit step optional or contextual

### Execution Steps

* [x] Update H1 title from "Breakdown Notes into Tasks" to "Create Tasks"
  > TEST: Verify Title Update
  > Type: Action Validation
  > Assert: Workflow title matches filename convention
  > Command: bin/test --check-workflow-title dev-handbook/workflow-instructions/create-task.wf.md
* [x] Generalize directory audit step to be less specific than `dev-handbook/guides`
  > TEST: Verify Directory Audit Generalization
  > Type: Action Validation
  > Assert: Directory audit step is appropriately generalized
  > Command: bin/test --check-audit-step-generalization dev-handbook/workflow-instructions/create-task.wf.md
* [x] Update embedded template to reflect the generalized directory audit approach
  > TEST: Template Consistency Check
  > Type: Action Validation
  > Assert: Embedded template reflects generalized approach
  > Command: bin/test --check-template-consistency dev-handbook/workflow-instructions/create-task.wf.md

## Acceptance Criteria

* [x] AC 1: Workflow H1 title is "Create Tasks" matching the filename convention
* [x] AC 2: Directory audit step is generalized and not overly specific to `dev-handbook/guides`
* [x] AC 3: Workflow maintains its functionality while being more broadly applicable
* [x] AC 4: Embedded template reflects the updated approach

## Out of Scope

* ❌ Changing the core functionality of the task creation workflow  
* ❌ Updating other workflow files in this task
* ❌ Modifying the workflow's embedded template structure beyond directory audit generalization

## References

* dev-taskflow/current/v.0.3.0-workflows/handbook_review/f203c0c6/dr-gpro.md - Code review identifying naming inconsistency
* dev-handbook/workflow-instructions/create-task.wf.md - Target workflow file
* dev-handbook/templates/release-tasks/task.template.md - Embedded template structure
