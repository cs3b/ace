---
id: v.0.3.0+task.38
status: done
priority: medium
estimate: 2h
dependencies: []
---

# Reorganize Meta Content Structure

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
│   └── README.md
├── embedded-testing-guide.g.md
├── error-handling
│   ├── ruby.md
│   ├── rust.md
│   └── typescript.md
├── error-handling.g.md
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

15 directories, 64 files
```

## Objective

Clean up the meta content structure by properly organizing template files, guide definition files, and the embedded testing guide. This addresses the mixed content types currently in `dev-handbook/guides/.meta/` and establishes a clear, logical organization.

## Scope of Work

* Move template files to appropriate template directory
* Organize guide definition files in the proper location
* Relocate and rename the embedded testing guide to be more appropriately named and located
* Remove empty directory after reorganization

### Deliverables

#### Create

* dev-handbook/.meta/tpl/ (templates directory)
* dev-handbook/guides/embedded-testing-guide.g.md (renamed and relocated)

#### Modify

* dev-handbook/.meta/gds/ (add moved guide definition files)
* dev-handbook/.meta/tpl/ (add moved template files)

#### Delete

* dev-handbook/guides/.meta/ (empty directory after reorganization)

## Phases

1. Audit - Review current .meta content structure
2. Create - Set up proper directory structure
3. Reorganize - Move files to appropriate locations
4. Rename - Update embedded testing guide name and location
5. Cleanup - Remove empty directories

## Implementation Plan

### Planning Steps

* [x] Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Key components and their relationships are identified
  > Command: ls -la dev-handbook/guides/.meta/ && ls -la dev-handbook/.meta/
* [x] Research best practices and design approach
* [x] Plan detailed implementation strategy

### Execution Steps

* [x] Step 1: Create dev-handbook/.meta/tpl/ directory for templates
* [x] Step 2: Move template files from guides/.meta/ to .meta/tpl/
  > TEST: Verify Template Files Moved
  > Type: Action Validation
  > Assert: Template files are in the new tpl directory
  > Command: ls -la dev-handbook/.meta/tpl/
* [x] Step 3: Move guide definition files from guides/.meta/ to .meta/gds/
  > TEST: Verify Guide Files Moved
  > Type: Action Validation
  > Assert: Guide definition files are in the gds directory
  > Command: ls -la dev-handbook/.meta/gds/
* [x] Step 4: Move and rename embedded testing guide to dev-handbook/guides/
  > TEST: Verify Embedded Testing Guide Relocated
  > Type: Action Validation
  > Assert: Embedded testing guide is properly renamed and located
  > Command: ls -la dev-handbook/guides/embedded-testing-guide.g.md
* [ ] Step 5: Remove empty guides/.meta/ directory
  > TEST: Verify Directory Cleanup
  > Type: Action Validation
  > Assert: The empty guides/.meta/ directory is removed
  > Command: test ! -d dev-handbook/guides/.meta/
* [ ] Step 6: Commit changes with intention-based message
  > TEST: Verify Commit Success
  > Type: Action Validation
  > Assert: Changes are committed successfully
  > Command: git log --oneline -1

## Acceptance Criteria

* [x] AC 1: All template files moved to dev-handbook/.meta/tpl/
* [x] AC 2: All guide definition files moved to dev-handbook/.meta/gds/
* [x] AC 3: Embedded testing guide renamed and relocated to dev-handbook/guides/
* [ ] AC 4: Empty guides/.meta/ directory removed
* [ ] AC 5: Changes committed with appropriate message

## Out of Scope

* ❌ Updating references to moved files in other documents
* ❌ Modifying content within the moved files
* ❌ Creating new template or guide files

## References

* User analysis: "analyze dev-handbook/guides/.meta and identified templates -> dev-handbook/.meta/tpl/ (templates) guides -> dev-handbook/.meta/gds/ one guide is more the for guides / workflow instructions (handbook meta) dev-handbook/guides/.meta/workflow-instructions-embeding-tests.g.md this guide is about using embeded tests (e.g.: we use it also in tasks) -> this should be move to dev-handbook/guides and rename more approprierate (it's not related to workflows only)"
