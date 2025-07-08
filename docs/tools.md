# Coding Agent Tools - Development Tools Reference

## Overview

This document provides a comprehensive reference for all gem executables in the Coding Agent Tools project. All tools are available directly by name via fish integration, encouraging usage from any directory level without path prefixes.

## Setup Requirements

### Dependencies
- **Ruby** >= 3.2.0
- **Bundler** for dependency management  
- **Git** CLI for repository operations
- **dev-handbook** submodule for task management utilities

### Environment Setup
```bash
# Initial setup (run from dev-tools/ directory)
./bin/setup

# Load Ruby console with gem loaded (run from dev-tools/ directory)
./bin/console
```

## Gem Executables (available via fish integration)

### LLM Integration Tools

#### `llm-query` - Unified LLM Query Interface

Query multiple LLM providers with unified syntax and cost tracking.

```bash
# Query with specific provider and model
llm-query google:gemini-2.5-flash "What is Ruby programming language?"

# Query with provider using default model
llm-query anthropic "Explain ATOM architecture"

# Query with output to file (format inferred from extension)
llm-query openai:gpt-4o "Code review" --output review.json

# Query with system instruction and temperature
llm-query gflash "Write a function" --system "You are a Ruby expert" --temperature 0.7

# Use convenient aliases
llm-query csonet "Explain AI" # claude-4-0-sonnet-latest
llm-query o4mini "Quick help" # gpt-4o-mini
```

**Key Features:**
- Multi-provider support: Google, OpenAI, Anthropic, Mistral, LM Studio
- Convenient aliases for commonly used models
- File input/output with automatic format detection
- Temperature control and system instructions

#### `llm-models` - List Available Models

Discover available models across all configured LLM providers with caching.

```bash
# List models from specific provider with details
llm-models google --detailed

# Quick model availability check across all providers
llm-models --all
```

**Key Features:**
- Cross-provider model discovery with intelligent caching
- Model capability and pricing information
- Availability status with connection testing

#### `llm-usage-report` - Usage and Cost Analysis

Generate comprehensive usage and cost reports for LLM interactions.

```bash
# Monthly cost analysis with breakdown by provider
llm-usage-report --monthly --breakdown

# Custom date range with detailed metrics
llm-usage-report --since "2024-01-01" --verbose
```

**Key Features:**
- Detailed cost analysis with provider breakdown
- Usage patterns and trend analysis
- Export capabilities for accounting integration

### Main CLI Interface

#### `coding_agent_tools` - Main CLI

Primary command-line interface providing access to all gem functionality.

```bash
# Show available commands and subcommands
coding_agent_tools help

# Access specific command help
coding_agent_tools llm help
```

**Key Features:**
- Unified entry point for all gem commands
- Structured subcommand organization
- Consistent help and documentation access

### Task Management

#### `task-manager` - Project Task Management

Advanced task management for project workflows with dependency tracking.

```bash
# Find next actionable task to work on
task-manager next

# List all tasks in current release with dependency order
task-manager all

# Find recently modified tasks
task-manager recent

# Generate new task ID for current release
task-manager generate-id
```

**Key Features:**
- Intelligent task selection with dependency resolution
- Cross-release task tracking and status management  
- Integration with documentation-based task workflows

### Code Review & Analysis

#### `generate-review-prompt` - Advanced Review Generator

Generate comprehensive code review prompts from git changes and project context.

```bash
# Generate review prompt from current git diff
generate-review-prompt --context-lines 5

# Include file-specific analysis with architectural considerations
generate-review-prompt --detailed --arch-focus
```

**Key Features:**
- Git-aware change analysis with context extraction
- Project-specific architectural guidance integration
- Customizable review depth and focus areas

#### `code-review` - Interactive Code Review Tool
```bash
# Interactive code review with guided prompts
code-review --interactive

# Batch review with automated analysis
code-review --batch --output-format json
```

