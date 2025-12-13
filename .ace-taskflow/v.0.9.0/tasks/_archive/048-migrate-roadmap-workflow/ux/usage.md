# Update Roadmap Workflow - Usage Guide

## Overview

The update-roadmap workflow provides a systematic process for maintaining project roadmaps in sync with task and release management state. It enables AI agents and developers to update roadmap documentation following the established roadmap structure defined in the Roadmap Definition Guide.

**Available Workflows:**

- `wfi://update-roadmap` - Update roadmap based on current project state

**Key Benefits:**

- Maintains roadmap consistency with actual task/release state
- Follows standardized roadmap format from roadmap-definition.g.md
- Provides validation and error checking
- Enables systematic roadmap updates through workflows

## Command Types

### Claude Code Commands (AI Agent Context)

When working within Claude Code, use slash commands with `/ace:` prefix:

```
/ace:update-roadmap
```

### Workflow Protocol (Direct Invocation)

When working with ace-nav directly:

```bash
ace-nav wfi://update-roadmap
```

**Note:** In this task, we're creating the workflow instruction document only. The `ace-taskflow roadmap` CLI read-only query is out of scope and will be implemented in a future task.

## Command Structure

### Workflow Invocation

**Basic Syntax:**

```bash
# Via ace-nav protocol
ace-nav wfi://update-roadmap

# Via Claude Code slash command (recommended)
/ace:update-roadmap
```

**No Arguments:**

- The workflow operates on the current project's `.ace-taskflow/` structure
- Automatically detects roadmap location (`.ace-taskflow/roadmap.md`)
- Uses project context to determine release state

**Default Behaviors:**

- Validates roadmap format against roadmap-definition.g.md
- Updates Planned Major Releases table from folder structure
- Synchronizes cross-release dependencies
- Adds update history entry with timestamp
- Commits changes with descriptive message

## Usage Scenarios

### Scenario 1: Update roadmap after new release is drafted

**Goal:** Add newly drafted release to roadmap's Planned Major Releases table

**Steps:**

```bash
# In Claude Code
/ace:update-roadmap

# The workflow will:
# 1. Load current roadmap from .ace-taskflow/roadmap.md
# 2. Validate format against roadmap-definition.g.md
# 3. Scan .ace-taskflow/v.X.Y.Z-*/release.md files
# 4. Detect new release not in roadmap table
# 5. Add new row to Planned Major Releases table
# 6. Update cross-release dependencies if needed
# 7. Add update history entry
# 8. Commit changes
```

**Expected Output:**

```
✓ Loaded roadmap from .ace-taskflow/roadmap.md
✓ Validated roadmap format (all sections present)
✓ Found 3 releases in .ace-taskflow/
  - v.0.9.0 (current, already in roadmap)
  - v.0.10.0 (backlog, NEW)
  - v.0.8.0 (done, excluded)
✓ Added v.0.10.0 "Spark" to Planned Major Releases
✓ Updated cross-release dependencies
✓ Added update history entry
✓ Committed: docs(roadmap): add v.0.10.0 "Spark" to planned releases

Roadmap updated successfully
```

### Scenario 2: Remove completed release from roadmap

**Goal:** Clean up roadmap after release is published and moved to done/

**Steps:**

```bash
# After running publish-release workflow
/ace:update-roadmap

# The workflow will:
# 1. Load current roadmap
# 2. Scan .ace-taskflow/ for release locations
# 3. Detect releases in done/ folder
# 4. Remove corresponding rows from roadmap table
# 5. Update dependencies referencing removed release
# 6. Add update history entry
# 7. Commit changes
```

**Expected Output:**

```
✓ Loaded roadmap from .ace-taskflow/roadmap.md
✓ Validated roadmap format
✓ Found 2 active releases, 1 completed
  - v.0.9.0 (current, in roadmap)
  - v.0.10.0 (backlog, in roadmap)
  - v.0.8.0 (done, STALE in roadmap)
✓ Removed v.0.8.0 from Planned Major Releases
✓ Updated cross-release dependencies (removed 2 references)
✓ Added update history entry
✓ Committed: docs(roadmap): remove completed v.0.8.0 from planned releases

Roadmap cleanup completed
```

### Scenario 3: Synchronize roadmap with manual changes

**Goal:** Validate and fix roadmap after manual edits

**Steps:**

```bash
# After manually editing roadmap sections
/ace:update-roadmap

# The workflow will:
# 1. Load current roadmap
# 2. Validate format (may find errors)
# 3. Report validation issues
# 4. Prompt for fixes or auto-correct if possible
# 5. Re-validate after corrections
# 6. Update history entry
# 7. Commit if changes made
```

