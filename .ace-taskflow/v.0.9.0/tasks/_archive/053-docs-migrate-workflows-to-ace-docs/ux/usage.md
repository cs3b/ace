# ace-docs Documentation Generation Workflows - Usage Guide

## Overview

This task migrates 5 documentation generation workflows from **dev-handbook** (legacy) to **ace-docs/handbook** (proper architectural home). After migration, all documentation workflows will be consolidated in the ace-docs gem and accessible via the `wfi://` protocol.

## Available Workflows (After Migration)

### API Documentation
- **`wfi://create-api-docs`** - Generate API reference documentation from code structure
  - Analyzes code interfaces, docstrings, and type definitions
  - Creates structured API reference documentation
  - Maintains format consistency

### User Documentation
- **`wfi://create-user-docs`** - Create user-facing guides and tutorials
  - Analyzes user-facing features
  - Generates usage examples and getting-started guides
  - Documents configuration and setup

### Blueprint Documentation
- **`wfi://update-blueprint`** - Maintain architectural documentation
  - Analyzes project structure and patterns
  - Updates architectural decision records
  - Tracks system design changes

### Context Documentation
- **`wfi://update-context-docs`** - Update project context files
  - Maintains CONTEXT.md or project overview
  - Updates component relationships
  - Documents conventions and guidelines

### Cookbook Documentation
- **`wfi://create-cookbook`** - Generate practical how-to guides
  - Creates task-oriented documentation
  - Documents workflows and patterns
  - Provides code examples and recipes

### Already in ace-docs
- **`wfi://create-adr`** - Create Architecture Decision Records
- **`wfi://maintain-adrs`** - Maintain ADR lifecycle
- **`wfi://update-docs`** - Update documentation frontmatter

## Key Benefits

- **Consolidated Location**: All documentation workflows in one gem (ace-docs)
- **Protocol Access**: Use `wfi://workflow-name` for portable references
- **Auto-Discovery**: ace-nav automatically finds workflows when ace-docs is installed
- **Self-Contained**: Workflows include embedded templates and complete instructions
- **Backward Compatible**: Original dev-handbook workflows remain during transition

## Migration Impact

### Before Migration

```bash
# Workflows scattered across dev-handbook
ace-nav wfi://create-api-docs
# → dev-handbook/workflow-instructions/create-api-docs.wf.md (@dev-handbook)

ace-nav wfi://create-adr
# → ace-docs/handbook/workflow-instructions/create-adr.wf.md (@ace-docs)
```

### After Migration

```bash
# All documentation workflows in ace-docs
ace-nav wfi://create-api-docs
# → ace-docs/handbook/workflow-instructions/create-api-docs.wf.md (@ace-docs)

ace-nav wfi://create-adr
# → ace-docs/handbook/workflow-instructions/create-adr.wf.md (@ace-docs)

# List all ace-docs workflows
ace-nav 'wfi://*' --list | grep "@ace-docs"
# Shows 8 workflows total (3 existing + 5 migrated)
```

## Usage Scenarios

### Scenario 1: Generating API Documentation for New Features

**Goal**: Create API documentation for newly added classes and methods

**Before Migration** (current state):
```bash
# Load workflow from dev-handbook
ace-nav wfi://create-api-docs
```

**After Migration**:
```bash
# Load workflow from ace-docs (same command, different source)
ace-nav wfi://create-api-docs
```

**Expected Output**: Complete workflow with steps to:
1. Identify target code requiring documentation
2. Analyze code structure and interfaces
3. Write documentation comments
4. Generate and review documentation output
5. Commit documentation updates

**No User Impact**: The workflow invocation remains identical; only the source location changes from dev-handbook to ace-docs.

### Scenario 2: Creating User-Facing Guides

**Goal**: Write a getting-started guide for new users

**Commands**:
```bash
# Load user documentation workflow
ace-nav wfi://create-user-docs
```

**Expected Output**: Workflow instructions including:
- User research and audience identification
- Content structure planning
- Writing guidelines and examples
- Format validation and review
- Publishing steps

