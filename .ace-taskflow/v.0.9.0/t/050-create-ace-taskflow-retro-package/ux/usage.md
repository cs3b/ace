# Retro Management Commands - Usage Guide

## Overview

The `ace-taskflow retro` and `ace-taskflow retros` commands provide CLI tools for managing retrospective reflection notes within the ace-taskflow structure. These commands follow the established singular/plural pattern (like task/tasks, idea/ideas) and are designed for file creation and browsing, NOT for automated content population.

**Key Features:**
- Create timestamped reflection note files with template structure
- List and browse reflection notes by release
- Display specific reflection content
- Maintain clear separation from Claude commands (which populate content)

**Command Types:**

1. **Bash CLI Commands** (`ace-taskflow retro/retros`):
   - File creation with template structure
   - Listing and browsing operations
   - Manual or LLM-assisted content population

2. **Claude Code Commands** (`/ace:create-reflection-note`):
   - Only callable by Claude agents
   - Automated content analysis and population
   - Workflow-driven behavior

## Command Structure

### Singular: `ace-taskflow retro`

Operations on single retrospective notes:

```bash
ace-taskflow retro create <title>        # Create new reflection note
ace-taskflow retro show <reference>      # Display specific reflection
ace-taskflow retro done <reference>      # Mark retro as done (move to done/)
ace-taskflow retro [<reference>]         # Shorthand for show
```

### Plural: `ace-taskflow retros`

Browse and list multiple retrospective notes:

```bash
ace-taskflow retros                      # List active retros in current release (excludes done/)
ace-taskflow retros --all                # Include done retros from all releases
ace-taskflow retros --done               # List only done retros
ace-taskflow retros --release <version>  # List from specific release (excludes done by default)
```

## Retro Lifecycle

Retros follow a lifecycle similar to ideas:

1. **Create** → File created in `.ace-taskflow/<release>/retro/`
2. **Populate** → Content filled by user or agent
3. **Analyze** → Insights extracted, actions created from learnings
4. **Done** → Moved to `.ace-taskflow/<release>/retro/done/`

**Directory Structure**:
```
.ace-taskflow/v.0.9.0/
└── retro/
    ├── 2025-10-02-current-sprint-learnings.md    # Active retros
    ├── 2025-10-01-api-refactor-insights.md
    └── done/                                       # Completed retros
        ├── 2025-09-30-migration-retro.md
        └── 2025-09-28-performance-analysis.md
```

**When to Mark as Done**:
- Retro content has been analyzed
- Key insights converted to tasks or actions
- Learnings documented in appropriate places
- No further action needed on this retro

## Usage Scenarios

### Scenario 1: Create a Reflection Note for Current Work

**Goal**: Capture learnings from today's development session in the current release.

**Commands**:
```bash
# Create a new reflection note
ace-taskflow retro create "ace-test-runner fixes"

# Output:
# Reflection note created: .ace-taskflow/v.0.9.0/retro/2025-10-02-ace-test-runner-fixes.md
```

**Expected Output**:
- File created: `.ace-taskflow/v.0.9.0/retro/2025-10-02-ace-test-runner-fixes.md`
- Contains template structure from workflow (What Went Well, Key Learnings, etc.)
- File is empty template ready for manual or LLM content population

**Next Steps**:
- Open file in editor to fill in content manually, OR
- Use Claude agent to analyze session and populate content

### Scenario 2: List Active Reflection Notes in Current Release

**Goal**: See what active retrospective notes exist for the current release.

**Commands**:
```bash
# List active retros in current release (excludes done/)
ace-taskflow retros

# Output:
# Active Retrospective Notes (v.0.9.0):
# 2025-10-02  ace-test-runner-fixes
# 2025-10-01  task-056-commit-output-implementation
# 2025-09-30  ace-taskflow-duplicate-id-fix
# ...
```

**Expected Output**:
- Formatted list showing date and title
- Ordered by date (newest first)
- Only shows active retros from current/active release (excludes done/ folder)
- Note: Completed retros are in done/ and not shown by default

### Scenario 3: View a Specific Reflection Note

**Goal**: Read the content of a previously created reflection note.

**Commands**:
```bash
# Show specific retro by partial name match
ace-taskflow retro show ace-test-runner

# Alternative shorthand
ace-taskflow retro ace-test-runner

# Output:
# Reflection: ace-test-runner fixes
# Date: 2025-09-30
# Context: Task to optimize ace-test-runner startup time
#
# ## What Went Well
# - Lazy loading implementation improved code organization
# ...
```

**Expected Output**:
- Full content of the reflection note
- Formatted display of all sections
- Path to file shown for easy access

### Scenario 4: Create Reflection in Specific Release

**Goal**: Create a reflection note for work done in a different release context.

