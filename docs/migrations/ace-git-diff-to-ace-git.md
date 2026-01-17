# Migrating from ace-git-diff to ace-git

**Date**: 2025-12-27
**Version**: ace-git v0.3.0+

## Overview

The `ace-git-diff` package has been removed and its functionality consolidated into `ace-git`. This migration guide helps you update your code to use the unified package.

## Quick Migration

### 1. Update Gemfile

```ruby
# Before
gem 'ace-git-diff', '~> 0.1'

# After
gem 'ace-git', '~> 0.3'
```

### 2. Update Require Statements

```ruby
# Before
require 'ace/git_diff'

# After
require 'ace/git'
```

### 3. Update Namespace References

All `Ace::GitDiff::*` references become `Ace::Git::*`:

| Before | After |
|--------|-------|
| `Ace::GitDiff::Atoms::*` | `Ace::Git::Atoms::*` |
| `Ace::GitDiff::Molecules::*` | `Ace::Git::Molecules::*` |
| `Ace::GitDiff::Organisms::*` | `Ace::Git::Organisms::*` |
| `Ace::GitDiff::Models::*` | `Ace::Git::Models::*` |

### 4. Update CLI Commands

```bash
# Before
ace-git-diff [options]

# After
ace-git diff [options]
```

## Detailed Changes

### DiffOrchestrator

The primary API remains the same:

```ruby
# Before
result = Ace::GitDiff::Organisms::DiffOrchestrator.generate(
  ranges: ["HEAD~5..HEAD"],
  exclude_renames: true
)

# After
result = Ace::Git::Organisms::DiffOrchestrator.generate(
  ranges: ["HEAD~5..HEAD"],
  exclude_renames: true
)
```

### CommandExecutor

```ruby
# Before
Ace::GitDiff::Atoms::CommandExecutor.execute("git", "status")

# After
Ace::Git::Atoms::CommandExecutor.execute("git", "status")
```

### Error Classes

```ruby
# Before
rescue Ace::GitDiff::Error
rescue Ace::GitDiff::GitError
rescue Ace::GitDiff::ConfigError

# After
rescue Ace::Git::Error
rescue Ace::Git::GitError
rescue Ace::Git::ConfigError
```

### Configuration

Configuration path changed from `.ace/diff/` to `.ace/git/`:

```yaml
# Before: .ace/diff/config.yml
# After: .ace/git/config.yml
```

## New Features in ace-git

The `ace-git` package provides additional functionality beyond diff generation:

- `ace-git status` - Repository context (branch, PR, task pattern)
- `ace-git branch` - Current branch information
- `ace-git diff` - Diff generation (replaces ace-git-diff)
- PR metadata fetching
- Task pattern extraction from branches
- Git scope filtering (staged, tracked, changed files)

## Packages Migrated

The following packages were updated to use ace-git in this consolidation:

- ace-bundle
- ace-docs
- ace-git-commit
- ace-git-worktree
- ace-prompt
- ace-review
- ace-search
- ace-support-test-helpers
- ace-taskflow

## Troubleshooting

### LoadError: cannot load such file -- ace/git_diff

The `ace-git-diff` package has been removed. Update your dependencies:

```bash
bundle update
```

### NoMethodError: undefined method for Ace::GitDiff

Replace all `Ace::GitDiff` references with `Ace::Git`.

### Configuration not found

Move configuration from `.ace/diff/config.yml` to `.ace/git/config.yml`.
