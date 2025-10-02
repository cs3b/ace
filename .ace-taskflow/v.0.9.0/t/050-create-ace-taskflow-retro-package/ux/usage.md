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
ace-taskflow retro [<reference>]         # Shorthand for show
```

### Plural: `ace-taskflow retros`

Browse and list multiple retrospective notes:

```bash
ace-taskflow retros                      # List retros in current release
ace-taskflow retros --all                # List from all releases
ace-taskflow retros --release <version>  # List from specific release
```

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

### Scenario 2: List All Reflection Notes in Current Release

**Goal**: See what retrospective notes have been created for the current release.

**Commands**:
```bash
# List all retros in current release
ace-taskflow retros

# Output:
# Retrospective Notes (v.0.9.0):
# 2025-10-02  ace-test-runner-fixes
# 2025-10-01  task-056-commit-output-implementation
# 2025-09-30  ace-taskflow-duplicate-id-fix
# ...
```

**Expected Output**:
- Formatted list showing date and title
- Ordered by date (newest first)
- Only shows retros from current/active release

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

### Scenario 5: List All Retrospectives Across All Releases

**Goal**: Get overview of all reflection notes across the entire project history.

**Commands**:
```bash
# List all retros from all releases
ace-taskflow retros --all

# Output:
# Retrospective Notes (All Releases):
#
# v.0.9.0:
#   2025-10-02  ace-test-runner-fixes
#   2025-10-01  task-056-commit-output-implementation
#
# v.0.8.0:
#   2025-09-15  migration-learnings
# ...
```

**Expected Output**:
- Retros grouped by release
- Chronological order within each release
- Total count summary

### Scenario 6: Error Handling - No Retros Found

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

### `ace-taskflow retros [options]`

List retrospective notes with filtering.

**Options**:
- `--all`: List from all releases
- `--release <version>`: List from specific release
- `--limit <n>`: Limit number of results

**Output**:
- Formatted list of retros grouped by release
- Shows date and title for each
- Summary count

**Internal Implementation**:
- Uses `RetroManager.list_retros(context:, filters:)`
- Resolves release context
- Formats for terminal display

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

**Use Claude Command** (`/ace:create-reflection-note`):
- Automated content analysis and generation
- Session analysis and insight extraction
- Pattern recognition and synthesis
- AI-assisted reflection writing

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