**Key Features:**
- Interactive review workflow with guided prompts
- Automated analysis with customizable depth
- Multiple output formats for integration

#### `code-review-prepare` - Review Preparation Tool
```bash
# Prepare review context with project analysis
code-review-prepare --context full

# Quick preparation with diff focus
code-review-prepare --diff-only
```

**Key Features:**
- Context preparation for efficient reviews
- Project-aware analysis and categorization
- Diff-focused preparation for targeted reviews

#### `code-review-synthesize` - Review Synthesis Tool
```bash
# Synthesize review results into actionable report
code-review-synthesize --format report

# Generate synthesis with recommendations
code-review-synthesize --include-recommendations
```

**Key Features:**
- Review result synthesis with actionable insights
- Recommendation generation for improvement
- Multiple output formats for reporting

#### `reflection-synthesize` - Reflection Report Generator
```bash
# Generate reflection report from session data
reflection-synthesize --session current

# Custom reflection with specific focus areas
reflection-synthesize --focus architecture,testing
```

**Key Features:**
- Session-based reflection report generation
- Focus area customization for targeted analysis
- Integration with development workflow patterns

### Git Command Wrappers

#### `git-add` - Enhanced Git Add
```bash
# Add files with interactive selection
git-add --interactive

# Add with pattern matching
git-add --pattern "*.rb"
```

**Key Features:**
- Interactive file selection with preview
- Pattern-based addition with safety checks
- Integration with project workflow patterns

#### `git-commit` - Enhanced Git Commit
```bash
# Commit with guided message generation
git-commit --guided

# Commit with automatic formatting
git-commit --auto-format
```

**Key Features:**
- Guided commit message generation
- Automatic formatting following project standards
- Integration with multi-repository workflows

#### `git-diff` - Enhanced Git Diff
```bash
# Show differences across repositories
git-diff

# Show staged changes only
git-diff --staged

# Show only names of changed files
git-diff --name-only

# Show diffstat summary
git-diff --stat

# Process specific repository context
git-diff --repository dev-tools
```

**Key Features:**
- Multi-repository diff operations
- Staged and unstaged change analysis
- Repository-specific context support

#### `git-fetch` - Enhanced Git Fetch
```bash
# Fetch with multi-repository support
git-fetch --all-repos

# Fetch with status reporting
git-fetch --report
```

**Key Features:**
- Multi-repository fetch operations
- Status reporting and conflict detection
- Integration with project coordination

#### `git-log` - Enhanced Git Log
```bash
# Log with enhanced formatting
git-log --enhanced

# Log with project context
git-log --project-context
```

**Key Features:**
- Enhanced formatting with project context
- Multi-repository log coordination
- Integration with task management workflows

#### `git-pull` - Enhanced Git Pull
```bash
# Pull with conflict resolution support
git-pull --resolve-conflicts

# Pull with multi-repository coordination
git-pull --all-repos
```

**Key Features:**
- Conflict resolution support with guidance
- Multi-repository coordination
- Integration with development workflows

#### `git-push` - Enhanced Git Push
```bash
# Push with safety checks
git-push --safe

# Push with multi-repository coordination
git-push --all-repos
```

**Key Features:**
- Safety checks and validation before push
- Multi-repository coordination
- Integration with CI/CD workflows

#### `git-status` - Enhanced Git Status
```bash
# Status with project context
git-status --project-context

# Status with multi-repository view
git-status --all-repos
```

**Key Features:**
- Project-aware status reporting
- Multi-repository status coordination
- Integration with task management

### Navigation & Documentation

#### `nav-ls` - Enhanced Directory Listing
```bash
# List with project context
nav-ls --project-context

# List with filtering options
nav-ls --filter "*.rb"
```

**Key Features:**
- Project-aware directory listing
- Advanced filtering and categorization
- Integration with navigation workflows

