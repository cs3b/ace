---
id: v.0.3.0+task.34
status: done
priority: high
estimate: 6h
dependencies: []
---

# Refactor Commit Workflow ADR Compliance with Template Extraction

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

Fix the critical ADR-002 compliance violation in `commit.wf.md` by converting embedded templates from raw markdown code blocks to the required XML `<templates>` format, and extract these templates to the template directory for proper synchronization functionality.

## Scope of Work

* Convert commit message templates in `commit.wf.md` from markdown code blocks to XML `<templates>` format per ADR-002
* Extract commit message templates to separate template files in `dev-handbook/templates/` directory
* Update the workflow to reference the extracted templates via the XML embedding system
* Ensure templates are discoverable by the template synchronization system

### Deliverables

#### Create

* dev-handbook/templates/commit/conventional-commit.template.md
* dev-handbook/templates/commit/intention-based-commit.template.md
* dev-handbook/templates/commit/multi-repo-commit.template.md

#### Modify

* dev-handbook/workflow-instructions/commit.wf.md

## Phases

1. Audit current commit workflow template structure
2. Extract templates to template directory
3. Convert workflow to use XML embedding format
4. Verify template synchronization compatibility

## Implementation Plan

### Planning Steps

* [x] Analyze current commit.wf.md template structure and identify all embedded templates
  > TEST: Template Structure Analysis
  > Type: Pre-condition Check
  > Assert: All commit message templates are identified and catalogued
  > Command: bin/test --check-commit-templates
* [x] Review ADR-002 requirements for XML template format
* [x] Plan template file organization in dev-handbook/templates/commit/ directory

### Execution Steps

* [x] Create dev-handbook/templates/commit/ directory structure
* [x] Extract feature implementation commit template to separate file
  > TEST: Verify Feature Implementation Template
  > Type: Action Validation
  > Assert: Feature implementation template is properly extracted and formatted
  > Command: bin/test --check-template-file dev-handbook/templates/commit/feature-implementation.template.md
* [x] Extract bug fix commit template to separate file
* [x] Extract refactoring commit template to separate file
* [x] Update commit.wf.md to use XML `<templates>` format with proper path references
  > TEST: Verify XML Template Embedding
  > Type: Action Validation
  > Assert: commit.wf.md uses proper XML template embedding format
  > Command: bin/test --check-xml-templates dev-handbook/workflow-instructions/commit.wf.md
* [x] Verify template synchronization system can discover new templates
  > TEST: Template Sync Compatibility
  > Type: Action Validation
  > Assert: Template sync system can process commit templates
  > Command: handbook sync-templates --dry-run

## Acceptance Criteria

* [x] AC 1: commit.wf.md uses XML `<templates>` format instead of markdown code blocks
* [x] AC 2: All commit message templates are extracted to dev-handbook/templates/commit/ directory
* [x] AC 3: Template synchronization system can discover and process the extracted templates
* [x] AC 4: Workflow complies with ADR-002 XML template embedding requirements

## Out of Scope

* ❌ Updating commit workflow logic or process steps
* ❌ Modifying other workflow files in this task
* ❌ Changing the commit message generation algorithms

## References

* dev-taskflow/current/v.0.3.0-workflows/handbook_review/f203c0c6/dr-gpro.md - Code review identifying ADR-002 violation
* docs/decisions/ADR-002.md - XML template embedding standard
* dev-handbook/workflow-instructions/commit.wf.md - Target workflow file
* handbook sync-templates - Template synchronization tool
