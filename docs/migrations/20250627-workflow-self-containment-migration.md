# Migration Guide: Workflow Self-Containment Breaking Changes

**Date**: 2025-06-27
**Breaking Change**: Workflow instructions refactored for complete independence
**Affected Version**: v.0.3.0-workflows
**Migration Required**: Yes

## Overview

This document provides a comprehensive migration guide for the fundamental architectural shift from reference-based workflows to self-contained, independent workflow instructions. This is a **breaking change** that affects all workflow instructions and requires immediate attention for teams using the workflow system.

## What Changed

### Core Paradigm Shift: "Embed, Don't Reference"

The workflow instruction system has been completely refactored to eliminate external dependencies and cross-references. This breaking change impacts how workflows are structured, executed, and maintained.

#### Before (Reference-Based)

```markdown
# Old Workflow Pattern
## Process Steps
1. Load environment using [Load Environment Workflow](dev-handbook/workflow-instructions/load-env.wf.md)
2. See [Coding Standards](dev-handbook/guides/coding-standards.g.md) for formatting rules
3. Use template from `dev-handbook/guides/draft-release/v.x.x.x/tasks/_template.md`
```

#### After (Self-Contained)

```markdown
# New Workflow Pattern
## Project Context Loading
* Load project objectives: `docs/what-do-we-build.md`
* Load architecture: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`

## High-Level Execution Plan
### Planning Phase
* [ ] Analyze requirements
### Execution Phase  
- [ ] Implement solution

## Process Steps
1. **Load Context**: Load the specified files from Project Context Loading section
2. **Apply Standards**: Use embedded coding standards:
   - Use 2 spaces for indentation
   - Limit lines to 100 characters
   - Follow conventional commit format: `type(scope): description`

## Embedded Templates
### Task Template
```yaml
---
id: v.X.Y.Z+task.N
status: pending
priority: medium
estimate: 2h
dependencies: []
---
# Task Title
## Implementation Plan
[Details embedded here]
```

```

## Breaking Changes Summary

### 1. Workflow File Changes

**Renamed Workflows:**
- `load-env.wf.md` → `load-project-context.wf.md`

**Removed Workflows:**
- `create-retrospective-document.wf.md`
- `create-review-checklist.wf.md` 
- `review-tasks-board-status.wf.md`
- `create-release-overview.wf.md` (content merged into `publish-release.wf.md`)

**Refactored Workflows (17 files):**
All remaining workflow files now follow the new self-contained structure.

### 2. Structural Requirements

**New Required Sections:**
- `## Project Context Loading` - Lists specific files to load before execution
- `## High-Level Execution Plan` - Planning and execution phases with checkboxes

**Updated Sections:**
- `## Prerequisites` - No longer references other workflows  
- `## Process Steps` - All templates and examples embedded inline
- `## Success Criteria` - Simple bullets, no external validation

**New Optional Sections:**
- `## Embedded Templates` - Complete template structures
- `## Common Patterns` - Technology-specific examples
- `## Best Practices` - DO/DON'T guidelines

### 3. Content Embedding Requirements

**Templates:** All template content must be embedded directly in workflows rather than referenced.

**Examples:** Technology-specific examples included inline:
```markdown
### Common Test Commands
- Ruby: `bundle exec rspec`
- Node.js: `npm test`  
- Python: `pytest`
- Rust: `cargo test`
```

**Format Specifications:** All format requirements embedded rather than referenced.

## Migration Steps

### Step 1: Update Workflow References

**If you reference workflows in your documentation or scripts:**

1. **Update workflow file references:**

   ```bash
   # Old reference
   load-env.wf.md
   
   # New reference  
   load-project-context.wf.md
   ```

2. **Remove references to deleted workflows:**
   - `create-retrospective-document.wf.md`
   - `create-review-checklist.wf.md`
   - `review-tasks-board-status.wf.md`
   - `create-release-overview.wf.md`

### Step 2: Adapt Custom Workflows

**If you have custom workflows based on the old pattern:**

1. **Add required sections:**

   ```markdown
   ## Project Context Loading
   * Load project objectives: `docs/what-do-we-build.md`
   * Load architecture: `docs/architecture.md`  
   * Load project structure: `docs/blueprint.md`
   * [Other relevant files for your workflow]

   ## High-Level Execution Plan
   ### Planning Phase
   * [ ] [Your planning steps]
   ### Execution Phase
   - [ ] [Your execution steps]
   ```

2. **Embed referenced content:**
   - Copy essential content from referenced guides
   - Include template structures inline
   - Add technology-specific examples

3. **Remove cross-workflow dependencies:**
   - Replace "Run X workflow first" with prerequisite conditions
   - Embed necessary instructions from other workflows

### Step 3: Update Automation Scripts

**If you have scripts that invoke workflows:**

1. **Update file paths:**

   ```bash
   # Before
   ./dev-handbook/workflow-instructions/load-env.wf.md
   
   # After  
   ./dev-handbook/workflow-instructions/load-project-context.wf.md
   ```

2. **Remove dependencies on deleted workflows:**
   - Update scripts that referenced removed workflow files
   - Consolidate functionality that was spread across multiple workflows

### Step 4: Validate Workflow Independence

**Check that your workflows are self-contained:**

1. **Verify no external references:**

   ```bash
   grep -n "\[.*\](.*/.*\.md)" your-workflow.wf.md
   ```

