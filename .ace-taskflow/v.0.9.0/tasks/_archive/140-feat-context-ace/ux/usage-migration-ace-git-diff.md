# ace-git-diff to ace-git Migration Guide

This document provides migration guidance for users transitioning from `ace-git-diff` to `ace-git`.

## Overview

The `ace-git-diff` package has been deprecated in favor of `ace-git`, which consolidates all git-related functionality for the ACE ecosystem. The deprecated package continues to work as a thin wrapper, but users should migrate to the new package.

## Deprecation Timeline

- **v0.2.0**: Deprecation warnings added, backward compatibility maintained
- **Future**: Package will be removed after deprecation period

## Migration Steps

### 1. Update Gemfile

```diff
# Gemfile
- gem 'ace-git-diff', '~> 0.1.0'
+ gem 'ace-git', '~> 0.3.0'
```

### 2. Update require statements

```diff
# Ruby code
- require 'ace/git_diff'
+ require 'ace/git'
```

### 3. Update module references

| ace-git-diff | ace-git |
|--------------|---------|
| `Ace::GitDiff` | `Ace::Git` |
| `Ace::GitDiff::Atoms` | `Ace::Git::Atoms` |
| `Ace::GitDiff::Molecules` | `Ace::Git::Molecules` |
| `Ace::GitDiff::Organisms` | `Ace::Git::Organisms` |
| `Ace::GitDiff::Models` | `Ace::Git::Models` |

### 4. Update CLI usage

```diff
# CLI commands
- ace-git-diff [range]
+ ace-git diff [range]

- ace-git-diff --since 7d
+ ace-git diff --since 7d

- ace-git-diff --paths "lib/**/*.rb"
+ ace-git diff --paths "lib/**/*.rb"
```

## API Compatibility

The ace-git package maintains full API compatibility with ace-git-diff:

### DiffOrchestrator

```ruby
# Before (ace-git-diff)
require 'ace/git_diff'
result = Ace::GitDiff::Organisms::DiffOrchestrator.generate(
  ranges: ["origin/main...HEAD"],
  paths: ["lib/**/*.rb"]
)

# After (ace-git)
require 'ace/git'
result = Ace::Git::Organisms::DiffOrchestrator.generate(
  ranges: ["origin/main...HEAD"],
  paths: ["lib/**/*.rb"]
)
```

### Configuration

```ruby
# Before
Ace::GitDiff.config
Ace::GitDiff.default_config
Ace::GitDiff.reset_config!

# After
Ace::Git.config
Ace::Git.default_config
Ace::Git.reset_config!
```

### Error Handling

```ruby
# Before
rescue Ace::GitDiff::Error => e
rescue Ace::GitDiff::GitError => e
rescue Ace::GitDiff::ConfigError => e

# After
rescue Ace::Git::Error => e
rescue Ace::Git::GitError => e
rescue Ace::Git::ConfigError => e
```

## New Features in ace-git

The ace-git package includes additional features beyond diff functionality:

### Repository Context

```bash
# Get full repository context
ace-git context

# Get PR information
ace-git pr [number]

# Get branch info
ace-git branch
```

### Ruby API

```ruby
require 'ace/git'

# Load repository context
context = Ace::Git::Organisms::RepoContextLoader.load
puts context.branch
puts context.task_pattern
puts context.pr_metadata
```

## Configuration Files

Configuration files remain compatible:

```yaml
# .ace/diff/config.yml (unchanged)
exclude_patterns:
  - "test/**/*"
  - "spec/**/*"
  - "**/*.lock"

exclude_whitespace: true
max_lines: 10000
```

## Integration Examples

### ace-docs

```yaml
# No changes needed - ace-docs will use ace-git internally
ace-docs:
  subject:
    diff:
      paths: ["lib/**/*.rb"]
      since: 7d
```

### ace-review

```yaml
# No changes needed - ace-review will use ace-git internally
pr:
  subject:
    diff:
      ranges: ["origin/main...HEAD"]
```

### ace-context

```yaml
# No changes needed - ace-context will use ace-git internally
context:
  diff:
    ranges: ["origin/main...HEAD"]
```

## Troubleshooting

### Deprecation Warning

If you see:
```
[DEPRECATED] ace-git-diff is deprecated. Use ace-git instead.
```

This is expected and indicates you should migrate when convenient. The functionality continues to work.

### Missing ace-git gem

If you get:
```
cannot load such file -- ace/git
```

Ensure ace-git is installed:
```bash
bundle add ace-git
```

### Module Not Found

If you get errors about missing modules after migration:
```
uninitialized constant Ace::Git::Atoms
```

Ensure you have ace-git version 0.3.0 or later, which includes the migrated components.

## Need Help?

- Check ace-git README for updated documentation
- Review task 140.01 for full migration details
- Open an issue if you encounter problems
