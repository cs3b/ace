# ace-git-commit Usage Guide

## Overview

`ace-git-commit` is a streamlined git commit tool that leverages LLM technology to generate meaningful commit messages. It simplifies the commit process while maintaining conventional commit standards.

## Installation

```bash
# From the ace-meta root directory
bundle install

# The command will be available as
ace-git-commit
```

## Command Interface

### Basic Usage

```bash
# Generate commit message for all changes in repo (default behavior)
ace-git-commit

# Generate commit message with intention context
ace-git-commit -i "fixing authentication bug"

# Use a specific commit message (bypass LLM)
ace-git-commit -m "feat: add user authentication"

# Commit specific files with LLM-generated message
ace-git-commit src/auth.rb src/user.rb

# Commit specific files with intention
ace-git-commit src/auth.rb -i "improve error handling"

# Commit specific files with direct message
ace-git-commit README.md -m "docs: update installation guide"

# Commit only currently staged changes (not all repo changes)
ace-git-commit --only-staged
ace-git-commit -s  # short form
```

### Command Options

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| `--intention` | `-i` | Provide context for LLM message generation | `-i "fix memory leak"` |
| `--message` | `-m` | Use provided message directly (no LLM) | `-m "fix: resolve null pointer"` |
| `--model` | | Override default LLM model | `--model glite` |
| `--only-staged` | `-s` | Commit only currently staged changes | `-s` |
| `--dry-run` | `-n` | Show what would be committed without doing it | `-n` |
| `--debug` | `-d` | Enable debug output | `-d` |

**Note**: By default, ace-git-commit stages ALL changes in the repository unless:
- Specific files are provided as arguments
- The `--only-staged` flag is used

## Use Cases

### 1. Quick Fix Workflow

When you've made a small fix and want a quick commit:

```bash
# Fix a typo in documentation
vim README.md
ace-git-commit README.md

# The LLM will analyze the diff and generate:
# "docs: fix typo in installation section"
```

### 2. Feature Development

When implementing a new feature with multiple files:

```bash
# After implementing authentication
ace-git-commit -i "implement JWT authentication" src/auth/*.rb

# The LLM will generate something like:
# "feat(auth): implement JWT token authentication
#
# - Add token generation and validation
# - Create authentication middleware
# - Update user session handling"
```

### 3. Bug Fix with Context

When fixing a specific bug:

```bash
# After fixing a bug
ace-git-commit -i "fix null pointer exception in user profile"

# Generated message:
# "fix(user): handle null values in profile data
#
# Prevent crash when optional profile fields are missing"
```

### 4. Emergency Hotfix

When you need to commit immediately with a specific message:

```bash
# Direct message without LLM processing
ace-git-commit -m "fix: critical security vulnerability in auth"
```

### 5. Documentation Updates

For documentation-only changes:

```bash
# Update multiple doc files
ace-git-commit docs/*.md -i "update API documentation"

# Generated message:
# "docs(api): update endpoint documentation
#
# - Add new authentication endpoints
# - Update response examples
# - Fix parameter descriptions"
```

### 6. Refactoring

When refactoring code:

```bash
# After refactoring
ace-git-commit -i "refactor database connection handling"

# Generated message:
# "refactor(db): improve connection pool management
#
# - Extract connection logic to separate module
# - Add connection retry mechanism
# - Improve error handling"
```

### 7. Working with Staged Changes

By default, all changes are staged automatically:

```bash
# Commits ALL changes in the repo (default)
ace-git-commit -i "complete user management feature"

# To commit ONLY what's already staged
ace-git-commit --only-staged -i "complete user management feature"
```

### 8. Dry Run Preview

To see what would be committed:

```bash
# Preview the commit without executing
ace-git-commit -n -i "test commit"

# Shows:
# - Files that would be staged
# - Generated commit message
# - But doesn't actually commit
```

## Configuration

### Project Configuration

Create `.ace/git/config/git.yml` in your project:

```yaml
git:
  model: glite  # Default LLM model (alias from ace-llm config)
  conventions:
    format: conventional  # Use conventional commits
    scopes:
      enabled: true
      detect_from_paths: true  # Auto-detect scope from file paths
      custom:  # Project-specific scopes
        - auth
        - api
        - ui
        - db
```

### Global Configuration

Place in `~/.ace/git/config/git.yml` for user-wide defaults:

```yaml
git:
  model: glite  # Default to glite alias
  author:
    sign_commits: true  # GPG sign commits
```

## LLM Models

The tool supports multiple LLM providers via ace-llm:

```bash
# Use different models (defaults to glite alias)
ace-git-commit --model glite                         # Default (alias for gemini-2.0-flash-lite)
ace-git-commit --model gflash                        # Alias for gemini-2.5-flash
ace-git-commit --model anthropic:claude-3.5-sonnet   # Full provider:model format
ace-git-commit --model openai:gpt-4                  # OpenAI's GPT-4
```

## Integration with Git Workflow

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Ensure commit message follows conventions
ace-git-commit --dry-run
```

### Alias Setup

Add to your shell configuration:

```bash
# Quick aliases
alias gc="ace-git-commit"
alias gci="ace-git-commit -i"
alias gcm="ace-git-commit -m"

# Common workflows
alias gcfix="ace-git-commit -i 'fix bug'"
alias gcfeat="ace-git-commit -i 'add feature'"
alias gcdocs="ace-git-commit -i 'update documentation'"
```

## Examples by Commit Type

### Feature Commits

```bash
ace-git-commit -i "add user profile page"
# Generated: "feat(ui): add user profile page with edit capabilities"
```

### Bug Fixes

```bash
ace-git-commit -i "fix login redirect loop"
# Generated: "fix(auth): resolve infinite redirect loop on login failure"
```

### Documentation

```bash
ace-git-commit README.md -i "add troubleshooting section"
# Generated: "docs: add troubleshooting section to README"
```

### Style Changes

```bash
ace-git-commit -i "format code with prettier"
# Generated: "style: apply prettier formatting to all JavaScript files"
```

### Refactoring

```bash
ace-git-commit -i "extract validation logic"
# Generated: "refactor(validation): extract form validation to separate module"
```

### Tests

```bash
ace-git-commit spec/*.rb -i "add user model tests"
# Generated: "test(user): add comprehensive model validation tests"
```

### Chores

```bash
ace-git-commit Gemfile -i "update dependencies"
# Generated: "chore(deps): update Ruby dependencies to latest versions"
```

## Best Practices

1. **Use Intention for Context**: Always provide `-i` with meaningful context for better messages
2. **Review Generated Messages**: Check the LLM-generated message before confirming
3. **Specific Files When Possible**: Specify files to commit for more focused messages
4. **Direct Messages for Clarity**: Use `-m` when you know exactly what the message should be
5. **Configure Scopes**: Set up project-specific scopes in configuration
6. **Understand Default Behavior**: Remember that all changes are staged by default unless using `--only-staged`
7. **Model Selection**: Use glite (default) for fast commits, switch models for complex changes

## Troubleshooting

### LLM Not Responding

```bash
# Check if ace-llm-query is working
ace-llm-query google:gemini-2.0-flash-lite "test"

# Use debug mode
ace-git-commit -d -i "test commit"
```

### Wrong Message Generated

```bash
# Provide more specific intention
ace-git-commit -i "fix: resolve null pointer in UserProfile.getName when user has no profile"

# Or use direct message
ace-git-commit -m "fix(profile): handle null profile in getName method"
```

### Model Errors

```bash
# Try a different model
ace-git-commit --model gflash -i "your intention"

# Check available models
ace-llm-query --list-providers
```

## Advanced Usage

### System Prompt Location

The system prompt is stored in the dev-handbook:

```bash
# System prompt location (maintained centrally)
dev-handbook/templates/prompts/git-commit.system.md
```

This prompt is automatically used by ace-git-commit when calling ace-llm-query.

### Batch Commits

For multiple related commits:

```bash
# Commit frontend changes
ace-git-commit src/ui/*.js -i "update UI components"

# Commit backend changes
ace-git-commit src/api/*.rb -i "update API endpoints"

# Commit tests
ace-git-commit spec/*.rb -i "add tests for new features"
```


## Migration from git-commit

If you're migrating from the dev-tools git-commit:

| Old Command | New Command |
|-------------|-------------|
| `git-commit` | `ace-git-commit` |
| `git-commit --intention "msg"` | `ace-git-commit -i "msg"` |
| `git-commit --message "msg"` | `ace-git-commit -m "msg"` |
| `git-commit --local` | `ace-git-commit --model lmstudio:local` |
| `git-commit --repo-only` | (default behavior) |
| `git-commit --concurrent` | (not supported - single repo only) |

## Summary

`ace-git-commit` streamlines the commit process by:
- Generating meaningful commit messages using LLM (defaults to glite)
- Automatically staging all changes by default (use --only-staged for current staging)
- Following conventional commit standards automatically
- Supporting both automatic and manual message modes
- Integrating seamlessly with existing git workflows
- Providing flexible configuration options

The tool strikes a balance between automation and control, letting you leverage AI when helpful while maintaining the ability to specify exact messages when needed.