#### `nav-path` - Intelligent Path Navigation
```bash
# Generate new task path with title
nav-path task-new --title "Feature Name"

# Resolve existing task by ID
nav-path task 42

# Autocorrect and resolve file path
nav-path file README

# Generate new documentation path
nav-path docs-new --title "Documentation Title"

# Generate new reflection path
nav-path reflection-new --title "Session Reflection"
```

**Key Features:**
- Intelligent path generation for tasks, docs, and reflections
- File path autocorrection and resolution
- Integration with task management workflows

#### `nav-tree` - Enhanced Project Tree
```bash
# Tree with project structure awareness
nav-tree --project-structure

# Tree with filtering options
nav-tree --filter source
```

**Key Features:**
- Project structure awareness
- Advanced filtering and categorization
- Integration with development workflows

#### `handbook` - Development Handbook Access
```bash
# Synchronize XML-embedded template content with template files
handbook sync-templates
```

**Key Features:**
- Template synchronization with XML-embedded content
- Development handbook management
- Integration with development processes

### Release Management

#### `release-manager` - Release Management Tool
```bash
# Manage current release
release-manager current

# Generate release reports
release-manager report --format detailed
```

**Key Features:**
- Comprehensive release management
- Report generation with detailed analytics
- Integration with task management workflows

## Tool Categories

### By Function

- **Git Operations**: `git-add`, `git-commit`, `git-diff`, `git-fetch`, `git-log`, `git-pull`, `git-push`, `git-status`
- **Task Management**: `task-manager`, `release-manager`
- **LLM Integration**: `llm-query`, `llm-models`, `llm-usage-report`
- **Code Review**: `generate-review-prompt`, `code-review`, `code-review-prepare`, `code-review-synthesize`
- **Navigation & Documentation**: `nav-ls`, `nav-path`, `nav-tree`, `handbook`
- **Reflection & Analysis**: `reflection-synthesize`

### By Target Users

- **AI Coding Agents**: `task-manager`, `llm-query`, `llm-models`, `nav-path`, `release-manager`
- **Human Developers**: `handbook`, `code-review`, `reflection-synthesize`
- **Both**: `llm-usage-report`, `coding_agent_tools`, `generate-review-prompt`, `git-*`, `nav-ls`, `nav-tree`

## Common Workflows

### For AI Coding Agents

```bash
# 1. Find next task using advanced task manager
task-manager next

# 2. Query LLM for guidance
llm-query google "How to implement feature X?"

# 3. Navigate to relevant files using intelligent path resolution
nav-path file README

# 4. Generate new task when needed
nav-path task-new --title "Implement feature X"
```

### For Human Developers

```bash
# 1. Synchronize handbook templates
handbook sync-templates

# 2. Show git differences across repositories
git-diff --stat

# 3. Use task management for organization
task-manager recent

# 4. Query LLM with specific output format
llm-query anthropic "Code review suggestions" --output review.md
```

## Migration Status

**Current State**: The project encourages direct command usage via fish shell integration. All gem executables are available directly by name from any directory without path prefixes.

**Tool Access Philosophy**: 
- **Direct Usage**: All tools are available directly by name (e.g., `task-manager`, `llm-query`)
- **No Binstubs**: Development binstubs are not documented to encourage direct command usage
- **Fish Integration**: Automatic path resolution for seamless operation from any directory

## Notes

- **Fish Integration**: All gem executables are available directly by name after setup
- **Direct Commands**: Use commands directly from any directory without path prefixes
- **Security Framework**: Most tools integrate with the project's comprehensive security validation
- **Performance**: LLM tools include intelligent caching and cost tracking
- **Git Enhancement**: Git command wrappers provide enhanced functionality over standard git commands
- **Task Integration**: Task management tools work with documentation-based workflows in `dev-taskflow/`

---

*This documentation covers gem executables only, encouraging direct command usage from any directory. For the most up-to-date information, run individual tools with `--help` flag.*