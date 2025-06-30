---
id: v.0.3.0+task.17
status: pending
priority: high
estimate: 8h
dependencies: []
---

# Extract Templates to dev-handbook/templates Directory

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
    │   ├── _code-review-from-diff.md
    │   ├── _code-review-system.md
    │   ├── _doc-review-system.md
    │   ├── _documentation-update-from-diff.md
    │   ├── _meta-code-review-comprison.md
    │   ├── _meta-doc-review-combine.md
    │   ├── _meta-test-review-combine.md
    │   ├── _test-review-system.md
    │   └── README.md
    ├── draft-release
    │   ├── README.md
    │   └── v.x.x.x
    ├── initialize-project-templates
    │   ├── architecture.md
    │   ├── blueprint.md
    │   ├── PRD.md
    │   ├── README.md
    │   ├── v.0.0.0
    │   └── what-do-we-build.md
    [... 18 directories, 74 files total]
```

## Objective

Improve the workflow structure by extracting all template files from `dev-handbook/guides/` to a dedicated `dev-handbook/templates/` directory with proper naming conventions. This will:

1. **Separate templates from guides**: Clear distinction between reusable templates and instructional guides
2. **Categorize template types**: Organize document templates, task templates, and system prompts separately
3. **Implement consistent naming**: Use `.prompt.md` and `.template.md` suffixes to prevent confusion with actual documentation
4. **Improve discoverability**: Organize templates by category for easier navigation
5. **Prevent mixing**: Ensure templates are never mixed with real documentation when searching for files

Link back to original requirement: `dev-taskflow/current/v.0.3.0-workflows/backlog/improve-the-workflow-structure.md`

## Scope of Work

* **Primary Focus**: Move 27 identified template files from `dev-handbook/guides/` to `dev-handbook/templates/`
* **Key Areas**: System prompts, document templates, task templates, release management templates
* **Technical Components**: File system reorganization, reference updates, link validation

### Deliverables

#### File Moves

**Code Review Templates:**
* `dev-handbook/guides/code-review/_code-review-system.md` → `dev-handbook/templates/review-code/system.prompt.md`
* `dev-handbook/guides/code-review/_code-review-from-diff.md` → `dev-handbook/templates/review-code/diff.prompt.md`
* `dev-handbook/guides/code-review/_doc-review-system.md` → `dev-handbook/templates/review-docs/system.prompt.md`
* `dev-handbook/guides/code-review/_documentation-update-from-diff.md` → `dev-handbook/templates/review-docs/diff.prompt.md`
* `dev-handbook/guides/code-review/_test-review-system.md` → `dev-handbook/templates/review-test/system.prompt.md`
* `dev-handbook/guides/code-review/_meta-code-review-comprison.md` → `dev-handbook/templates/review-synthesizer/system.prompt.md`
* `dev-handbook/guides/code-review/_meta-doc-review-combine.md` → `dev-handbook/templates/review-synthesizer/docs-system.prompt.md`
* `dev-handbook/guides/code-review/_meta-test-review-combine.md` → `dev-handbook/templates/review-synthesizer/test-system.prompt.md`

**Release Management Templates:**
* `dev-handbook/guides/draft-release/v.x.x.x/tasks/_template.md` → `dev-handbook/templates/release-tasks/task.template.md`
* `dev-handbook/guides/draft-release/v.x.x.x/tasks/_example.md` → `dev-handbook/templates/release-tasks/example.md`
* `dev-handbook/guides/draft-release/v.x.x.x/reflections/_template.md` → `dev-handbook/templates/release-reflections/retrospective.template.md`
* `dev-handbook/guides/draft-release/v.x.x.x/docs/_template.md` → `dev-handbook/templates/release-docs/documentation.template.md`
* `dev-handbook/guides/draft-release/v.x.x.x/researches/_template.md` → `dev-handbook/templates/release-research/investigation.template.md`
* `dev-handbook/guides/draft-release/v.x.x.x/test-cases/_template.md` → `dev-handbook/templates/release-testing/test-case.template.md`
* `dev-handbook/guides/draft-release/v.x.x.x/user-experience/_template.md` → `dev-handbook/templates/release-ux/user-experience.template.md`
* `dev-handbook/guides/draft-release/v.x.x.x/codemods/_template.md` → `dev-handbook/templates/release-codemods/transformation.template.md`
* `dev-handbook/guides/draft-release/v.x.x.x/v.x.x.x-codename.md` → `dev-handbook/templates/release-planning/release-readme.template.md`

**Project Initialization Templates:**
* `dev-handbook/guides/draft-release/v.x.x.x/decisions/_template.md` → `dev-handbook/templates/project-docs/decisions/adr.template.md`
* `dev-handbook/guides/initialize-project-templates/PRD.md` → `dev-handbook/templates/project-docs/prd.template.md`
* `dev-handbook/guides/initialize-project-templates/architecture.md` → `dev-handbook/templates/project-docs/architecture.template.md`
* `dev-handbook/guides/initialize-project-templates/blueprint.md` → `dev-handbook/templates/project-docs/blueprint.template.md`
* `dev-handbook/guides/initialize-project-templates/what-do-we-build.md` → `dev-handbook/templates/project-docs/vision.template.md`

**Project Setup Task Templates:**
* `dev-handbook/guides/initialize-project-templates/v.0.0.0/tasks/TEMPLATE-complete-prd.md` → `dev-handbook/templates/release-v.0.0.0/03-complete-prd.task.template.md`
* `dev-handbook/guides/initialize-project-templates/v.0.0.0/tasks/TEMPLATE-complete-core-documentation.md` → `dev-handbook/templates/release-v.0.0.0/02-complete-documentation.task.template.md`
* `dev-handbook/guides/initialize-project-templates/v.0.0.0/tasks/TEMPLATE-create-project-roadmap.md` → `dev-handbook/templates/release-v.0.0.0/04-create-roadmap.task.template.md`
* `dev-handbook/guides/initialize-project-templates/v.0.0.0/tasks/TEMPLATE-setup-docs-project-structure.md` → `dev-handbook/templates/release-v.0.0.0/01-setup-structure.task.template.md`
* `dev-handbook/guides/initialize-project-templates/v.0.0.0/tasks/TEMPLATE-archive-v000-release.md` → `dev-handbook/templates/release-v.0.0.0/05-archive-release.task.template.md`

**Total:** 27 template files to be moved from `guides/` to `templates/` with proper naming conventions

## Phases

1. **Research/Analysis** - Search and catalog all templates in guides directory
2. **Design/Planning** - Define new directory structure with proper naming conventions
3. **Implementation** - Move files and update all references
4. **Testing/Validation** - Verify no broken links exist after migration

## Implementation Plan

### Planning Steps

* [x] **Search for all templates inside the guides directory**
  > TEST: Template Discovery Validation
  > Type: Pre-condition Check
  > Assert: All 27 template files identified and cataloged by type and purpose
  > Command: `find dev-handbook/guides -name "_*" -o -name "*template*" -o -name "TEMPLATE-*" | wc -l`

* [x] **Propose the new directory structure with proper naming conventions**
  > TEST: Structure Design Approval
  > Type: Pre-condition Check
  > Assert: Directory structure follows pattern: review-code/, review-docs/, release-*, project-* with .prompt.md/.template.md suffixes
  > Command: Manual review of proposed structure

### Execution Steps

* [ ] **Create the new template directory structure**
  > TEST: Directory Creation Validation
  > Type: Action Validation
  > Assert: All required directories exist under dev-handbook/templates/
  > Command: `find dev-handbook/templates -type d | sort`

* [ ] **Move all template files to their new locations with proper names**
  > TEST: File Migration Validation
  > Type: Action Validation
  > Assert: All 27 files moved successfully with correct naming conventions
  > Command: `find dev-handbook/templates -name "*.prompt.md" -o -name "*.template.md" | wc -l`

* [ ] **Scan dev-handbook for references to old template paths**
  > TEST: Reference Discovery
  > Type: Action Validation
  > Assert: All references to old template paths identified for updating
  > Command: `grep -r "guides.*_.*\.md\|guides.*template\|guides.*TEMPLATE" dev-handbook/`

* [ ] **Scan dev-tools for references to old template paths**
  > TEST: Dev-tools Reference Discovery
  > Type: Action Validation
  > Assert: All references in dev-tools scripts identified for updating
  > Command: `grep -r "guides.*_.*\.md\|guides.*template\|guides.*TEMPLATE" dev-tools/`

* [ ] **Update all references to point to new template locations**
  > TEST: Reference Update Validation
  > Type: Action Validation
  > Assert: All references updated to new paths in templates/ directory
  > Command: `grep -r "templates.*\.prompt\.md\|templates.*\.template\.md" dev-handbook/ dev-tools/`

* [ ] **Validate no broken links exist after migration**
  > TEST: Link Validation
  > Type: Action Validation
  > Assert: No broken internal links detected in documentation
  > Command: `bin/lint` (includes link checking)

## Acceptance Criteria

* [ ] All 27 template files successfully moved from guides/ to templates/
* [ ] New directory structure follows the approved naming convention
* [ ] All template files use appropriate suffixes (.prompt.md or .template.md)
* [ ] All references in dev-handbook updated to new paths
* [ ] All references in dev-tools updated to new paths
* [ ] No broken links remain after migration
* [ ] `bin/lint` command passes without link-related errors
* [ ] Original requirement from improve-the-workflow-structure.md fully addressed

## Out of Scope

* ❌ Creating new templates or modifying template content
* ❌ Updating templates in other repositories outside this meta-repository
* ❌ Restructuring non-template files in guides directory
* ❌ Modifying the guides directory structure beyond template removal

## References

* Original requirement: `dev-taskflow/current/v.0.3.0-workflows/backlog/improve-the-workflow-structure.md`
* Related workflow: `dev-handbook/workflow-instructions/create-task.wf.md`
* Linting command: `bin/lint` (for link validation)