**Migration Benefit**: Workflow now lives alongside other doc workflows (create-adr, update-docs) in ace-docs for logical organization.

### Scenario 3: Updating Architectural Documentation

**Goal**: Update BLUEPRINT.md after major refactoring

**Commands**:
```bash
# Load blueprint update workflow
ace-nav wfi://update-blueprint
```

**Expected Output**: Complete process for:
- Analyzing current project structure
- Identifying architectural changes
- Updating blueprint documentation
- Validating consistency with ADRs
- Committing updates

**Path Reference Update**: Workflow previously referenced `dev-handbook/workflow-instructions/load-project-context.wf.md` → now uses `ace-nav wfi://load-context` protocol reference.

### Scenario 4: Maintaining Project Context Documentation

**Goal**: Update CONTEXT.md with new components and relationships

**Commands**:
```bash
# Load context documentation workflow
ace-nav wfi://update-context-docs
```

**Expected Output**: Instructions for:
- Reviewing current project context
- Identifying new/changed components
- Updating context documentation
- Validating completeness
- Committing changes

**Note**: This workflow may need template embedding verification during migration.

### Scenario 5: Creating Cookbook Entries

**Goal**: Document a common development workflow as a cookbook recipe

**Commands**:
```bash
# Load cookbook creation workflow
ace-nav wfi://create-cookbook
```

**Expected Output**: Step-by-step guide for:
- Identifying cookbook topic
- Structuring practical examples
- Writing code samples
- Testing examples
- Publishing cookbook entry

### Scenario 6: Verifying Migration Success

**Goal**: Confirm all workflows migrated correctly and are discoverable

**Commands**:
```bash
# Check ace-docs is registered as workflow source
ace-nav --sources | grep ace-docs

# Verify all 8 workflows discovered from ace-docs
ace-nav 'wfi://*' --list | grep "@ace-docs" | wc -l
# Expected: 8 (3 existing + 5 newly migrated)

# Test specific workflow loads correctly
ace-nav wfi://create-api-docs | head -20

# Verify protocol references work
ace-nav wfi://load-context | head -10
```

**Expected Results**:
- ace-docs appears in sources list
- All 8 workflows show @ace-docs source
- Individual workflows load without errors
- Protocol references resolve correctly

## Command Reference

### Workflow Access

**General syntax**:
```bash
# Load workflow via protocol
ace-nav wfi://workflow-name

# List all workflows
ace-nav 'wfi://*' --list

# List only ace-docs workflows
ace-nav 'wfi://*' --list | grep "@ace-docs"

# Check workflow sources
ace-nav --sources
```

### Migration Validation Commands

**Verify workflows copied**:
```bash
# Count workflows in ace-docs (should be 8 after migration)
ls -1 ace-docs/handbook/workflow-instructions/*.wf.md | wc -l
```

**Check for path reference updates**:
```bash
# Should return 0 results after migration
ace-search "dev-handbook/workflow-instructions" --content \
  --glob "ace-docs/handbook/workflow-instructions/*.wf.md"
```

**Verify template embedding**:
```bash
# Each workflow should have <documents> section
for f in ace-docs/handbook/workflow-instructions/{create-api-docs,create-user-docs,update-blueprint,update-context-docs,create-cookbook}.wf.md; do
  echo "$f:"
  grep -c "<documents>" "$f" || echo "  MISSING"
done
```

**Test workflow discovery**:
```bash
# Should show 5 migrated workflows with @ace-docs source
ace-nav 'wfi://*' --list | grep -E "(create-api-docs|create-user-docs|update-blueprint|update-context-docs|create-cookbook)" | grep "@ace-docs"
```

## Claude Code Integration

### Slash Commands

Workflows can be invoked via Claude Code slash commands:

```
/ace:load-context wfi://create-api-docs
```

Or directly in conversation:
```
Load and follow: `ace-nav wfi://create-api-docs`
```

### Migration Impact on Slash Commands

**No Changes Required**:
- Existing slash commands using `wfi://` protocol continue working
- ace-nav automatically resolves to new location (@ace-docs)
- Priority system ensures smooth transition (project > gem)

