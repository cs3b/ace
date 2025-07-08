# Coding Agent Tools - Development Tools Reference

## Overview

This document provides a comprehensive reference for all current development tools in the Coding Agent Tools project. The tools are organized into two main categories:

- **Development Tools** - Project-specific tools accessed via `bin/` for development workflows
- **Gem Executables** - User-facing tools available directly by name via fish integration

## Setup Requirements

### Dependencies
- **Ruby** >= 3.2.0
- **Bundler** for dependency management  
- **Git** CLI for repository operations
- **dev-handbook** submodule for task management utilities

### Environment Setup
```bash
# Initial setup
bin/setup

# Load Ruby console with gem loaded
bin/console
```

## Development Tools (`bin/`)

### Git Workflow Tools

#### `bin/gc` - Git Commit with Standardized Format
```bash
# Commit changes with intention-based message
bin/gc -i "fix user authentication bug"

# Multi-repository commit across all 4 repositories
bin/gc -i "update documentation"
```

#### `bin/gl` - Recent Git Log
```bash
# Show recent git commits
bin/gl
```

#### `bin/gp` - Git Push
```bash
# Push to remote repository
bin/gp
```

#### `bin/gpull` - Git Pull
```bash
# Pull from remote repository across all repositories
bin/gpull
```

### Task Management Tools

#### `bin/tn` - Find Next Task
```bash
# Get next unblocked task to work on
bin/tn
```

#### `bin/tr` - List Recent Tasks
```bash
# Show recently modified tasks
bin/tr
```

#### `bin/tal` - List All Tasks
```bash
# Display all tasks across all releases
bin/tal
```

#### `bin/llm-models` - List Available Models (Development)
```bash
# List available models (development version)
bin/llm-models
```

#### `bin/llm-query` - Query LLM Services (Development)
```bash
# Query LLM services (development version)
bin/llm-query anthropic "test query"
```

#### `bin/tnid` - Generate Next Task ID
```bash
# Generate next available task ID
bin/tnid
```

#### `bin/rc` - Get Current Release Context
```bash
# Display current release information
bin/rc
```

### Quality & Testing Tools

#### `bin/test` - Run Test Suite
```bash
# Run RSpec tests with coverage
bin/test
```

#### `bin/lint` - Code Quality Checks
```bash
# Run StandardRB linter
bin/lint
```

#### `bin/lint-cassettes` - VCR Cassette Size Check
```bash
# Check VCR cassette sizes (warnings only)
bin/lint-cassettes
```

#### `bin/lint-security` - Security Linting
```bash
# Run security-focused linting checks
bin/lint-security
```

#### `bin/build` - Build and Verify Gem
```bash
# Build gem and verify installation
bin/build
```

### Development Utilities

#### `bin/console` - Ruby Console
```bash
# Start Ruby console with gem loaded
bin/console
```

#### `bin/tree` - Project Structure Display
```bash
# Display filtered project structure
bin/tree
```

#### `bin/cr` - Code Review Prompt Generator
```bash
# Generate code review prompt from git diff
bin/cr
```

#### `bin/cr-docs` - Documentation Review Generator
```bash
# Generate documentation review prompt
bin/cr-docs
```

#### `bin/test-review` - Test Review Generator
```bash
# Generate test review prompt
bin/test-review
```

#### `bin/llm-usage` - LLM Usage Quick Check
```bash
# Quick usage check for LLM services
bin/llm-usage
```

#### `bin/markdown-sync-embedded-documents` - Markdown Document Synchronizer
```bash
# Synchronize embedded documents in markdown files
bin/markdown-sync-embedded-documents
```

#### `bin/np` - New Project Generator
```bash
# Generate new project structure
bin/np
```

#### `bin/nt` - New Task Generator
```bash
# Generate new task with structured metadata
bin/nt
```

#### `bin/setup-env` - Environment Setup Script
```bash
# Setup development environment
bin/setup-env

# Fish shell specific setup
bin/setup-env.fish
```

### Build & Deployment Tools

#### `bin/run` - Execute Commands
```bash
# Execute commands in gem context
bin/run
```

#### `bin/setup` - Initial Development Setup
```bash
# Install dependencies and setup development environment
bin/setup
```

## Gem Executables (available via fish integration)

### LLM Integration Tools

#### `llm-query` - Unified LLM Query Interface

Query multiple LLM providers with unified syntax and cost tracking.

