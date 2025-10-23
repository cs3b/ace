# ace-search Project Root Search - Usage Guide

## Overview

The `ace-search` tool now searches the entire project by default, regardless of your current working directory. You can optionally specify a search path to limit the scope.

**Key Benefits:**
- No need to `cd` to project root before searching
- Consistent results from any directory within the project
- Flexible scoping with optional search path argument

## Command Structure

```bash
ace-search [options] PATTERN [SEARCH_PATH]
```

**Arguments:**
- `PATTERN` (required): Search pattern or query string
- `SEARCH_PATH` (optional): Directory or glob to search within
  - If omitted: searches entire project from root
  - If provided: searches only the specified path

**Common Options:**
- `-t, --type TYPE`: Search type (file, content, hybrid, auto)
- `-f, --files`: Search for files only
- `-c, --content`: Search in file content only
- `-i, --case-insensitive`: Case insensitive search
- `-g, --glob PATTERN`: File glob pattern to include
- `--include PATHS`: Include only these paths (comma-separated)
- `--exclude PATHS`: Exclude these paths (comma-separated)
- `-C, --context NUM`: Show NUM lines of context
- `--json`: Output in JSON format
- `--max-results NUM`: Limit number of results

## Usage Scenarios

### Scenario 1: Search Entire Project (Default Behavior)

**Goal:** Find all occurrences of "TODO" anywhere in the project

From any directory within your project (even deeply nested):

```bash
$ cd /path/to/project/deep/nested/subdirectory
$ ace-search "TODO"
```

**Expected Output:**
```
Search context: | mode: content | pattern: "TODO"
Found 42 results

./src/main.rb:15:0: # TODO: Refactor this method
./lib/helper.rb:8:0: # TODO: Add error handling
./test/integration_test.rb:103:0: # TODO: Test edge cases
...
```

**What Happens:**
- Detects project root by finding `.git`, `Gemfile`, etc.
- Searches from project root down
- Returns results with paths relative to project root

### Scenario 2: Search Current Directory Only

**Goal:** Find "config" only in current directory and subdirectories

```bash
$ cd /path/to/project/lib/utils
$ ace-search "config" ./
```

**Expected Output:**
```
Search context: | mode: content | pattern: "config"
Found 5 results

./config_loader.rb:10:0: def load_config
./config_validator.rb:3:0: class ConfigValidator
...
```

**What Happens:**
- `./ ` explicitly limits search to current directory
- Only searches `/path/to/project/lib/utils` and below
- Useful for focused searches in specific areas

### Scenario 3: Search Specific Directory

**Goal:** Find "class" definitions only in the `src/` directory

```bash
$ cd /path/to/project  # Can be anywhere in project
$ ace-search "class" src/
```

**Expected Output:**
```
Search context: | mode: content | pattern: "class"
Found 28 results

src/models/user.rb:5:0: class User
src/controllers/auth.rb:3:0: class AuthController
...
```

**What Happens:**
- Searches only the `src/` directory (relative to current directory)
- Can specify any subdirectory path
- Paths are resolved from your current working directory

### Scenario 4: Search with Glob Pattern

**Goal:** Find "import" statements in all Markdown files in current directory tree

```bash
$ ace-search "import" ./**/*.md
```

**Expected Output:**
```
Search context: | mode: content | pattern: "import"
Found 8 results

./docs/api.md:12:0: import { User } from './models'
./README.md:45:0: import the module
...
```

**What Happens:**
- `./**/*.md` is treated as the search path
- Searches only Markdown files in current directory tree
- Glob patterns work as search path specifiers

### Scenario 5: Use Environment Variable for Project Root

**Goal:** Override project root detection with explicit path

```bash
$ export PROJECT_ROOT_PATH=/custom/project/path
$ ace-search "function"
```

**Expected Output:**
```
Search context: | mode: content | pattern: "function"
Found 156 results

./src/app.js:22:0: function initialize() {
...
```

**What Happens:**
- `PROJECT_ROOT_PATH` env var overrides auto-detection
- Useful for projects without standard markers (.git, etc.)
- Can be set per-session or in shell config

### Scenario 6: Combine Search Path with Include/Exclude

**Goal:** Search only Ruby files in `lib/` and `src/`, excluding `test/`

```bash
$ ace-search "def.*process" --include "lib/,src/" --exclude "test/" --glob "**/*.rb"
```

**Expected Output:**
```
Search context: | mode: content | pattern: "def.*process"
Found 12 results

lib/processor.rb:15:0: def process_data
src/batch_processor.rb:8:0: def process_batch
...
```

**What Happens:**
- Searches from project root (default)
- `--include` limits to `lib/` and `src/` (relative to project root)
- `--exclude` skips `test/` directory
- `--glob` filters to Ruby files only

