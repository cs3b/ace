---
id: v.0.3.0+task.36
status: done
priority: high
estimate: 2h
dependencies: []
---

# Fix Create ADR Directory Path

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/guides
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

Fix the incorrect directory path reference in `create-adr.wf.md` Step 7, which currently points to `docs/architecture-decisions/` instead of the correct canonical path `docs/decisions/` established by the project structure.

## Scope of Work

* Update the directory path in `create-adr.wf.md` Step 7 from `docs/architecture-decisions/` to `docs/decisions/`
* Ensure the workflow correctly references the canonical ADR storage location
* Verify consistency with project documentation structure

### Deliverables

#### Modify

* .ace/handbook/workflow-instructions/create-adr.wf.md

## Phases

1. Locate the incorrect path reference in create-adr workflow
2. Update the path to the correct canonical location
3. Verify consistency with project structure

## Implementation Plan

### Planning Steps

* [x] Locate Step 7 in create-adr.wf.md and identify the incorrect path reference
  > TEST: Path Reference Location
  > Type: Pre-condition Check
  > Assert: Incorrect path reference in Step 7 is identified
  > Command: bin/test --check-adr-path-reference
* [x] Verify the canonical ADR directory location in project structure
* [x] Check for other potential path references that might need updating

### Execution Steps

* [x] Update Step 7 path reference from `docs/architecture-decisions/` to `docs/decisions/`
  > TEST: Verify Path Update
  > Type: Action Validation
  > Assert: create-adr.wf.md Step 7 references correct docs/decisions/ path
  > Command: bin/test --check-corrected-adr-path .ace/handbook/workflow-instructions/create-adr.wf.md
* [x] Verify no other incorrect path references exist in the workflow
  > TEST: Complete Path Consistency Check
  > Type: Action Validation
  > Assert: All path references in create-adr.wf.md are correct
  > Command: bin/test --check-all-paths .ace/handbook/workflow-instructions/create-adr.wf.md

## Acceptance Criteria

* [x] AC 1: create-adr.wf.md Step 7 references the correct `docs/decisions/` directory
* [x] AC 2: No incorrect `docs/architecture-decisions/` references remain in the workflow
* [x] AC 3: Path references are consistent with canonical project structure
* [x] AC 4: Workflow will correctly create ADRs in the proper location

## Out of Scope

* ❌ Moving existing ADRs to different locations
* ❌ Updating other workflow files in this task
* ❌ Changing ADR numbering or naming conventions

## References

* .ace/taskflow/current/v.0.3.0-workflows/handbook_review/f203c0c6/dr-gpro.md - Code review identifying incorrect path
* docs/decisions/ - Canonical ADR directory location
* docs/architecture.md - Documentation of directory structure
* .ace/handbook/workflow-instructions/create-adr.wf.md - Target workflow file
