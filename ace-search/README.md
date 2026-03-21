---
doc-type: user
title: ace-search
purpose: Documentation for ace-search/README.md
ace-docs:
  last-updated: 2026-01-08
  last-checked: 2026-03-21
---

# ace-search

Unified search tool for codebases with intelligent pattern matching and configuration.

## Features

- **Project-Wide Search by Default**: Searches entire project from root, regardless of current directory
  > **Note for upgrading users**: Default search behavior changed in `v0.11.0`. See the [Troubleshooting](#troubleshooting) guide for details.
- **Intelligent DWIM Mode**: Automatically detects whether you're searching for files or content
- **Dual Backend**: Uses ripgrep for content search and fd for file search
- **Git-Aware**: Search only staged, tracked, or changed files
- **Configurable Defaults**: Set any CLI flag as a default in configuration
- **Preset System**: Organize common searches as reusable presets
- **Path-Aware File Search**: Matches full paths, not just filenames
- **Interactive Mode**: fzf integration for result selection
- **Multiple Output Formats**: Text (with clickable links), JSON, and YAML
- **Flexible Search Scope**: Optional search path argument to limit scope when needed

## Installation

Add to your Gemfile:

```ruby
gem 'ace-search', path: './ace-search'  # Development
# OR
gem 'ace-search', '~> 0.1.0'  # From RubyGems (when published)
```

Then run:

```bash
bundle install
```

## Quick Start

```bash
# Search entire project (from root, regardless of current directory)
ace-search "TODO"

# Search in current directory only
ace-search "TODO" ./

# Search specific directory
ace-search "TODO" src/

# Search for files
ace-search --files "controller"

# Use a preset
ace-search --preset code "def initialize"

# Interactive mode with fzf
ace-search --fzf "class"
```

## Configuration

Create `.ace/search/config.yml` in your project:

```yaml
ace:
  search:
    case_insensitive: true
    max_results: 100
    exclude:
      - "vendor/**/*"
      - "node_modules/**/*"
      - "coverage/**/*"
```

## Presets

Create preset files in `.ace/search/presets/`:

```yaml
# .ace/search/presets/ruby.yml
name: ruby
description: Search Ruby files only
glob: "*.rb"
exclude:
  - "vendor/**/*"
case_insensitive: false
```

## Usage

See the [usage guide](../../.ace-taskflow/v.0.9.0/t/059-task-search-migrate-tool-ace-search-gem/ux/usage.md) for comprehensive documentation.

## Troubleshooting

### Different results after upgrading to v0.11.0?

**Symptom**: Search finds different files or more/fewer results after upgrade

**Cause**: v0.11.0 changed default search scope from current directory to project root

**Solutions**:
- **Maintain old behavior**: Add `./` argument: `ace-search "pattern" ./`
- **Embrace new behavior**: Remove any `cd` commands in scripts
- **Verify behavior**: Use `DEBUG=1` to see which directory is being searched

### Search path not detected correctly?

**Symptom**: Searches wrong directory or can't find project root

**Debugging**:
```bash
DEBUG=1 ace-search "pattern"  # Shows resolved search path
```

**Solutions**:
- **Set explicitly**: `ace-search "pattern" /specific/path`
- **Override detection**: `PROJECT_ROOT_PATH=/path ace-search "pattern"`
- **Check project markers**: Ensure `.git`, `Gemfile`, or other markers exist in project root

### No results found?

**Common causes**:
1. **Pattern needs escaping**: Use quotes for patterns with spaces or special characters
   ```bash
   ace-search "pattern with spaces"
   ace-search "special.*regex"
   ```

2. **Files excluded by .gitignore**: ace-search respects `.gitignore` files
   ```bash
   ace-search "pattern" --hidden  # Include hidden files
   ```

3. **Search path incorrect**: Verify with `DEBUG=1`

4. **Wrong search mode**: Force content search with `--content` flag

### Warning about non-existent path?

**Symptom**: `Warning: Search path '/path' does not exist`

**Cause**: You provided an explicit search path that doesn't exist (likely a typo)

**Solutions**:
- Check the spelling of the path
- Use tab-completion for paths
- Verify the path exists: `ls /the/path`

## Debugging

ace-search supports debug output via the `DEBUG` environment variable:

```bash
# Show search path resolution and command execution
DEBUG=1 ace-search "pattern"
```

**Debug output shows**:
- Resolved search path (absolute)
- Current working directory
- Actual ripgrep/fd command being executed
- Directory where command executes (chdir)

**Example output**:
```
============================================================
DEBUG: CLI Search Path Resolution
DEBUG: Resolved search path: "/Users/you/project"
DEBUG: Current directory: /Users/you/project/subdirectory
============================================================
DEBUG: RipgrepExecutor
DEBUG: options[:search_path] = "/Users/you/project"
DEBUG: Current Dir.pwd = /Users/you/project/subdirectory
DEBUG: Command: rg --color=never --line-number pattern .
DEBUG: Will chdir to: /Users/you/project
DEBUG: Absolute chdir: /Users/you/project
============================================================
```

**Use cases**:
- Verify project root detection is working correctly
- Debug unexpected search results
- Troubleshoot path resolution issues
- Understand how search scope is determined

## Architecture

Follows the ATOM pattern:
- **Atoms**: Pure functions (ripgrep_executor, fd_executor, pattern_analyzer, result_parser, tool_checker)
- **Molecules**: Composed operations (preset_manager, dwim_analyzer, time_filter, fzf_integrator)
- **Organisms**: Business logic (unified_searcher, result_formatter, result_aggregator)
- **Models**: Data structures (search_result, search_options, search_preset)

## Dependencies

- **ace-core**: Configuration cascade and shared utilities
- **ace-git**: Git operations (scope filtering, staged/modified files)
- **ripgrep** (external): Content search backend
- **fd** (external): File search backend
- **fzf** (external, optional): Interactive selection

## Development

```bash
# Run tests
bundle exec rake test

# Install locally
bundle install

# Try it out
bundle exec ace-search "pattern"
```

## Migration from dev-tools/exe/search

All CLI flags are compatible except editor integration (removed - use terminal's built-in file:line clicking instead).

Key improvements:
- File search now matches full paths
- Configuration supports all CLI flags as defaults
- Presets in separate files for better organization

## Claude Code Agent Integration

ace-search includes two specialized agents for AI-assisted code discovery:

### 1. Search Agent (Tool Wrapper)

**Purpose**: Execute single ace-search commands with intelligent defaults

**Location**: `ace-search/handbook/agents/search.ag.md`

**Features**:
- DWIM mode auto-detection (file vs content)
- Scope control and filtering
- Git integration (staged/tracked/changed)
- Structured response formatting

**Usage**:
```bash
@search "TaskManager"  # Single focused search
```

### 2. Research Agent (Autonomous Orchestrator)

**Purpose**: Plan and execute multi-search investigations to answer research goals

**Location**: `ace-search/handbook/agents/research.ag.md`

**Features**:
- Multi-step search planning (files → structure → details → usage)
- Adaptive strategy based on results
- Synthesized reports with findings
- Pattern and architecture analysis

**Usage**:
```bash
@research "How is authentication implemented?"  # Complex investigation
```

### Agent Locations

Both agents are available at:
- **Source**: `ace-search/handbook/agents/{search,research}.ag.md`
- **Symlinks**: `.claude/agents/{search,research}.ag.md` (optional, for Claude Code integration)

**When to use which:**
- Use `@search` for single queries: "Find all TODO comments"
- Use `@research` for complex questions: "How does the task system work?"

## License

Part of the ACE (Agentic Coding Environment) toolkit.
