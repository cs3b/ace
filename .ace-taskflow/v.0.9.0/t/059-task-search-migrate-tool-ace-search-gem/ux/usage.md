# ace-search Usage Guide

## Document Type: How-To Guide + Reference

## Overview

Unified search tool for codebases, providing intelligent pattern matching across files and content with editor integration support.

**Key Features:**
- File and content search with ripgrep/fd backends
- Smart DWIM (Do What I Mean) heuristics for search mode selection
- Editor integration with line-number positioning
- Preset support for common search patterns
- Interactive selection with fzf
- Git-aware searching (staged, tracked, changed files)

## Installation

```bash
# Install as gem (once published)
gem install ace-search

# Or add to Gemfile
gem 'ace-search', '~> 0.1.0'

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
| `--files` | `-f` | Search for files only | `ace-search -f "controller"` |
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
| `--open` | | Open results in configured editor | `ace-search --open "bug"` |
| `--preset NAME` | `-p` | Use search preset | `ace-search -p code "TODO"` |

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

**Next Steps**: Open results in editor with `--open` flag

### Scenario 2: Search and edit with editor integration

**Goal**: Find bugs and open them in your editor

**Commands**:
```bash
# Search and open in default editor
ace-search "BUG" --open

# Use specific editor
ace-search "FIXME" --editor vim --open
```

**Expected Output**:
```
Search context: mode: content | pattern: "BUG"
Found 3 results

  ./lib/ace/search/organisms/searcher.rb:67:0: # BUG: Handle nil case
  ./test/integration/search_test.rb:34:0: # BUG: Flaky test
  ./docs/known-issues.md:12:0: - BUG: Search fails with spaces

✓ Opened 3 files in nvim
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
    editor:
      default: nvim
      line_support: true
    exclude_paths:
      - "vendor/**/*"
      - "tmp/**/*"
      - "coverage/**/*"
    presets:
      ruby:
        glob: "*.rb"
        exclude: "vendor"
      docs:
        glob: "*.{md,txt}"
      tests:
        glob: "*_{test,spec}.rb"
```

### Global Configuration

Place in `~/.ace/search/config.yml` for user-wide defaults.

### Editor Configuration

```bash
# View current editor configuration
ace-search config

# Set default editor
ace-search config --editor code

# List available editors
ace-search config --list-editors
```

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

### Configuration Commands

#### `ace-search config`

Manages editor integration and search preferences.

**Subcommands:**
- `--editor EDITOR`: Set default editor
- `--list-editors`: Show available editors

**Examples:**
```bash
# Show current configuration
ace-search config
# Output:
# Current editor configuration:
#
#   Default editor: nvim (nvim)
#   Line support: Yes
#   Status: Configured

# Change default editor
ace-search config --editor code
# Output: ✓ Default editor set to: code
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

### Problem: Editor integration not working

**Symptom**: `--open` flag doesn't open editor

**Solution**:
```bash
# Verify editor is configured
ace-search config

# Set editor explicitly
ace-search config --editor vim

# Test with explicit editor
ace-search "test" --editor nano --open
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

1. **Use presets for repeated searches**: Define common search patterns in configuration
2. **Combine with git scopes**: Use `--staged` or `--changed` for focused searches
3. **Leverage DWIM mode**: Let the tool detect the best search mode automatically
4. **Configure editor once**: Set your preferred editor in global config
5. **Use globs for performance**: Narrow search scope with glob patterns

## Migration Notes

Migrating from `dev-tools/exe/search`:

**No changes required!** ace-search maintains 100% compatibility:

```bash
# Old command (still works)
search "pattern" --type content

# New command (identical behavior)
ace-search "pattern" --type content

# Symlink provided for compatibility
search → ace-search
```

All flags, options, and output formats remain identical. Configuration files in `.ace/` are automatically recognized.

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