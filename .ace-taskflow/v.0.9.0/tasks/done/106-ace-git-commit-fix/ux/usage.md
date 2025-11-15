# Path-Restricted Commits with ace-git-commit

## Overview

The enhanced `ace-git-commit` now supports path-restricted commits, allowing you to commit only files within specified directories or paths. This enables more precise, focused commits even when you have multiple unrelated changes staged across your repository.

**Key Benefits:**
- Create focused commits for specific components or features
- Separate concerns when multiple changes are staged
- Maintain cleaner git history with targeted commits
- Compatible with existing ace-git-commit features

## Command Structure

```bash
ace-git-commit [options] [path...]

# Basic usage - commit only files in specified path
ace-git-commit <path>

# Multiple paths
ace-git-commit <path1> <path2> <path3>

# With options
ace-git-commit --message "Custom message" <path>
ace-git-commit --dry-run <path>
```

**Important:** When paths are specified, ONLY files within those paths will be committed, regardless of what else is staged.

## Usage Scenarios

### Scenario 1: Commit Only Task-Related Changes

**Goal:** You've been working on a task and made changes to task files and some gem code. You want to commit just the task changes first.

```bash
# See what's changed
git status
# Shows:
#   modified: .ace-taskflow/v.0.9.0/tasks/106-fix/task.106.md
#   modified: ace-git-commit/lib/ace/git_commit/cli.rb
#   modified: ace-git-commit/test/cli_test.rb

# Commit only the task file
ace-git-commit .ace-taskflow/

# Result: Creates commit with only .ace-taskflow/ changes
# The ace-git-commit changes remain staged for a separate commit
```

### Scenario 2: Commit Library Changes Without Tests

**Goal:** Commit implementation files separately from test files for clearer review.

```bash
# You have changes in both lib/ and test/
git status
# Shows multiple files in ace-git-commit/lib/ and ace-git-commit/test/

# First commit: just the implementation
ace-git-commit ace-git-commit/lib/

# Second commit: the tests
ace-git-commit ace-git-commit/test/
```

### Scenario 3: Multiple Component Updates

**Goal:** Commit related changes from multiple directories in a single commit.

```bash
# Commit both library and executable changes together
ace-git-commit ace-git-commit/lib/ ace-git-commit/exe/

# This commits files from both directories but excludes test/
```

### Scenario 4: Single File Commit

**Goal:** Commit just one specific file from many staged changes.

```bash
# Many files are staged, but you want to commit just the README
ace-git-commit README.md

# Only README.md is committed
```

### Scenario 5: Error Handling - Non-Existent Path

**Goal:** Understand error messages when paths don't exist.

```bash
# Try to commit a non-existent path
ace-git-commit non-existent-dir/

# Error output:
# Error: Path 'non-existent-dir/' does not exist
# No changes committed
```

### Scenario 6: Dry Run to Preview

**Goal:** Preview what would be committed before actual commit.

```bash
# Preview what would be committed from a specific path
ace-git-commit --dry-run .ace-taskflow/

# Shows:
# DRY RUN - Would commit:
#   .ace-taskflow/v.0.9.0/tasks/106-fix/task.106.md
# Commit message would be: "feat(task): Update task 106 implementation plan"
```

## Command Reference

### Basic Path Restriction
```bash
ace-git-commit <path>
```
- `<path>`: Directory or file path to restrict commit to
- Commits ONLY files within the specified path
- Path can be relative or absolute
- Directories should include trailing slash for clarity

### Multiple Paths
```bash
ace-git-commit <path1> <path2> ...
```
- Commits files from ALL specified paths
- Paths are combined (union, not intersection)
- Useful for committing related changes from different directories

### With Custom Message
```bash
ace-git-commit --message "Your message" <path>
ace-git-commit -m "Your message" <path>
```
- Overrides auto-generated commit message
- Path restriction still applies

### Dry Run Mode
```bash
ace-git-commit --dry-run <path>
```
- Shows what would be committed without making changes
- Displays files that would be included
- Shows generated commit message

### Debug Mode
```bash
ace-git-commit --debug <path>
```
- Shows detailed path filtering information
- Displays git commands being executed
- Helpful for troubleshooting

### Current Behavior (No Paths)
```bash
ace-git-commit
```
- Without paths, behaves as before
- Commits all staged files
- Full backward compatibility maintained

## Internal Implementation

The path restriction feature works by:

1. **Path Resolution:** When paths are provided, they're resolved to actual file lists
2. **Staging Reset:** The staging area is reset to remove files outside the paths
3. **Selective Staging:** Only files within the specified paths are staged
4. **Normal Commit:** The standard commit flow proceeds with the filtered file set

This uses git's native path handling through commands like:
- `git reset --quiet` - Clears staging area
- `git add <path>` - Stages only files in path
- `git diff --name-only <path>` - Finds changed files in path

## Tips and Best Practices

### DO:
- ✅ Use path restriction to create focused, single-purpose commits
- ✅ Combine with `--dry-run` to preview before committing
- ✅ Specify multiple related paths when changes span directories
- ✅ Use `git status` to see what's staged before/after

### DON'T:
- ❌ Don't expect files outside paths to remain staged after commit (they're reset)
- ❌ Don't use glob patterns yet (e.g., `**/*.rb`) - not currently supported
- ❌ Don't mix path restriction with `--only-staged` flag

### Performance Tips:
- Path filtering is fast for typical repositories
- For very large repos, be specific with paths to minimize processing
- Use `--debug` to see timing information if performance is a concern

## Troubleshooting

### Issue: "No changes to commit in specified path(s)"
**Cause:** The path exists but has no modified files
**Solution:** Check `git status` to see where changes actually are

### Issue: Files outside path were uncommitted
**Cause:** This is by design - only specified paths are committed
**Solution:** Run `git status` to see remaining changes, commit them separately

### Issue: Expected file not included
**Cause:** File might not be tracked or might be outside the exact path specified
**Solution:** Use `git ls-files <path>` to see what git considers in that path

## Migration from Previous Behavior

Previously, `ace-git-commit <path>` would:
- Ignore the path argument
- Commit ALL staged files
- Path had no effect on what was committed

Now, `ace-git-commit <path>` will:
- ✅ Respect the path argument
- ✅ Commit ONLY files within the path
- ✅ Reset files outside the path from staging

**To maintain old behavior:** Simply don't specify any paths

## Examples Comparison

### Before (Broken)
```bash
$ ace-git-commit .ace-taskflow/
# Would commit: .ace-taskflow/ + Gemfile.lock + other staged files
# Path was ignored!
```

### After (Fixed)
```bash
$ ace-git-commit .ace-taskflow/
# Commits: ONLY files within .ace-taskflow/
# Path is respected!
```

This change brings ace-git-commit in line with git's principle of least surprise and enables more precise commit control.