**Commands**:
```bash
# Create retro in specific release (not current)
ace-taskflow retro create "migration learnings" --release v.0.8.0

# Output:
# Reflection note created: .ace-taskflow/v.0.8.0/retro/2025-10-02-migration-learnings.md
```

**Expected Output**:
- File created in specified release's retro/ directory
- Same template structure as current release
- Release context preserved in file location

### Scenario 5: Mark Retro as Done After Analysis

**Goal**: Move a retro to done/ folder after analyzing it and creating action items.

**Commands**:
```bash
# Mark retro as done (similar to ace-taskflow idea done)
ace-taskflow retro done ace-test-runner

# Output:
# Retro 'ace-test-runner-fixes' marked as done and moved to retro/done/
# Path: .ace-taskflow/v.0.9.0/retro/done/2025-10-02-ace-test-runner-fixes.md
# Completed at: 2025-10-02 15:30:00
```

**Expected Output**:
- File moved from `retro/` to `retro/done/`
- Confirmation message with new path
- Timestamp of completion

**When to Use**:
- After extracting insights and creating tasks from retro
- When learnings have been documented elsewhere
- Retro content has been fully processed

### Scenario 6: List All Retrospectives Including Done

**Goal**: Get overview of all reflection notes including completed ones.

**Commands**:
```bash
# List all retros from all releases including done
ace-taskflow retros --all

# Output:
# Retrospective Notes (All Releases):
#
# v.0.9.0:
#   Active:
#     2025-10-02  ace-test-runner-fixes
#     2025-10-01  task-056-commit-output-implementation
#   Done:
#     2025-09-30  migration-learnings
#
# v.0.8.0:
#   Done:
#     2025-09-15  initial-setup-retro
# ...
```

**Expected Output**:
- Retros grouped by release and status (Active/Done)
- Chronological order within each group
- Total count summary

### Scenario 7: List Only Done Retrospectives

**Goal**: Review completed retrospectives to see what has been actioned.

**Commands**:
```bash
# List only done retros
ace-taskflow retros --done

# Output:
# Done Retrospective Notes (v.0.9.0):
# 2025-09-30  migration-learnings
# 2025-09-28  api-refactor-insights
# ...
```

**Expected Output**:
- Only retros from retro/done/ directory
- Ordered by date
- From current release unless --all specified

### Scenario 8: Error Handling - No Retros Found

**Goal**: Understand behavior when no reflection notes exist.

**Commands**:
```bash
# Try to list retros when none exist
ace-taskflow retros

# Output:
# No retrospective notes found in current release (v.0.9.0).
# Use 'ace-taskflow retro create <title>' to create your first reflection note.
```

**Expected Output**:
- Clear message indicating empty state
- Helpful suggestion for next action
- No error exit code (normal operation)

## Command Reference

### `ace-taskflow retro create <title> [options]`

Create a new reflection note file with template structure.

**Parameters**:
- `<title>`: Descriptive title for the reflection (converted to slug for filename)

**Options**:
- `--release <version>`: Create in specific release (e.g., `v.0.8.0`)
- `--current`: Create in current/active release (default)

**Output**:
- Creates file: `.ace-taskflow/<release>/retro/YYYY-MM-DD-<title-slug>.md`
- File contains template from `tmpl://release-reflections/retro`
- Returns file path for reference

**Internal Implementation**:
- Uses `RetroManager.create_retro(title, context:)`
- Loads template from workflow file
- Resolves release context (current vs specific)
- Generates timestamped filename

### `ace-taskflow retro show <reference>`

Display the content of a specific reflection note.

**Parameters**:
- `<reference>`: Filename or partial name match (e.g., `ace-test` matches `ace-test-runner-fixes`)

**Options**:
- `--release <version>`: Search in specific release
- `--path`: Show only file path (not content)

**Output**:
- Formatted display of reflection content
- Shows all sections and metadata
- File path for easy access

**Internal Implementation**:
- Uses `RetroLoader.find_retro_by_reference(reference, context:)`
- Parses frontmatter and content
- Formats for terminal display

### `ace-taskflow retro done <reference>`

Mark a retro as done and move it to the done/ subfolder.

**Parameters**:
- `<reference>`: Filename or partial name match (e.g., `ace-test` matches `ace-test-runner-fixes`)

**Options**:
- `--release <version>`: Mark done in specific release context

**Output**:
- Confirmation message with new path
- Timestamp of completion
- File moved from `retro/` to `retro/done/`

**Internal Implementation**:
- Uses `RetroManager.mark_retro_done(reference)`
- Finds retro file in `retro/` directory
- Moves to `retro/done/` preserving filename
- Similar to `IdeaDirectoryMover.move_to_done`

