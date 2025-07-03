---
id: v.0.3.0+task.39
status: pending
priority: medium
estimate: 8h
dependencies: []
---

# Create Meta Content Management Workflow Instructions

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

Create specialized meta workflow instructions for managing handbook content creation, updates, and reviews. These workflows will enable handbook maintainers to systematically manage content without over-engineering, making the handbook content management more efficient and consistent.

## Scope of Work

* Create 4 meta workflow instructions for content management
* Leverage existing patterns from review-task.wf.md and draft-release.wf.md
* Embed relevant content from .meta/gds/ definitions
* Follow established workflow instruction standards
* Place in appropriate meta directory structure

### Deliverables

#### Create

* dev-handbook/.meta/wfi/manage-workflow-instructions.wf.md
* dev-handbook/.meta/wfi/manage-guides.wf.md
* dev-handbook/.meta/wfi/review-workflows.wf.md
* dev-handbook/.meta/wfi/review-guides.wf.md

#### Modify

* None

#### Delete

* None

## Phases

1. Audit - Review existing workflow patterns and meta content structure
2. Design - Plan workflow structure based on existing successful patterns
3. Implement - Create the 4 meta workflow instruction files
4. Validate - Ensure workflows follow established standards
5. Document - Update any necessary cross-references

## Implementation Plan

### Planning Steps

* [ ] Analyze existing workflow patterns from review-task.wf.md and draft-release.wf.md
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Key workflow patterns and structures are identified for reuse
  > Command: grep -l "## Process Steps\|## High-Level Execution Plan" dev-handbook/workflow-instructions/*.wf.md
* [ ] Review meta content definitions in .meta/gds/
  > TEST: Meta Content Review Complete
  > Type: Pre-condition Check
  > Assert: Guide and workflow instruction standards are understood
  > Command: ls -la dev-handbook/.meta/gds/
* [ ] Plan workflow structure and embedded content strategy
* [ ] Design batch processing approach for review workflows

### Execution Steps

* [ ] Step 1: Create manage-workflow-instructions.wf.md for workflow creation/updates
  > TEST: Workflow Instruction Management File Created
  > Type: Action Validation
  > Assert: The manage-workflow-instructions.wf.md file exists with proper structure
  > Command: test -f dev-handbook/.meta/wfi/manage-workflow-instructions.wf.md && grep -q "## Goal" dev-handbook/.meta/wfi/manage-workflow-instructions.wf.md
* [ ] Step 2: Create manage-guides.wf.md for guide creation/updates
  > TEST: Guide Management File Created
  > Type: Action Validation
  > Assert: The manage-guides.wf.md file exists with proper structure
  > Command: test -f dev-handbook/.meta/wfi/manage-guides.wf.md && grep -q "## Goal" dev-handbook/.meta/wfi/manage-guides.wf.md
* [ ] Step 3: Create review-workflows.wf.md for batch workflow reviews
  > TEST: Workflow Review File Created
  > Type: Action Validation
  > Assert: The review-workflows.wf.md file exists with proper structure
  > Command: test -f dev-handbook/.meta/wfi/review-workflows.wf.md && grep -q "## Goal" dev-handbook/.meta/wfi/review-workflows.wf.md
* [ ] Step 4: Create review-guides.wf.md for batch guide reviews
  > TEST: Guide Review File Created
  > Type: Action Validation
  > Assert: The review-guides.wf.md file exists with proper structure
  > Command: test -f dev-handbook/.meta/wfi/review-guides.wf.md && grep -q "## Goal" dev-handbook/.meta/wfi/review-guides.wf.md
* [ ] Step 5: Validate all workflows follow established standards
  > TEST: Workflow Standards Compliance
  > Type: Post-condition Check
  > Assert: All created workflows have required sections and proper structure
  > Command: for file in dev-handbook/.meta/wfi/*.wf.md; do grep -q "## Goal\|## Prerequisites\|## Process Steps" "$file" || echo "Missing sections in $file"; done
* [ ] Step 6: Update any necessary cross-references or documentation
  > TEST: Cross-references Updated
  > Type: Post-condition Check
  > Assert: Any necessary documentation updates are completed
  > Command: bin/lint | grep -q "No broken links" || echo "Check for broken links"

## Acceptance Criteria

* [ ] AC 1: All 4 meta workflow instruction files created in dev-handbook/.meta/wfi/
* [ ] AC 2: Each workflow follows established workflow instruction standards
* [ ] AC 3: Workflows leverage existing patterns from successful examples
* [ ] AC 4: Embedded content from .meta/gds/ definitions is properly incorporated
* [ ] AC 5: All workflows are self-contained and follow meta-workflow principles
* [ ] AC 6: No broken links or references introduced

## Out of Scope

* ❌ Modifying existing workflow instructions in workflow-instructions/
* ❌ Creating new guide definition standards
* ❌ Implementing automated workflow execution
* ❌ Creating UI or interactive tools for workflow management

## References

* User request: "creating workflow instruction for updating/creating workflow instruction, updating/creating guides, review workflows (more than one against, usually all), review guides (more than one against, usually all) - the goal is to make it more manageable (in past we have wfi for guides and workflows) how to attach is the best - without creating too much stuff, and getting results. because those are meta workflows -> we should put them in dev-handbook/.meta/wfi"
* Existing patterns: dev-handbook/workflow-instructions/review-task.wf.md
* Batch processing patterns: dev-handbook/workflow-instructions/draft-release.wf.md
* Content standards: dev-handbook/.meta/gds/workflow-instructions-definition.g.md
* Content standards: dev-handbook/.meta/gds/guides-definition.g.md