## Command Reference

### Basic Syntax

```bash
# Search entire project
ace-search "pattern"

# Search specific directory
ace-search "pattern" <directory>

# Search with glob pattern
ace-search "pattern" <glob-pattern>
```

### Search Path Resolution

When you run `ace-search "pattern" [SEARCH_PATH]`, the search path is determined by this priority:

1. **Explicit Path Argument**: If you provide a second argument, it's used as-is
   ```bash
   ace-search "todo" ./          # Current directory
   ace-search "todo" src/        # src/ directory
   ace-search "todo" ../**/*.md  # Parent tree Markdown files
   ```

2. **Environment Variable**: If `PROJECT_ROOT_PATH` is set
   ```bash
   PROJECT_ROOT_PATH=/custom/path ace-search "todo"
   ```

3. **Project Root Detection**: Automatically finds root by looking for:
   - `.git` directory
   - `Gemfile` (Ruby projects)
   - `package.json` (Node.js projects)
   - `Cargo.toml` (Rust projects)
   - `pyproject.toml` (Python projects)
   - Other standard markers

4. **Fallback**: Current directory if no project root found

### Relative Path Behavior

**Include/Exclude Patterns:**
- Always relative to the search directory (explicit path or resolved project root)
- Example with explicit path:
  ```bash
  ace-search "config" src/ --include "models/"
  # Searches: src/models/
  ```
- Example with project root (default):
  ```bash
  ace-search "config" --include "lib/,src/"
  # Searches: /project/lib/ and /project/src/
  ```

**Glob Patterns:**
- Relative to the search directory
- Example:
  ```bash
  ace-search "test" --glob "**/*.rb"
  # Glob applies to project root (or explicit search path)
  ```

### Output Formats

**Text Output (default):**
```bash
ace-search "pattern"
# Human-readable, color-coded (if terminal supports it)
```

**JSON Output:**
```bash
ace-search "pattern" --json
# Machine-parseable JSON
```

**Files Only:**
```bash
ace-search "pattern" -l
# Only print matching file names
```

## Tips and Best Practices

### When to Use Search Path Argument

**Use explicit path when:**
- You want to limit search to a specific area for faster results
- You're working on a specific module/feature
- You want to search outside the project (different directory)

**Use default (project root) when:**
- You want comprehensive results across the entire project
- You're unsure where something might be defined
- You're searching for cross-module references

### Common Patterns

**Find all TODOs in project:**
```bash
ace-search "TODO|FIXME|HACK" --content
```

**Find files by name pattern:**
```bash
ace-search "*config*" --files
```

**Search only Ruby test files:**
```bash
ace-search "describe|it" --glob "**/*_test.rb"
```

**Search staged git changes only:**
```bash
ace-search "pattern" --staged
```

### Troubleshooting

**Issue: "Too many results"**
- Solution: Use `--max-results NUM` to limit output
- Solution: Add `--glob` or `--include` to narrow scope
- Solution: Use explicit search path for specific directory

**Issue: "Not finding files in parent directories"**
- Check: Are you using `./ ` which limits to current directory?
- Solution: Remove search path argument to search entire project
- Verify: Check that project root is detected correctly

**Issue: "Wrong project root detected"**
- Solution: Set `PROJECT_ROOT_PATH` environment variable explicitly
- Example: `export PROJECT_ROOT_PATH=/correct/path`

**Issue: "Searches are slow"**
- Tip: Use `--exclude` to skip large directories (node_modules, .git, etc.)
- Tip: Use `--glob` to limit file types
- Tip: Specify explicit search path for smaller scope

## Migration from Previous Behavior

### What Changed

**Before:**
```bash
$ cd /project/deep/nested/dir
$ ace-search "TODO"
# Only searched /project/deep/nested/dir/** (current dir and below)
```

**After:**
```bash
$ cd /project/deep/nested/dir
$ ace-search "TODO"
# Now searches /project/** (entire project from root)
```

### Maintaining Old Behavior

If you want the old behavior (search only current directory), use `./`:

```bash
ace-search "pattern" ./
```

Or set the environment variable to current directory:

```bash
PROJECT_ROOT_PATH=. ace-search "pattern"
```

### Updating Scripts

**Old script:**
```bash
#!/bin/bash
cd /project/root  # Had to cd to root first
ace-search "pattern"
```

**New script:**
```bash
#!/bin/bash
# No need to cd, works from any directory
ace-search "pattern"
```

## Implementation Notes

**Internal Tools Used:**
- `ripgrep` (`rg`) for content search
- `fd` for file search
- `Ace::Core::Molecules::ProjectRootFinder` for root detection

**Performance:**
- Project root detection is cached, minimal overhead
- Search performance unchanged from previous version
- Large projects may benefit from `--exclude` for faster searches