**When to Use**:
- After retro content has been analyzed
- Key insights converted to tasks/actions
- Learnings documented appropriately
- No further work needed on this retro

### `ace-taskflow retros [options]`

List retrospective notes with filtering.

**Options**:
- (none): List active retros from current release (excludes done/)
- `--all`: Include done retros from all releases
- `--done`: List only done retros
- `--release <version>`: List from specific release (excludes done by default)
- `--limit <n>`: Limit number of results

**Output**:
- Formatted list of retros grouped by release and status
- Shows date and title for each
- Summary count and status indicators

**Internal Implementation**:
- Uses `RetroManager.list_retros(context:, filters:)`
- Uses `RetroLoader.list_active_retros()` for default
- Uses `RetroLoader.list_all_retros()` for --all
- Uses `RetroLoader.list_done_retros()` for --done
- Resolves release context
- Formats for terminal display

**Listing Behavior**:
- Default: Active retros only (excludes `retro/done/`)
- `--all`: Includes both `retro/` and `retro/done/`
- `--done`: Only from `retro/done/`

## Tips and Best Practices

### Naming Retro Files

**Good titles** (descriptive and specific):
- `ace-test-runner-performance-optimization`
- `task-056-commit-output-implementation`
- `migration-from-v08-to-v09-lessons`

**Avoid** (too generic):
- `reflection`
- `notes`
- `today`

### When to Use CLI vs Claude Commands

**Use CLI** (`ace-taskflow retro create`):
- Quick file creation for later population
- Scripting or automation workflows
- Manual reflection writing
- Template generation

**Use CLI** (`ace-taskflow retro done`):
- After manually reviewing and actioning retro
- When insights have been converted to tasks
- To archive processed retros

**Use Claude Command** (`/ace:create-reflection-note`):
- Automated content analysis and generation
- Session analysis and insight extraction
- Pattern recognition and synthesis
- AI-assisted reflection writing

### Managing the Retro Lifecycle

**Active Retros** (in `retro/`):
- Keep retros active while insights are still being extracted
- Active retros appear in default listings
- Use for ongoing retrospective work

**Done Retros** (in `retro/done/`):
- Move to done after creating tasks/actions from insights
- Done retros excluded from default listings (cleaner view)
- Use `--all` or `--done` to see completed retros
- Good for historical reference without cluttering active view

**Workflow Example**:
1. Create retro: `ace-taskflow retro create "sprint-23-learnings"`
2. Populate content (manually or with Claude)
3. Extract insights, create tasks from action items
4. Mark as done: `ace-taskflow retro done sprint-23-learnings`
5. Retro now in `retro/done/`, tasks are tracked separately

### File Location Strategy

Reflection notes are stored by release:
- **Current work**: `.ace-taskflow/v.0.9.0/retro/`
- **Historical work**: `.ace-taskflow/v.0.8.0/retro/`
- **Cross-release insights**: Create in most relevant release

### Content Population Workflow

1. **Create** file with CLI: `ace-taskflow retro create "topic"`
2. **Populate** content:
   - Manually: Open file and fill in sections
   - With Claude: Ask Claude to analyze session and populate
   - Mixed: Manual + Claude enhancement
3. **Review** content: `ace-taskflow retro show topic`

## Troubleshooting

### "No retros found matching..."

**Issue**: Reference doesn't match any files.

**Solutions**:
- List all retros: `ace-taskflow retros`
- Check filename spelling
- Try broader partial match
- Verify release context with `--release`

### "Release 'v.x.x.x' not found"

**Issue**: Specified release doesn't exist.

**Solutions**:
- List available releases: `ace-taskflow releases`
- Use `--current` for active release
- Check version format (v.0.9.0 not 0.9.0)

### File created but empty

**Issue**: Created file contains only template.

**Expected Behavior**: This is correct! CLI creates template, content population is separate step.

**Next Steps**:
- Open file in editor to fill manually
- Use Claude agent to populate content
- This matches task/idea pattern (create structure, populate separately)

## Migration Notes

### From Manual Retro Creation

**Old approach**:
```bash
# Manually create file
touch .ace-taskflow/v.0.9.0/retro/2025-10-02-my-reflection.md
# Manually copy template content
# Fill in manually
```

**New approach**:
```bash
# Use command to create with template
ace-taskflow retro create "my-reflection"
# Template already included, just fill in
```

**Benefits**:
- Automatic timestamp and naming
- Consistent template structure
- Release context resolution
- Validation and error handling

### From `/ace:create-reflection-note` Claude Command

**Key Difference**:
- Claude command: Analyzes context AND populates content automatically
- CLI command: Creates file with template only (manual or LLM population separate)

**When to migrate**:
- Don't migrate! Both serve different purposes
- Use CLI for file creation in scripts or manual workflows
- Use Claude command for AI-assisted content generation