**Expected Output (with errors):**

```
✗ Validation failed: 3 issues found

Issues:
1. Planned Major Releases table: Invalid version format "v0.9" (should be "v.0.9.0")
2. Update History: Missing last_reviewed date update in front matter
3. Cross-Release Dependencies: Reference to non-existent release "v.0.7.5"

Would you like to:
  [f] Fix automatically where possible
  [r] Review and fix manually
  [c] Cancel update

Choice: f

✓ Fixed version format to v.0.9.0
✓ Updated last_reviewed to 2025-10-02
✗ Cannot auto-fix: Cross-release dependency reference needs manual review

Please review and fix remaining issues, then re-run /ace:update-roadmap
```

### Scenario 4: Fresh roadmap creation from template

**Goal:** Initialize roadmap for new project

**Steps:**

```bash
# In new project with no roadmap
/ace:update-roadmap

# The workflow will:
# 1. Detect missing roadmap file
# 2. Offer to create from template
# 3. Create roadmap.md from template
# 4. Populate with current release data
# 5. Commit initial roadmap
```

**Expected Output:**

```
✗ Roadmap not found at .ace-taskflow/roadmap.md

Create new roadmap from template?
  [y] Yes, create from template
  [n] No, cancel

Choice: y

✓ Created roadmap from template
✓ Found 1 release in .ace-taskflow/
  - v.0.9.0 (current)
✓ Populated Planned Major Releases table
✓ Set initial metadata (status: draft, last_reviewed: 2025-10-02)
✓ Committed: docs(roadmap): initialize project roadmap

Roadmap created successfully
Next steps: Review and update Project Vision and Strategic Objectives
```

## Command Reference

### Workflow Execution

**Syntax:**

```bash
ace-nav wfi://update-roadmap
```

**What It Does:**

1. Loads roadmap from `.ace-taskflow/roadmap.md`
2. Validates format against roadmap-definition.g.md specification
3. Analyzes release state from `.ace-taskflow/` folder structure
4. Updates Planned Major Releases table (add/remove rows)
5. Synchronizes cross-release dependencies
6. Updates front matter `last_reviewed` date
7. Adds entry to Update History table
8. Validates updated roadmap structure
9. Commits changes with descriptive message

**Input Sources:**

- `.ace-taskflow/roadmap.md` (current roadmap)
- `.ace-taskflow/v.*/release.md` (release metadata)
- `.ace-taskflow/` folder structure (release locations)
- `dev-handbook/guides/roadmap-definition.g.md` (validation rules)
- `dev-handbook/templates/project-docs/roadmap/roadmap.template.md` (template)

**Output:**

- Updated `.ace-taskflow/roadmap.md`
- Git commit with changes

**Internal Implementation:**

- Workflow instructions in `ace-taskflow/handbook/workflow-instructions/update-roadmap.wf.md`
- Uses Read, Write, Edit, Grep tools
- Follows self-contained workflow principle (ADR-001)

### Error Handling

**Common Errors:**

**1. Roadmap Format Validation Failed**

```
Error: Roadmap validation failed
  - Missing section: "Strategic Objectives"
  - Invalid table format in section 4

Fix: Review dev-handbook/guides/roadmap-definition.g.md for required format
```

**2. Roadmap File Not Found**

```
Error: Roadmap not found at .ace-taskflow/roadmap.md

Options:
  - Create from template (workflow will prompt)
  - Specify custom location (not yet supported)
```

**3. Release Folder Inconsistency**

```
Warning: Release v.0.9.0 in roadmap table but not found in .ace-taskflow/

Action: Workflow will prompt to remove stale entry or update folder structure
```

**4. Git Commit Failed**

```
Error: Failed to commit roadmap changes
  - Uncommitted changes in working directory
  - Git conflict detected

Fix: Resolve git issues manually, then re-run workflow
```

## Tips and Best Practices

### When to Update Roadmap

**Regular Update Triggers:**

- After drafting a new release (draft-release workflow)
- After publishing a release (publish-release workflow)
- When release targets change significantly
- Quarterly roadmap review cycles

**Avoid Frequent Updates For:**

- Individual task status changes (roadmap is high-level)
- Minor release metadata edits
- Documentation-only changes

### Roadmap Maintenance

**Best Practices:**

