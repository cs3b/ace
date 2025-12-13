# ace-search Usage Guide

## Document Type: How-To Guide + Reference

## Overview

Unified search tool for codebases, providing intelligent pattern matching across files and content.

**Key Features:**

- File and content search with ripgrep/fd backends
- Improved file search matching full paths and names
- Smart DWIM (Do What I Mean) heuristics for search mode selection
- Preset support with separate configuration files
- Interactive selection with fzf
- Git-aware searching (staged, tracked, changed files)
- Comprehensive configuration defaults for all CLI flags

## Installation

```bash
# Install as gem (once published)
gem install ace-search

# Or add to Gemfile
gem 'ace-search', '~> 0.9.0'

# Verify installation
ace-search --version
```

## Quick Start (5 minutes)

Get started with the most basic usage:

```bash
# Search for content in files
ace-search "TODO"

# Expected output:
Search context: mode: content | pattern: "TODO"
Found 12 results

  ./lib/ace/search/organisms/unified_searcher.rb:45:0: # TODO: Implement caching
  ./test/test_helper.rb:8:0: # TODO: Add test fixtures
  ./README.md:92:0: - TODO: Complete documentation
```

**Success criteria:** Results shown with file paths and line numbers

## Command Interface

### Basic Usage

```bash
# Default content search
ace-search "pattern"

# File search
ace-search --files "*.rb"

# Content search (explicit)
ace-search --content "function"
```

### Command Options

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| `--type TYPE` | `-t` | Search type (file/content/hybrid/auto) | `ace-search -t file "*.test.rb"` |
| `--files` | `-f` | Search file paths and names | `ace-search -f "controller"` (matches `app/controllers/user_controller.rb`) |
| `--content` | `-c` | Search in file content only | `ace-search -c "def initialize"` |
| `--case-insensitive` | `-i` | Case insensitive search | `ace-search -i "TODO"` |
| `--whole-word` | `-w` | Match whole words only | `ace-search -w "test"` |
| `--multiline` | `-U` | Enable multiline matching | `ace-search -U "class.*end"` |
| `--context NUM` | `-C` | Show NUM lines of context | `ace-search -C 3 "error"` |
| `--glob PATTERN` | `-g` | File glob pattern to include | `ace-search -g "*.rb" "TODO"` |
| `--exclude PATHS` | `-e` | Exclude paths/globs | `ace-search -e "vendor,tmp" "pattern"` |
| `--staged` | | Search staged files only | `ace-search --staged "fix"` |
| `--json` | | Output in JSON format | `ace-search --json "pattern"` |
| `--fzf` | | Use fzf for interactive selection | `ace-search --fzf "test"` |
| `--preset NAME` | `-p` | Use search preset | `ace-search -p code "TODO"` |
| `--max-results NUM` | | Limit number of results | `ace-search --max-results 50 "pattern"` |

## Common Scenarios

### Scenario 1: Find all TODOs in Ruby files

**Goal**: Locate all TODO comments in Ruby source files

**Commands**:

```bash
# Using glob filter
ace-search --glob "*.rb" "TODO"

# Or using preset (if configured)
ace-search --preset ruby "TODO"
```

**Expected Output**:

```
Search context: mode: content | pattern: "TODO" | filters: [glob: *.rb]
Found 8 results

  ./lib/ace/search/atoms/ripgrep_executor.rb:23:0: # TODO: Add timeout handling
  ./lib/ace/search/molecules/preset_manager.rb:45:0: # TODO: Validate preset format
  ./test/test_helper.rb:8:0: # TODO: Add test fixtures
```

**Next Steps**: Click on file:line in terminal to open in editor

### Scenario 2: Search file paths with improved matching

**Goal**: Find files using path-aware matching

**Commands**:

```bash
# Find all controller files (matches paths)
ace-search --files "controller"

# Find specific test files
ace-search --files "user.*test"
```

**Expected Output**:

```
Search context: mode: files | pattern: "controller"
Found 5 results

  ./app/controllers/application_controller.rb
  ./app/controllers/users_controller.rb
  ./app/controllers/api/v1/base_controller.rb
  ./test/controllers/users_controller_test.rb
  ./spec/controllers/api_controller_spec.rb
```

### Scenario 3: Interactive file selection with fzf

**Goal**: Search and interactively select files to process

**Commands**:

```bash
# Find test files interactively
ace-search --files "*_test.rb" --fzf

# Search content and select results
ace-search "describe" --fzf
```

**Expected Output**:

```
# FZF interactive window opens
> test/atoms/ripgrep_executor_test.rb
  test/molecules/preset_manager_test.rb
  test/organisms/unified_searcher_test.rb
  3/15

# After selection:
Selected:
  test/atoms/ripgrep_executor_test.rb
  test/organisms/unified_searcher_test.rb
```

### Scenario 4: Git-aware searching

**Goal**: Search only in files that have been modified

**Commands**:

```bash
# Search in staged files
ace-search --staged "console.log"

# Search in changed files
ace-search --changed "TODO"

# Search only tracked files
ace-search --tracked "deprecated"
```

**Expected Output**:

```
Search context: mode: content | pattern: "console.log" | filters: [scope: staged]
Found 2 results

  ./lib/debug_helper.rb:12:0: console.log("Debug:", data)
  ./test/test_helper.rb:45:0: console.log("Test started")
```

## Configuration

### Project Configuration

