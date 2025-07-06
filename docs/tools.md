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

## Tool Categories

### By Function

- **Git Operations**: `gc`, `gl`, `gp`, `gpull`
- **Task Management**: `tn`, `tr`, `tal`, `tnid`, `rc`, `task-manager`
- **Quality Assurance**: `test`, `lint`, `lint-cassettes`, `lint-security`, `build`
- **LLM Integration**: `llm-query`, `llm-models`, `llm-usage-report`
- **Code Review**: `cr`, `cr-docs`, `test-review`, `generate-review-prompt`
- **Development**: `console`, `tree`, `run`, `setup`

### By Target Users

- **AI Coding Agents**: `tn`, `tr`, `tal`, `task-manager`, `llm-query`, `llm-models`, `gc`
- **Human Developers**: `console`, `tree`, `cr`, `test`, `lint`, `build`
- **Both**: `llm-usage-report`, `coding_agent_tools`, `generate-review-prompt`

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

**Current State**: The project has successfully implemented fish shell integration for gem executables. All `dev-tools/exe/` tools are available directly by name without path prefixes.

**Tool Access Methods**: 
- **Development tools**: Use `bin/` prefix for project-specific development workflows
- **Gem executables**: Use tool name directly (fish integration provides automatic path resolution)
- **Legacy references**: Old `dev-tools/exe/` paths still work but are not recommended

## Notes

- **Fish Integration**: All gem executables are available directly by name after setup
- **Development Tools**: Project-specific `bin/` tools require the `bin/` prefix for clarity
- **Security Framework**: Most tools integrate with the project's comprehensive security validation
- **Performance**: LLM tools include intelligent caching and cost tracking
- **Multi-Repository**: Git tools operate seamlessly across all 4 project repositories
- **Task Integration**: Task management tools work with documentation-based workflows in `dev-taskflow/`

---

*This documentation covers the current state of tools as of the migration period. For the most up-to-date information, run individual tools with `--help` flag.*