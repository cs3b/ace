# ace-search

Unified search tool for codebases with intelligent pattern matching and configuration.

## Features

- **Intelligent DWIM Mode**: Automatically detects whether you're searching for files or content
- **Dual Backend**: Uses ripgrep for content search and fd for file search
- **Git-Aware**: Search only staged, tracked, or changed files
- **Configurable Defaults**: Set any CLI flag as a default in configuration
- **Preset System**: Organize common searches as reusable presets
- **Path-Aware File Search**: Matches full paths, not just filenames
- **Interactive Mode**: fzf integration for result selection
- **Multiple Output Formats**: Text (with clickable links), JSON, and YAML

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
# Search for content
ace-search "TODO"

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

## Architecture

Follows the ATOM pattern:
- **Atoms**: Pure functions (ripgrep_executor, fd_executor, pattern_analyzer, result_parser, tool_checker)
- **Molecules**: Composed operations (preset_manager, git_scope_filter, dwim_analyzer, time_filter, fzf_integrator)
- **Organisms**: Business logic (unified_searcher, result_formatter, result_aggregator)
- **Models**: Data structures (search_result, search_options, search_preset)

## Dependencies

- **ace-core**: Configuration cascade and shared utilities
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

Part of the ACE (Agent Coding Environment) toolkit.