**If slash commands use file paths** (.claude/commands/*.md):
- Update file path references to use `wfi://` protocol
- Example: Change `dev-handbook/workflow-instructions/create-api-docs.wf.md` to `ace-nav wfi://create-api-docs`

## Tips and Best Practices

### For AI Agents

1. **Use Protocol References**: Always use `wfi://workflow-name` instead of file paths
2. **Load Complete Workflow**: Don't guess steps - load full workflow with ace-nav
3. **Follow Planning First**: Workflows separate planning (*) from execution (-) steps
4. **Verify Prerequisites**: Check workflow prerequisites before executing
5. **Test Embedded Commands**: Use TEST blocks in workflows to validate results

### For Developers

1. **Consolidation Benefit**: All doc workflows now in one place (ace-docs)
2. **Discovery Check**: Verify workflows appear in `ace-nav --sources` after install
3. **Path Independence**: Use protocol URLs for portability across environments
4. **Backward Compatibility**: Original dev-handbook workflows remain during transition
5. **Update References**: Replace hardcoded paths with protocol references in custom workflows

### Common Pitfalls

❌ **Don't**: Reference workflows by file path in documentation
✅ **Do**: Use `wfi://create-api-docs` protocol URL

❌ **Don't**: Assume workflows have moved during transition period
✅ **Do**: Check `ace-nav 'wfi://workflow-name' --list` to see current source

❌ **Don't**: Skip template embedding verification
✅ **Do**: Verify all workflows have `<documents>` sections

❌ **Don't**: Modify workflows in gem installation directly
✅ **Do**: Create local overrides in `.ace/handbook/workflow-instructions/` if needed

## Troubleshooting

### Workflow Not Found After Migration

**Problem**: `ace-nav wfi://create-api-docs` returns "not found" or shows dev-handbook source

**Diagnosis**:
```bash
# Check if workflows were copied to ace-docs
ls -la ace-docs/handbook/workflow-instructions/create-api-docs.wf.md

# Check ace-nav discovery
ace-nav --sources | grep ace-docs

# Check workflow source
ace-nav 'wfi://create-api-docs' --list
```

**Solutions**:
1. Verify workflows copied to ace-docs/handbook/workflow-instructions/
2. Check ace-docs gem is properly installed
3. Verify handbook/ directory exists in ace-docs
4. Restart shell if using local development setup

### Broken Protocol References

**Problem**: Workflow references `wfi://load-context` but it doesn't resolve

**Diagnosis**:
```bash
# Test protocol reference directly
ace-nav wfi://load-context

# Check ace-context gem provides this workflow
ace-nav 'wfi://*' --list | grep load-context
```

**Solutions**:
1. Verify ace-context gem is installed: `gem list | grep ace-context`
2. Check workflow name is correct (load-context vs load-project-context)
3. Ensure ace-context has handbook/workflow-instructions/load-context.wf.md
4. Try restarting shell to reload gem paths

### Template Embedding Errors

**Problem**: Workflow missing embedded templates (ADR-002 violation)

**Diagnosis**:
```bash
# Check for <documents> sections in workflows
ace-search "<documents>" --content \
  --glob "ace-docs/handbook/workflow-instructions/{create-api-docs,create-user-docs,update-blueprint,update-context-docs,create-cookbook}.wf.md"

# Specifically check update-context-docs (flagged in planning)
grep -c "<documents>" ace-docs/handbook/workflow-instructions/update-context-docs.wf.md
```

**Solutions**:
1. If templates missing, check source workflow in dev-handbook
2. Look for external template files in dev-handbook/templates/
3. Embed templates in `<documents>` section per ADR-002
4. Report issue if migration included workflows without proper embedding

### Discovery Shows Duplicates

**Problem**: Same workflow appears from both @dev-handbook and @ace-docs

**Diagnosis**:
```bash
# Check all sources for workflow
ace-nav 'wfi://create-api-docs' --list

# Should show both during transition:
# wfi://create-api-docs → .../ace-docs/... (@ace-docs)
# wfi://create-api-docs → .../dev-handbook/... (@dev-handbook)
```

**Expected Behavior**:
- During transition, both sources exist
- ace-nav uses priority system (gem priority 100+, project priority 10)
- Project @local overrides take precedence if present
- This is intentional for smooth migration

**Solutions**:
- No action needed - this is expected during transition
- After validation, original dev-handbook workflows will be removed
- If you want ace-docs version immediately, can temporarily move dev-handbook workflows

## Migration Notes

### Timeline

1. **Planning Phase** (this task): Create implementation plan
2. **Migration Phase**: Copy workflows, update references, validate
3. **Validation Phase**: Test discovery, execution, protocol references
4. **Cleanup Phase** (future task): Remove original dev-handbook workflows

### File Changes Summary

**Added** (5 files):
- ace-docs/handbook/workflow-instructions/create-api-docs.wf.md
- ace-docs/handbook/workflow-instructions/create-user-docs.wf.md
- ace-docs/handbook/workflow-instructions/update-blueprint.wf.md
- ace-docs/handbook/workflow-instructions/update-context-docs.wf.md
- ace-docs/handbook/workflow-instructions/create-cookbook.wf.md

**Modified** (optional):
- ace-docs/README.md (add workflow documentation)

**Kept for Compatibility**:
- dev-handbook/workflow-instructions/*.wf.md (all original files remain)

### Reference Updates

**Pattern Applied to All 5 Workflows**:

```markdown
# Before
## Project Context Loading
- Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`

# After
## Project Context Loading
- Read and follow: `ace-nav wfi://load-context`
```

**Why This Change**:
- Removes hardcoded file path dependency
- Uses protocol for portable, location-independent references
- Follows ADR-001 self-containment principle
- Works regardless of where workflows are installed

## Internal Implementation Notes

### ace-nav Discovery

Workflows auto-discovered via:

1. **Gem Scanner** (`Ace::Nav::Molecules::HandbookScanner#scan_gem_sources`):
   - Finds ace-docs gem in RubyGems
   - Checks for `handbook/` directory
   - Creates @ace-docs source entry

2. **Directory Structure**:
   ```
   ace-docs/
   └── handbook/
       └── workflow-instructions/
           ├── create-adr.wf.md          # Existing
           ├── maintain-adrs.wf.md        # Existing
           ├── update-docs.wf.md          # Existing
           ├── create-api-docs.wf.md      # Migrated
           ├── create-user-docs.wf.md     # Migrated
           ├── update-blueprint.wf.md     # Migrated
           ├── update-context-docs.wf.md  # Migrated
           └── create-cookbook.wf.md      # Migrated
   ```

3. **Protocol Resolution**:
   - `wfi://` maps to `workflow-instructions/` directory
   - `.wf.md` extension added automatically
   - Returns full path when workflow requested

### Priority System

ace-nav priority (lower number = higher precedence):
- Project `.ace/` (10)
- User `~/.ace` (20)
- Gems (100+)
- Custom (200)

During migration:
- Both @dev-handbook (gem, priority 100+) and @ace-docs (gem, priority 100+) exist
- Later in list typically gets higher priority number
- After dev-handbook cleanup, only @ace-docs remains

### No Code Changes

Migration involves **zero code changes**:
- No Ruby code modifications to ace-docs gem
- No new dependencies
- No CLI command additions
- Pure workflow file relocation and reference updates

## Further Reading

- **ADR-001**: Workflow Self-Containment Principle - Why workflows should be self-contained
- **ADR-002**: XML Template Embedding - How templates must be embedded in workflows
- **ADR-016**: Handbook Directory Architecture - Standard structure for handbook/ directories
- **ace-nav Documentation**: Complete guide to wfi:// protocol and workflow discovery
- **Task 052**: ace-handbook gem creation (handbook MANAGEMENT workflows vs. doc GENERATION workflows)
