---
doc-type: workflow
title: Search Workflow
purpose: search workflow instruction
ace-docs:
  last-updated: 2026-03-06
  last-checked: 2026-03-21
---

# Search Workflow

## Purpose

Intelligent code and file discovery using the **ace-search** gem - finding files by name, searching for code patterns, and exploring project structure.

## Primary Tool: ace-search

You use the **ace-search** command exclusively for all search operations. This unified tool combines file and content searching with intelligent DWIM (Do What I Mean) pattern analysis.

## Search Modes

### Auto Mode (Default - DWIM)
Let ace-search intelligently detect search type:
```bash
# File glob patterns auto-detected
ace-search "*.rb"
ace-search "test_*.md"

# Content searches auto-detected
ace-search "class TaskManager"
ace-search "def initialize"

# Hybrid searches
ace-search "bin/as-search"
ace-search "TODO"
```

### Explicit Modes

**File Search** - Find files by name/pattern:
```bash
ace-search "agent" --file
ace-search "*.md" --file
ace-search "*Manager*" --file
```

**Content Search** - Search within files:
```bash
ace-search "require 'ace/core'" --content
ace-search "TODO|FIXME" --content
ace-search "class.*Agent" --content
```

**Hybrid Mode** - Search both:
```bash
ace-search "TaskManager" --hybrid
ace-search "config" --hybrid
```

## Scope Control

### Search Scope
Limit search to specific paths:
```bash
# Search specific directory (change directory first)
cd lib/ && ace-search "pattern"
cd ace-task/ && ace-search "TODO"

# Or use --include to filter paths
ace-search "pattern" --include "lib/**/*"
ace-search "TODO" --include "ace-task/**/*"
```

### File Pattern Filtering (Glob)
Filter by file patterns:
```bash
# Search only Ruby files
ace-search "class" --content --glob "**/*.rb"

# Search only markdown in specific paths
ace-search "TODO" --content --glob "docs/**/*.md"

# Multiple patterns
ace-search "config" --glob "**/*.{yml,yaml,json}"
```

### Git Scope
Limit to git-tracked files:
```bash
# Staged files only
ace-search "console.log" --staged

# Tracked files only
ace-search "TODO" --tracked

# Changed files only
ace-search "FIXME" --changed
```

## Search Modifiers

### Pattern Matching
```bash
# Case-insensitive
ace-search "todo" --case-insensitive

# Whole word matching
ace-search "test" --whole-word

# Multiline patterns
ace-search "class.*end" --multiline
```

### Context Display
Show surrounding lines:
```bash
# 3 lines before and after
ace-search "error" --context 3

# 2 lines after
ace-search "warning" --after-context 2

# 2 lines before
ace-search "exception" --before-context 2
```

### Output Control
```bash
# Limit results
ace-search "TODO" --max-results 20

# Show only filenames
ace-search "deprecated" --files-with-matches

# Output formats
ace-search "class" --format json
ace-search "def" --format yaml
```

## Preset Support

Use predefined search configurations:
```bash
# Use preset from .ace/search/presets/
ace-search --preset ruby-classes

# List available presets
ace-search --list-presets
```

## Common Workflows

### Finding Implementation
```bash
# 1. Broad discovery
ace-search "TaskManager"

# 2. Narrow by file type
ace-search "TaskManager" --glob "**/*.rb"

# 3. Find class definition
ace-search "class TaskManager" --content --glob "**/*.rb"

# 4. Find usage
ace-search "TaskManager.new" --content
```

### Searching Configuration
```bash
# Find YAML config files
ace-search "*.yml" --file --search-root .ace

# Search within config
ace-search "model: opus" --content --glob "**/*.yml"

# Find environment variables
ace-search "API_KEY" --content
```

### Exploring Code Structure
```bash
# Find all requires
ace-search "require 'ace" --content --glob "**/*.rb"

# Find class definitions
ace-search "class.*< " --content --glob "**/*.rb"

# Find method definitions (in lib/ directory)
cd lib/ && ace-search "def " --content
```

### Debugging and Maintenance
```bash
# Find TODOs and FIXMEs
ace-search "TODO|FIXME" --content

# Find deprecated code
ace-search "deprecated" --case-insensitive --content

# Find error handling
ace-search "rescue|raise" --content --glob "**/*.rb"
```

## Search Strategy

### Progressive Refinement
1. **Start broad**: Use auto mode to understand scope
   ```bash
   ace-search "notification"
   ```

2. **Identify patterns**: Look at results to understand structure
   ```bash
   ace-search "notification" --files-with-matches
   ```

3. **Narrow focus**: Add filters based on findings
   ```bash
   ace-search "class.*Notification" --content --glob "**/*.rb" --include "lib/**/*"
   ```

4. **Verify relevance**: Check sample results
   ```bash
   ace-search "Notification.new" --content --max-results 5
   ```

### Efficiency Tips
- Use `--file` for filename-only searches (faster)
- Change directories or use `--include` to limit scope
- Use `--glob` to filter file types
- Apply `--max-results` for initial exploration
- Leverage auto mode for intelligent detection

## Response Format

### Success Response
```markdown
## Search Summary
Found [N] matches for "[pattern]" across [M] files.

## Key Results
- path/to/file.rb:42: [relevant match with context]
- another/file.md:15: [relevant match with context]

## Patterns Observed
- [Common themes or structures]
- [Notable file/directory concentrations]

## Suggestions
- Refine with: ace-search "[pattern]" --glob "**/*.ext" --include "path/**/*"
- Explore: [specific files or directories of interest]
```

### No Results Response
```markdown
## Search Summary
No matches found for "[pattern]".

## Suggestions
- Try alternative terms or patterns
- Broaden scope: --search-root .
- Use case-insensitive: --case-insensitive
- Check different file types: --glob "**/*.ext"
```

### Large Result Set Response
```markdown
## Search Summary
Found [N] matches (showing first [M] due to limit).

## Top Results
[Most relevant matches]

## Refinement Suggestions
To narrow results, try:
- ace-search "[pattern]" --glob "**/*.rb"
- cd specific/path/ && ace-search "[pattern]"
- ace-search "[pattern]" --whole-word
- ace-search "[pattern]" --include "specific/path/**/*"
```

## Important Notes

- **Discovery Only**: This workflow searches but does not modify files
- **DWIM Mode**: Auto mode intelligently detects file vs content searches
- **Git Integration**: Supports scoping to staged/tracked/changed files
- **Preset Support**: Can use predefined search configurations
- **Performance**: Use specific modes and filters for faster searches
- **Results Limit**: Default max-results prevents overwhelming output