```bash
# Query with cost tracking and provider selection
llm-query anthropic "Explain ATOM architecture" --track-cost

# Multi-provider usage with model specification
llm-query google "What is Ruby?" --model gemini-pro
```

**Key Features:**
- Multi-provider support: Google, OpenAI, Anthropic, Local models
- Real-time cost tracking across all providers
- Response caching with performance optimization

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
# Find next available task with priority consideration
task-manager next --priority high

# List tasks with status filtering
task-manager list --status pending --current
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
# Diff with context highlighting
git-diff --context-highlight

# Diff with file-specific analysis
git-diff --file-analysis
```

**Key Features:**
- Context-aware diff highlighting
- File-specific analysis and categorization
- Integration with review workflows

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
# Navigate with fuzzy matching
nav-path task README

# Navigate with path generation
nav-path task-new --title "Feature Name"
```

**Key Features:**
- Fuzzy matching for rapid navigation
- Path generation with context awareness
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
# Access handbook with search
handbook --search "workflow"

# Access specific handbook section
handbook --section "development"
```

**Key Features:**
- Searchable development handbook access
- Section-based navigation
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

- **Git Operations**: `gc`, `gl`, `gp`, `gpull`, `git-add`, `git-commit`, `git-diff`, `git-fetch`, `git-log`, `git-pull`, `git-push`, `git-status`
- **Task Management**: `tn`, `tr`, `tal`, `tnid`, `rc`, `task-manager`, `nt`, `np`, `release-manager`
- **Quality Assurance**: `test`, `lint`, `lint-cassettes`, `lint-security`, `build`
- **LLM Integration**: `llm-query`, `llm-models`, `llm-usage-report`, `llm-usage`
- **Code Review**: `cr`, `cr-docs`, `test-review`, `generate-review-prompt`, `code-review`, `code-review-prepare`, `code-review-synthesize`
- **Navigation & Documentation**: `nav-ls`, `nav-path`, `nav-tree`, `handbook`, `tree`
- **Development**: `console`, `run`, `setup`, `setup-env`
- **Documentation**: `markdown-sync-embedded-documents`
- **Reflection & Analysis**: `reflection-synthesize`

### By Target Users

- **AI Coding Agents**: `tn`, `tr`, `tal`, `task-manager`, `llm-query`, `llm-models`, `gc`, `nt`, `np`, `nav-path`, `release-manager`
- **Human Developers**: `console`, `tree`, `cr`, `test`, `lint`, `build`, `handbook`, `code-review`, `reflection-synthesize`
- **Both**: `llm-usage-report`, `coding_agent_tools`, `generate-review-prompt`, `git-*`, `nav-ls`, `nav-tree`, `markdown-sync-embedded-documents`

## Common Workflows

### For AI Coding Agents

```bash
# 1. Find next task using advanced task manager
task-manager next --priority high

# 2. Query LLM for guidance with cost tracking
llm-query google "How to implement feature X?" --track-cost

# 3. Run tests and quality checks
bin/test && bin/lint

# 4. Commit changes with intention-based message
bin/gc -i "implement feature X"
```

### For Human Developers

```bash
# 1. Setup development environment
bin/setup

# 2. Run comprehensive quality checks
bin/test && bin/lint && bin/lint-security

# 3. Generate and review code analysis
generate-review-prompt --detailed

# 4. Build and verify gem
bin/build
```

## Migration Status

**Current State**: The project has successfully implemented fish shell integration for gem executables. All gem executables are available directly by name without path prefixes.

**Tool Access Methods**: 
- **Development tools**: Use `bin/` prefix for project-specific development workflows
- **Gem executables**: Use tool name directly (fish integration provides automatic path resolution)
- **Legacy references**: Old full path references still work but are not recommended

## Notes

- **Fish Integration**: All gem executables are available directly by name after setup
- **Development Tools**: Project-specific `bin/` tools require the `bin/` prefix for clarity
- **Security Framework**: Most tools integrate with the project's comprehensive security validation
- **Performance**: LLM tools include intelligent caching and cost tracking
- **Multi-Repository**: Git tools operate seamlessly across all 4 project repositories
- **Task Integration**: Task management tools work with documentation-based workflows in `dev-taskflow/`

---

*This documentation covers the current state of tools as of the migration period. For the most up-to-date information, run individual tools with `--help` flag.*