Create `.ace/search/config.yml`:

```yaml
ace:
  search:
    # Any CLI flag can be a default (use underscore for dashes)
    case_insensitive: true      # Always case-insensitive
    max_results: 100            # Limit results by default
    exclude:                    # Default exclusions
      - "vendor/**/*"
      - "tmp/**/*"
      - "coverage/**/*"
      - "node_modules/**/*"
    context: 2                  # Show 2 lines of context
    hidden: false               # Don't search hidden files by default
    whole_word: false           # Partial matches by default
    files_with_matches: false   # Show full results by default

    # File search specific
    type: auto                  # Auto-detect search type
```

### Preset Configuration

Create presets as separate files in `.ace/search/presets/`:

```yaml
# .ace/search/presets/ruby.yml
name: ruby
description: Search Ruby files only
glob: "*.rb"
exclude:
  - "vendor/**/*"
  - "tmp/**/*"
case_insensitive: false  # Override default for Ruby

# .ace/search/presets/tests.yml
name: tests
description: Search test files
glob: "*_{test,spec}.rb"
type: file
max_results: 50

# .ace/search/presets/docs.yml
name: docs
description: Documentation search
glob: "*.{md,txt,rdoc}"
type: content
case_insensitive: true
```

### Global Configuration

Place in `~/.ace/search/config.yml` for user-wide defaults.

### Configuration Cascade

Settings are applied in order (later overrides earlier):
1. Built-in defaults
2. Global config (`~/.ace/search/config.yml`)
3. Project config (`./.ace/search/config.yml`)
4. Preset (if specified with `--preset`)
5. Command-line flags

## Complete Command Reference

### Main Commands

#### `ace-search [pattern]`

Searches for pattern in the codebase using intelligent mode detection.

**Parameters:**

- `pattern`: Regular expression or string to search for

**Options:**

- `--type MODE`: Force specific search mode (file/content/hybrid/auto)
- `--case-insensitive`: Ignore case in pattern matching
- `--whole-word`: Match complete words only
- `--multiline`: Allow pattern to span multiple lines

**Examples:**

```bash
# Simple content search
ace-search "initialize"
# Output: Found 23 results in 15 files

# Case-insensitive file search
ace-search -i -f "readme"
# Output: Found 3 files:
#   ./README.md
#   ./docs/readme.txt
#   ./lib/README.md

# Multiline pattern
ace-search -U "def.*?end"
# Output: Found 45 method definitions
```

## Troubleshooting

### Problem: No results found when expected

**Symptom**: Search returns empty results for known patterns

**Solution**:

```bash
# Check if files are excluded
ace-search "pattern" --exclude none

# Verify search scope
ace-search "pattern" --hidden --include-archived
```

### Problem: Terminal doesn't open files on click

**Symptom**: Clicking on file:line doesn't open editor

**Solution**:

```bash
# Configure your terminal emulator to handle file:// URLs
# For iTerm2: Preferences → Profiles → Advanced → Semantic History
# For VS Code Terminal: Already handles file paths
# For other terminals: Check documentation for URL handling
```

### Problem: Slow search performance

**Symptom**: Searches take too long to complete

**Solution**:

```bash
# Use more specific globs
ace-search --glob "src/**/*.rb" "pattern"

# Exclude large directories
ace-search --exclude "node_modules,vendor" "pattern"

# Limit search scope
ace-search --max-results 100 "pattern"
```

## Best Practices

1. **Use presets for repeated searches**: Create preset files in `.ace/search/presets/`
2. **Set sensible defaults**: Configure common flags in `.ace/search/config.yml`
3. **Combine with git scopes**: Use `--staged` or `--changed` for focused searches
4. **Leverage DWIM mode**: Let the tool detect the best search mode automatically
5. **Use globs for performance**: Narrow search scope with glob patterns
6. **Path-aware file search**: Use partial paths like "controller" to find nested files

## Migration Notes

Migrating from `dev-tools/exe/search`:

**Key changes:**

1. **Editor integration removed**: Use your terminal's built-in file:line clicking instead
   - Remove `--open`, `--editor` flags from scripts
   - Remove `search config --editor` commands

2. **Improved file search**: Now matches full paths
   ```bash
   # Old: only matched filename
   search --files "controller"  # Found: controller.rb

   # New: matches paths too
   ace-search --files "controller"  # Found: app/controllers/user_controller.rb
   ```

3. **Better configuration**: All CLI flags can be defaults
   ```yaml
   # New: .ace/search/config.yml
   ace:
     search:
       case_insensitive: true
       max_results: 100
   ```

4. **Presets in separate files**: `.ace/search/presets/*.yml`

All other flags and output formats remain identical. Symlink provided for compatibility: `search → ace-search`

## Tips for AI Agents

When using ace-search in automated workflows:

1. **Use JSON output** for structured parsing:

   ```bash
   ace-search --json "pattern" | jq '.results[]'
   ```

2. **Combine with other tools**:

   ```bash
   ace-search --files "*.rb" | xargs rubocop
   ```

3. **Batch operations**:

   ```bash
   ace-search --staged "console.log" --files-with-matches | \
     xargs -I {} sed -i '' 's/console.log/logger.debug/g' {}
   ```

## See Also

- `ace-nav` - Resource navigation with wfi:// protocol
- `ace-llm` - LLM integration for code analysis
- `grep` / `rg` - Underlying search tools
- `fd` - File finding backend

