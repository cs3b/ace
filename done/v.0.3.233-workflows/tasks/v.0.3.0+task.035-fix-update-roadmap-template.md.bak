---
id: v.0.3.0+task.35
status: done
priority: high
estimate: 3h
dependencies: []
---

# Fix Update Roadmap Template

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

Fix the critical template embedding error in `update-roadmap.wf.md` where it incorrectly embeds `release-readme.template.md` instead of a roadmap-related template, making the workflow non-functional for its intended purpose.

## Scope of Work

* Identify the correct template that should be embedded for roadmap updates
* Replace the incorrect `release-readme.template.md` reference with appropriate roadmap template
* Create roadmap template if it doesn't exist in the template directory
* Verify the workflow is functional for roadmap update operations

### Deliverables

#### Create

* dev-handbook/templates/roadmap/roadmap.template.md (if needed)

#### Modify

* dev-handbook/workflow-instructions/update-roadmap.wf.md

## Phases

1. Audit current update-roadmap workflow and its template usage
2. Identify or create appropriate roadmap template
3. Update workflow to reference correct template
4. Verify workflow functionality

## Implementation Plan

### Planning Steps

* [x] Analyze update-roadmap.wf.md workflow to understand its intended purpose and template needs
  > TEST: Workflow Purpose Analysis
  > Type: Pre-condition Check
  > Assert: Roadmap workflow purpose and template requirements are understood
  > Command: bin/test --check-roadmap-workflow-purpose
* [x] Check if appropriate roadmap template exists in dev-handbook/templates/
* [x] Review roadmap-definition.g.md guide to understand roadmap structure requirements

### Execution Steps

* [x] Create roadmap template file if it doesn't exist in dev-handbook/templates/roadmap/
  > TEST: Verify Roadmap Template Creation
  > Type: Action Validation
  > Assert: Roadmap template is created with proper structure
  > Command: bin/test --check-template-file dev-handbook/templates/roadmap/roadmap.template.md
* [x] Update update-roadmap.wf.md to reference correct roadmap template instead of release-readme.template.md
  > TEST: Verify Template Reference Fix
  > Type: Action Validation
  > Assert: update-roadmap.wf.md references appropriate roadmap template
  > Command: bin/test --check-template-reference dev-handbook/workflow-instructions/update-roadmap.wf.md
* [x] Verify template synchronization system can process the corrected workflow
  > TEST: Template Sync Verification
  > Type: Action Validation
  > Assert: Template sync can process update-roadmap workflow
  > Command: handbook sync-templates --dry-run

## Acceptance Criteria

* [x] AC 1: update-roadmap.wf.md embeds a roadmap-appropriate template instead of release-readme.template.md
* [x] AC 2: The embedded template is relevant to roadmap update operations
* [x] AC 3: Template synchronization system can process the workflow without errors
* [x] AC 4: Workflow is functional for its intended roadmap update purpose

## Out of Scope

* ❌ Redesigning the roadmap update workflow process
* ❌ Updating other workflow files
* ❌ Modifying existing roadmap content or structure

## References

* dev-taskflow/current/v.0.3.0-workflows/handbook_review/f203c0c6/dr-gpro.md - Code review identifying incorrect template
* dev-handbook/workflow-instructions/update-roadmap.wf.md - Target workflow file
* dev-handbook/guides/roadmap-definition.g.md - Roadmap structure guidance
* handbook sync-templates - Template synchronization tool
