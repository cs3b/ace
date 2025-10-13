---
id: v.0.6.0+task.006
status: done
priority: medium
estimate: 4h
dependencies: [v.0.6.0+task.004]
---

# Update Documentation

## Objective

Update all documentation to reflect the new `.ace/*` structure and `AceTools` gem naming, ensuring users have accurate information for installation and usage.

## Scope of Work

- Update main README files
- Update installation instructions
- Update workflow instructions
- Update architecture documentation
- Update CLI tool documentation

### Deliverables

#### Create

- `docs/MIGRATION.md` - Migration guide for existing users

#### Modify

- `README.md` - Main project README
- `.ace/tools/README.md` - Tools README
- `.ace/handbook/README.md` - Handbook README
- `docs/architecture.md` - Architecture documentation
- `docs/blueprint.md` - Project blueprint
- `docs/tools.md` - Tools reference
- `docs/decisions.md` - Decision records
- `CHANGELOG.md` - Add migration entry
- All `.claude/commands/*.md` files
- All `.ace/handbook/workflow-instructions/*.wf.md` files

#### Delete

- None

## Implementation Plan

### Planning Steps

* [x] Inventory all documentation files needing updates
* [x] Draft migration guide outline
* [x] Identify user-facing breaking changes

### Execution Steps

- [x] Update main README.md:
  - Change all dev-* references to .ace/*
  - Update gem name to ace-tools
  - Update installation instructions
  - Add migration notice for existing users
  > TEST: README Links
  > Type: Link Validation
  > Assert: All internal links work
  > Command: grep -o '\[.*\](.*)' README.md | grep -v http

- [x] Update tools documentation:
  - .ace/tools/README.md - gem name, module name, installation
  - docs/tools.md - update all command references
  - docs/architecture-tools.md - module structure updates
  > TEST: Tools Docs
  > Type: Documentation Test
  > Assert: No old module names remain
  > Command: grep -r "CodingAgentTools" docs/

- [x] Update workflow instructions:
  - Update all path references in .wf.md files
  - Verify embedded templates have correct paths
  - Update command examples
  > TEST: Workflow Paths
  > Type: Path Validation
  > Assert: All paths exist
  > Command: grep -r "\.ace/" .ace/handbook/workflow-instructions/ | head -20

- [x] Create MIGRATION.md guide:
  ```markdown
  # Migration Guide: v0.5.x to v0.6.0

  ## Breaking Changes
  - Gem renamed from `coding-agent-tools` to `ace-tools`
  - Module renamed from `CodingAgentTools` to `AceTools`
  - Directory structure changed from `dev-*` to `.ace/*`

  ## Migration Steps
  1. Uninstall old gem: `gem uninstall coding-agent-tools`
  2. Install new gem: `gem install ace-tools`
  3. Update require statements: `require 'ace_tools'`
  4. Update shell configurations to use new paths

  ## Compatibility Notes
  ...
  ```

- [x] Update CHANGELOG.md:
  - Add v0.6.0 release notes
  - Document breaking changes
  - List all migration items

## Acceptance Criteria

- [x] All documentation uses new naming/paths
- [x] Installation instructions are accurate
- [x] Migration guide is comprehensive
- [x] No broken internal links
- [x] Examples use correct module names

## Out of Scope

- ❌ API documentation generation (separate task)
- ❌ Video tutorials or external docs
- ❌ Translation updates