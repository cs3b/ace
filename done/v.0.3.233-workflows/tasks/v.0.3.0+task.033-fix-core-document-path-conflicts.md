---
id: v.0.3.0+task.33
status: done
priority: high
estimate: 4h
dependencies: []
---

# Fix Core Document Path Conflicts

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

Resolve critical path inconsistencies across workflow files where some workflows reference core project documents (`what-do-we-build.md`, `architecture.md`, `blueprint.md`) in conflicting locations, causing execution failures for AI agents and breaking workflow reliability.

## Scope of Work

* Fix path conflicts in `initialize-project-structure.wf.md` where "Project Context Loading" section incorrectly references `dev-taskflow/` instead of canonical `docs/` location
* Fix path conflicts in `update-blueprint.wf.md` where the workflow targets `dev-taskflow/blueprint.md` instead of canonical `docs/blueprint.md`
* Fix path conflicts in `load-project-context.wf.md` if similar issues exist
* Ensure all workflow files consistently reference the single source of truth in `docs/` directory

### Deliverables

#### Modify

* dev-handbook/workflow-instructions/initialize-project-structure.wf.md
* dev-handbook/workflow-instructions/update-blueprint.wf.md
* dev-handbook/workflow-instructions/load-project-context.wf.md (if applicable)

## Phases

1. Audit all workflow files referencing core documents
2. Identify specific path conflicts
3. Update workflows to use canonical `docs/` paths consistently

## Implementation Plan

### Planning Steps

* [x] Analyze all workflow files for references to core documents
  > TEST: Path Reference Audit
  > Type: Pre-condition Check
  > Assert: All core document references are identified and catalogued
  > Command: bin/test --check-core-doc-references
* [x] Verify canonical locations of core documents in `docs/` directory
* [x] Document current inconsistencies and required changes

### Execution Steps

* [x] Fix initialize-project-structure.wf.md "Project Context Loading" section paths
* [x] Fix update-blueprint.wf.md target file path from dev-taskflow/ to docs/
  > TEST: Verify Blueprint Path Update
  > Type: Action Validation
  > Assert: update-blueprint.wf.md correctly targets docs/blueprint.md
  > Command: bin/test --check-workflow-paths dev-handbook/workflow-instructions/update-blueprint.wf.md
* [x] Update load-project-context.wf.md if path conflicts exist
* [x] Verify all workflow files use consistent `docs/` references for core documents
  > TEST: Verify Core Document Path Consistency
  > Type: Action Validation
  > Assert: All workflows reference core documents in docs/ directory consistently
  > Command: bin/test --check-core-doc-path-consistency

## Acceptance Criteria

* [x] AC 1: All workflow files reference core documents (`what-do-we-build.md`, `architecture.md`, `blueprint.md`) consistently in the `docs/` directory
* [x] AC 2: initialize-project-structure.wf.md "Project Context Loading" section points to correct `docs/` paths
* [x] AC 3: update-blueprint.wf.md targets the correct `docs/blueprint.md` file
* [x] AC 4: No workflow files contain conflicting path references to core documents

## Out of Scope

* ❌ Changing the canonical location of core documents (they remain in `docs/`)
* ❌ Updating other non-core document references
* ❌ Restructuring workflow file organization

## References

* dev-taskflow/current/v.0.3.0-workflows/handbook_review/f203c0c6/dr-gpro.md - Code review identifying path conflicts
* docs/what-do-we-build.md - Canonical project vision document
* docs/architecture.md - Canonical architecture document  
* docs/blueprint.md - Canonical project structure document