1. **Let Workflows Handle It**: Use `/update-roadmap` instead of manual edits
2. **Validate Before Committing**: Workflow validates automatically
3. **Keep Vision Stable**: Don't change vision section frequently
4. **Update Metrics Quarterly**: Review strategic objectives every 3 months
5. **Document Dependencies**: Call out blocking dependencies explicitly

**Common Pitfalls:**

- ❌ Editing roadmap manually without validation
- ❌ Including too many planned releases (>4-5 is too many)
- ❌ Forgetting to remove completed releases
- ❌ Circular dependencies between releases
- ❌ Stale target dates (update when reality changes)

### Integration with Other Workflows

**Draft Release → Update Roadmap:**

```bash
# After creating new release
/ace:draft-release v.0.10.0 "Spark"
# ... release scaffolding created ...

# Update roadmap to include new release
/ace:update-roadmap
```

**Publish Release → Update Roadmap:**

```bash
# After publishing release
/ace:publish-release v.0.9.0
# ... release moved to done/ ...

# Clean up roadmap
/ace:update-roadmap
```

**Roadmap Review Cycle:**

```bash
# Quarterly review process
1. Review strategic objectives and vision
2. Update release targets based on progress
3. Run /ace:update-roadmap to sync with current state
4. Commit reviewed roadmap
```

## Troubleshooting

### Workflow Doesn't Find Roadmap

**Problem:** Workflow reports roadmap not found

**Solutions:**

1. Check roadmap location: `.ace-taskflow/roadmap.md` (not root `ROADMAP.md`)
2. Create from template using workflow prompt
3. Move existing roadmap to correct location

### Validation Keeps Failing

**Problem:** Roadmap format validation errors persist

**Solutions:**

1. Compare against template: `dev-handbook/templates/project-docs/roadmap/roadmap.template.md`
2. Review guide: `dev-handbook/guides/roadmap-definition.g.md`
3. Check table column headers match exactly
4. Verify YAML front matter format
5. Ensure all 6 required sections present

### Releases Not Syncing

**Problem:** Releases in folder structure don't appear in roadmap

**Solutions:**

1. Verify release.md files exist in release directories
2. Check release.md has valid metadata (version, codename)
3. Ensure releases are in active locations (v.*/not done/)
4. Re-run workflow with --debug flag (future feature)

### Git Conflicts on Commit

**Problem:** Workflow fails to commit due to conflicts

**Solutions:**

1. Ensure working directory is clean before running
2. Pull latest changes: `git pull origin main`
3. Resolve conflicts manually if they exist
4. Re-run `/ace:update-roadmap` after conflict resolution

## Migration Notes

### Legacy Update-Roadmap Command

**Before (dev-handbook):**

```
# Legacy command reference (not yet implemented)
@dev-handbook/workflow-instructions/update-roadmap.wf.md
```

**After (ace-taskflow):**

```
# New workflow location
ace-nav wfi://update-roadmap

# Future CLI command (out of scope for this task)
ace-taskflow roadmap update
```

**Key Differences:**

- **Location**: Moved from dev-handbook to ace-taskflow
- **Discovery**: Uses ace-nav wfi:// protocol
- **Self-Contained**: Embeds templates per ADR-002
- **Validation**: References roadmap-definition.g.md

### Breaking Changes

**None** - This is a new workflow. No existing update-roadmap workflow exists to migrate from.

### Future Enhancements

Planned for future tasks (out of scope for task 048):

- `ace-taskflow roadmap` CLI read-only query (lists planned releases)
- `ace-taskflow roadmap --limit N` display first N releases
- `ace-taskflow roadmap --format [table|json]` output formatting
- LLM-assisted roadmap content generation (via workflow enhancements)
- Automatic roadmap validation checks in CI/CD
- Release timeline visualization

**Note:** Roadmap updates remain agent-driven via `/ace:update-roadmap` workflow. No CLI update commands (separation of concerns: CLI for reading, workflows for writing).

## Review Criteria

When creating the update-roadmap workflow, ensure:

- [ ] Examples use actual workflow syntax (ace-nav wfi://)
- [ ] Scenarios cover common and edge cases
- [ ] Command types clearly distinguished (workflow vs future CLI)
- [ ] Output examples realistic and helpful
- [ ] Troubleshooting addresses likely issues
- [ ] Migration path clear (noting no legacy workflow exists)
- [ ] Error messages match actual workflow outputs
- [ ] Integration with draft-release and publish-release workflows documented
- [ ] References to roadmap-definition.g.md for validation rules
- [ ] Self-containment principle (ADR-001) compliance noted