2. **Confirm required sections exist:**
   - `## Goal`
   - `## Prerequisites`
   - `## Project Context Loading`
   - `## Process Steps`
   - `## Success Criteria`

3. **Test independent execution:**
   - Workflow should be executable without reading other files
   - All necessary context embedded within the workflow

## New Workflow Development Standards

### Self-Containment Requirements

1. **No Cross-Workflow Dependencies**: Never require another workflow to be run first
2. **Embedded Essential Content**: Include all necessary templates, examples, and context
3. **Explicit Context Loading**: List specific files to load at the beginning
4. **Complete Process Coverage**: Everything needed from start to finish included

### Template Embedding Example

**Before (Reference-Based):**

```markdown
Use the task template from `dev-handbook/guides/draft-release/v.x.x.x/tasks/_template.md`
```

**After (Self-Contained):**

```markdown
## Embedded Templates

### Task Template
```yaml
---
id: v.X.Y.Z+task.N
status: pending
priority: medium
estimate: 2h
dependencies: []
---

# Task Title

## Implementation Plan
### Planning Steps
* [ ] Research and analyze requirements
### Execution Steps  
- [ ] Implement solution
- [ ] Add tests
- [ ] Update documentation
```

```

### Technology-Agnostic Patterns

**Include multiple technology examples:**
```markdown
### Version File Locations
- Node.js: `package.json`
- Ruby: `*.gemspec` or `lib/*/version.rb`  
- Python: `setup.py` or `pyproject.toml`
- Rust: `Cargo.toml`
```

## Common Migration Issues

### Issue 1: Missing Context Loading Section

**Problem:** Workflow lacks `## Project Context Loading` section

**Solution:** Add the standard context loading section:

```markdown
## Project Context Loading
* Load project objectives: `docs/what-do-we-build.md`
* Load architecture: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`
```

### Issue 2: External Template References

**Problem:** Workflow references external template files

**Solution:** Embed template content directly:

```markdown
## Embedded Templates

### Template Name
[Complete template content here]
```

### Issue 3: Cross-Workflow Dependencies

**Problem:** Workflow requires running another workflow first

**Solution:** Convert to prerequisite conditions:

```markdown
## Prerequisites
- Project structure exists
- Git repository initialized
- Required tools installed
```

### Issue 4: Missing Technology Examples

**Problem:** Workflow is too generic without practical guidance

**Solution:** Add embedded technology patterns:

```markdown
### Common Commands
- Ruby: `bundle exec rake test`
- Node.js: `npm run test`
- Python: `python -m pytest`
```

## Validation Checklist

Use this checklist to verify your workflows comply with the new standards:

### Required Sections

- [ ] `## Goal` - Clear objective statement
- [ ] `## Prerequisites` - No workflow dependencies  
- [ ] `## Project Context Loading` - Specific files to load
- [ ] `## Process Steps` - Detailed implementation steps
- [ ] `## Success Criteria` - Simple bullet validation points

### Self-Containment Validation

- [ ] No references to other workflow files
- [ ] All templates embedded inline
- [ ] Technology examples included where relevant
- [ ] No external guide dependencies in process steps
- [ ] Can be executed independently

### Optional Enhancements

- [ ] `## High-Level Execution Plan` with planning/execution phases
- [ ] `## Embedded Templates` section with complete structures
- [ ] `## Common Patterns` with technology-specific examples
- [ ] `## Best Practices` with DO/DON'T guidelines

## Support and Resources

### Getting Help

If you encounter issues during migration:

1. **Review the new workflow definition:** `dev-handbook/guides/.meta/workflow-instructions-definition.g.md`
2. **Check example workflows:** Any current workflow file for reference patterns
3. **Use validation tools:**
   - `bin/check-workflow-compliance` (if available)
   - `bin/check-workflow-independence` (if available)

### Example Migration

For a complete migration example, compare these files in the diff:

- **Before:** Old `breakdown-notes-into-tasks.wf.md` (with sub-workflows)
- **After:** New `breakdown-notes-into-tasks.wf.md` (unified and self-contained)

## Migration Timeline

### Immediate (Required)

- Update any scripts or documentation referencing renamed/removed workflows
- Validate that any custom workflows still function

### Short-term (Recommended)  

- Migrate custom workflows to new self-contained format
- Update any external documentation referencing old workflow patterns

### Long-term (Optional)

- Enhance workflows with optional sections (High-Level Execution Plan, Best Practices)
- Add technology-specific examples to improve usability

## Impact Assessment

### Positive Impacts

- **AI Agent Autonomy**: Workflows can be executed without human intervention for context loading
- **Reduced Brittleness**: No broken links or missing external dependencies
- **Improved Portability**: Workflows work in any environment without external file dependencies
- **Faster Execution**: No need to load multiple files to understand workflow context

### Potential Challenges

- **File Size Increase**: Workflows are longer due to embedded content
- **Content Duplication**: Some information duplicated across workflows (acceptable trade-off)
- **Migration Effort**: One-time cost to update custom workflows and documentation

### Mitigation Strategies

- **Documentation**: This migration guide provides clear steps and examples
- **Validation Tools**: Automated tools help verify compliance
- **Incremental Migration**: Can be done gradually for custom workflows
- **Fallback Patterns**: Old patterns still documented for reference during transition

---

This breaking change significantly improves the reliability and usability of workflow instructions for AI agents while maintaining all functionality. The migration effort is a one-time investment that yields long-term benefits for automation and development efficiency.
