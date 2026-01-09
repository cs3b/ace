# ace-search Usage Reference

This document captures the expected CLI behavior that must be preserved during the refactoring. Since this is an internal refactoring task (eliminating the wrapper pattern), the user-facing behavior must remain identical.

## Overview

ace-search provides unified file and content search with intelligent pattern matching. It auto-detects search type based on the pattern provided.

## Command Structure

```bash
ace-search [PATTERN] [SEARCH_PATH] [OPTIONS]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| PATTERN | Yes | Search pattern (regex or glob) |
| SEARCH_PATH | No | Optional directory to search in (defaults to project root) |

### Search Type Auto-Detection

Patterns are automatically classified:
- Glob patterns (`*.rb`, `**/*.js`) -> file search
- Regex patterns (`TODO`, `class.*`) -> content search
- Use `--files` or `--content` to override

## Usage Scenarios

### Scenario 1: Basic Content Search

**Goal**: Find all occurrences of a pattern in code

```bash
ace-search "TODO"
```

**Expected Output**:
```
mode: content | pattern: "TODO" | path: .

Found 15 results in 8 files

lib/ace/search/cli.rb:23:# TODO: Add caching
test/integration_test.rb:45:# TODO: Fix flaky test
...
```

### Scenario 2: File Search with Glob Pattern

**Goal**: Find files matching a pattern

```bash
ace-search "*.rb" --files
```

**Expected Output**:
```
mode: file | pattern: "*.rb" | path: .

Found 42 results

lib/ace/search/cli.rb
lib/ace/search/commands/search.rb
...
```

### Scenario 3: Limited Results with JSON Output

**Goal**: Get structured search results for programmatic use

```bash
ace-search "pattern" --json --max-results 5
```

**Expected Output**:
```json
{
  "count": 5,
  "mode": "content",
  "results": [
    {"file": "lib/file.rb", "line": 42, "content": "...pattern..."},
    ...
  ]
}
```

### Scenario 4: Case-Insensitive Search with Context

**Goal**: Find matches with surrounding lines

```bash
ace-search "error" -i -C 3
```

**Expected Output**:
```
mode: content | pattern: "error" | path: .

Found 8 results

lib/file.rb
40-  def process
41-    begin
42:      raise error("Failed")  # Match
43-    rescue
44-    end
```

### Scenario 5: Scoped Search (Git Staged Files)

**Goal**: Search only in staged files

```bash
ace-search "FIXME" --staged
```

### Scenario 6: Subdirectory Search

**Goal**: Limit search to specific directory

```bash
ace-search "test" lib/
```

## Command Reference

### Search Type Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--type TYPE` | `-t` | Explicit type (file, content, hybrid, auto) |
| `--files` | `-f` | Search for files only |
| `--content` | `-c` | Search in file content only |

### Pattern Matching Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--case-insensitive` | `-i` | Case insensitive search |
| `--whole-word` | `-w` | Match whole words only |
| `--multiline` | `-U` | Enable multiline matching |
| `--hidden` | | Include hidden files |

### Context Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--after-context NUM` | `-A` | Show NUM lines after match |
| `--before-context NUM` | `-B` | Show NUM lines before match |
| `--context NUM` | `-C` | Show NUM lines of context |

### File Filtering Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--glob PATTERN` | `-g` | File glob pattern to include |
| `--include PATHS` | | Include only these paths (comma-separated) |
| `--exclude PATHS` | `-e` | Exclude paths (comma-separated) |
| `--since TIME` | | Files modified since TIME |
| `--before TIME` | | Files modified before TIME |

### Git Scope Options

| Option | Description |
|--------|-------------|
| `--staged` | Search staged files only |
| `--tracked` | Search tracked files only |
| `--changed` | Search changed files only |

### Output Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--json` | | Output in JSON format |
| `--yaml` | | Output in YAML format |
| `--files-with-matches` | `-l` | Only print filenames |
| `--max-results NUM` | | Limit number of results |

### Interactive Options

| Option | Description |
|--------|-------------|
| `--fzf` | Use fzf for interactive selection |

### Preset Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--preset NAME` | `-p` | Use search preset |

### Standard Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--quiet` | `-q` | Suppress config summary output |
| `--verbose` | `-v` | Enable verbose output |
| `--debug` | `-d` | Enable debug output |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (results found or no errors) |
| 1 | Error (invalid input, missing pattern, search failure) |

## Configuration

ace-search loads configuration from:
1. Global: `~/.ace/search/config.yml`
2. Project: `.ace/search/config.yml`

## Verification Commands

After refactoring, these commands must produce identical output:

```bash
# Help text
ace-search --help

# Version
ace-search --version

# Basic search
ace-search "test" --max-results 1

# File search
ace-search "*.rb" --files --max-results 1

# JSON output
ace-search "test" --json --max-results 1

# Scoped search
ace-search "def " lib/ --max-results 1
```
