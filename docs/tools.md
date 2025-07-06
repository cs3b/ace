# Coding Agent Tools - Development Tools Reference

## Overview

This document provides a comprehensive reference for all current development tools in the Coding Agent Tools project. The tools are organized into two main categories:

- **`bin/`** - Development tools used when working on the project itself
- **`dev-tools/exe/`** - The actual gem executables that users will run after installing the gem

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

## Gem Executables (`dev-tools/exe/`)

### LLM Integration Tools

#### `llm-query` - Unified LLM Query Interface
```bash
# Query any supported LLM provider
dev-tools/exe/llm-query google "What is Ruby?"
dev-tools/exe/llm-query anthropic "Explain ATOM architecture"
dev-tools/exe/llm-query openai "Write a function"
```

#### `llm-models` - List Available Models
```bash
# List all available models from all providers
dev-tools/exe/llm-models

# List models from specific provider
dev-tools/exe/llm-models google
dev-tools/exe/llm-models anthropic
dev-tools/exe/llm-models openai
```

#### `llm-usage-report` - Usage and Cost Analysis
```bash
# Generate comprehensive usage report
dev-tools/exe/llm-usage-report

# Generate report for specific time period
dev-tools/exe/llm-usage-report --since "2024-01-01"
```

### Main CLI Interface

#### `coding_agent_tools` - Main CLI
```bash
# Display available commands
dev-tools/exe/coding_agent_tools

# Access help for specific commands
dev-tools/exe/coding_agent_tools help
```

### Code Review & Analysis

#### `generate-review-prompt` - Advanced Review Generator
```bash
# Generate comprehensive code review prompt
dev-tools/exe/generate-review-prompt
```

## Tool Categories

### By Function

- **Git Operations**: `gc`, `gl`, `gp`, `gpull`
- **Task Management**: `tn`, `tr`, `tal`, `tnid`, `rc`
- **Quality Assurance**: `test`, `lint`, `lint-cassettes`, `lint-security`, `build`
- **LLM Integration**: `llm-query`, `llm-models`, `llm-usage-report`
- **Code Review**: `cr`, `cr-docs`, `test-review`, `generate-review-prompt`
- **Development**: `console`, `tree`, `run`, `setup`

### By Target Users

- **AI Coding Agents**: `tn`, `tr`, `tal`, `llm-query`, `llm-models`, `gc`
- **Human Developers**: `console`, `tree`, `cr`, `test`, `lint`, `build`
- **Both**: `llm-usage-report`, `coding_agent_tools`

## Common Workflows

### For AI Coding Agents

```bash
# 1. Find next task
bin/tn

# 2. Query LLM for guidance
dev-tools/exe/llm-query google "How to implement feature X?"

# 3. Run tests
bin/test

# 4. Commit changes
bin/gc -i "implement feature X"
```

### For Human Developers

```bash
# 1. Setup environment
bin/setup

# 2. Run quality checks
bin/test && bin/lint

# 3. Review code
bin/cr

# 4. Build gem
bin/build
```

## Migration Status

**Current State**: The project is transitioning from `bin/` to `dev-tools/exe/` for user-facing commands. Some commands exist in both locations during this migration period.

**Future Direction**: 
- User-facing commands will be moved to `dev-tools/exe/`
- Development tools will remain in `bin/`
- Legacy commands will be deprecated gradually

## Notes

- All tools support `--help` flag for detailed usage information
- Most tools integrate with the project's security framework
- LLM tools cache results for improved performance
- Task management tools integrate with the `dev-taskflow/` documentation system
- Git tools operate across all 4 repositories in the multi-repository structure

---

*This documentation covers the current state of tools as of the migration period. For the most up-to-date information, run individual tools with `--help` flag.*