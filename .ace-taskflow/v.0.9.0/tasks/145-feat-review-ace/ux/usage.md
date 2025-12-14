# ace-review Unified Subject Definition - UX Specification

## Overview

The `--subject` flag accepts a unified `type:value` format that clearly separates "what to review" (subject) from "how to review" (preset). This enables composable reviews where you select a review style preset and override just the subject.

## The Core Insight

**Problem**: Users often want to reuse a preset's review style (prompts, focus areas, model) but change what they're reviewing. Currently this requires either:
1. Creating duplicate presets with different subjects
2. Using verbose YAML inline: `--subject 'diffs: ["range"]'`

**Solution**: Simple `type:value` syntax for the most common subject overrides:
```bash
ace-review --preset security --subject diff:origin/main..HEAD
```

## Subject Types

| Type | Format | Description |
|------|--------|-------------|
| `diff:` | `diff:<range>` | Git diff range |
| `pr:` | `pr:<number>` | GitHub PR by number |
| `files:` | `files:<pattern>` | File glob pattern |
| `task:` | `task:<ref>` | Task directory context |
| `staged` | `staged` | Staged changes (keyword) |
| `working` | `working` | Unstaged changes (keyword) |

## Usage Scenarios

### Scenario 1: Review a Feature Branch with Security Focus

**Goal**: Apply security review preset to my current feature branch changes.

```bash
# Current way (verbose)
ace-review --preset security --subject 'diffs: ["origin/main..HEAD"]' --auto-execute

# New way (clean)
ace-review --preset security --subject diff:origin/main..HEAD --auto-execute
```

### Scenario 2: Review a Specific PR with Code Quality Preset

**Goal**: Use the comprehensive code-pr review style on a specific PR.

```bash
# The --pr flag already exists, but subject syntax also works
ace-review --preset code --subject pr:123 --auto-execute

# With full PR URL
ace-review --preset code --subject pr:https://github.com/owner/repo/pull/456 --auto-execute
```

### Scenario 3: Review Specific Files with ATOM Architecture Focus

**Goal**: Review only Ruby files in a specific gem with ATOM architecture focus.

```bash
# Review all Ruby files in ace-review gem
ace-review --preset ruby-atom --subject files:ace-review/**/*.rb --auto-execute

# Multiple patterns (comma-separated)
ace-review --preset ruby-atom --subject files:ace-review/**/*.rb,ace-core/**/*.rb --auto-execute
```

### Scenario 4: Review Staged Changes Before Commit

**Goal**: Quick review of what I'm about to commit.

```bash
# Keyword shortcut
ace-review --preset code --subject staged --auto-execute

# Same as
ace-review --preset code --subject diff:--staged --auto-execute
```

### Scenario 5: Review Task Context

**Goal**: Review all files related to a specific task.

```bash
# Review files changed for task 145
ace-review --preset code --subject task:145 --auto-execute

# Full task reference
ace-review --preset code --subject task:v.0.9.0+task.145 --auto-execute
```

### Scenario 6: Review Recent Commits

**Goal**: Review the last few commits with performance focus.

```bash
# Last commit
ace-review --preset performance --subject diff:HEAD~1..HEAD --auto-execute

# Last 5 commits
ace-review --preset performance --subject diff:HEAD~5..HEAD --auto-execute

# Since yesterday (if using reflog)
ace-review --preset performance --subject diff:HEAD@{yesterday}..HEAD --auto-execute
```

## Command Reference

### Basic Syntax

```bash
ace-review --preset <style> --subject <type:value> [--auto-execute]
```

### Subject Type Details

#### `diff:<range>`

Git diff range specification. Supports all git range syntax:

```bash
--subject diff:origin/main..HEAD       # Compare to main branch
--subject diff:HEAD~3..HEAD            # Last 3 commits
--subject diff:abc123..def456          # Between specific commits
--subject diff:v1.0.0..v1.1.0          # Between tags
--subject diff:feature/my-branch       # Compared to current HEAD
```

**Internal**: Resolves to `diffs: ["<range>"]` in ace-context

#### `pr:<identifier>`

GitHub Pull Request. Supports multiple formats:

```bash
--subject pr:123                                    # PR number (current repo)
--subject pr:owner/repo#456                         # Qualified PR reference
--subject pr:https://github.com/owner/repo/pull/789 # Full URL
```

**Internal**: Uses `gh pr diff` via existing PR integration

#### `files:<pattern>`

File glob pattern(s):

```bash
--subject files:lib/**/*.rb                  # All Ruby files in lib/
--subject files:ace-review/**/*              # All files in ace-review/
--subject files:*.md                         # All markdown files in root
--subject files:lib/**/*.rb,test/**/*_test.rb  # Multiple patterns
```

**Internal**: Resolves to `files: ["<pattern>"]` in ace-context

#### `task:<reference>`

Task directory context:

```bash
--subject task:145                    # Task by number
--subject task:task.145               # With prefix
--subject task:v.0.9.0+task.145       # Full reference
--subject task:145.01                 # Subtask
```

**Internal**: Resolves task via ace-taskflow, includes task file and related changes

#### Keywords

Special keywords for common scenarios:

```bash
--subject staged     # git diff --staged
--subject working    # git diff (unstaged changes)
```

## Preset + Subject Composition Examples

The power of unified subject syntax is composability:

```bash
# Security review on staged changes
ace-review --preset security --subject staged

# Performance review on specific files
ace-review --preset performance --subject files:lib/ace/review/**/*.rb

# Documentation review on PR
ace-review --preset docs --subject pr:123

# Test review on recent changes
ace-review --preset test --subject diff:HEAD~1..HEAD

# Spec review on task context
ace-review --preset spec --subject task:145
```

## Error Handling

### Invalid Subject Format

```bash
$ ace-review --preset code --subject invalid_format
Error: Invalid subject format. Expected 'type:value' or keyword.

Valid formats:
  --subject diff:<range>     Git diff range (e.g., diff:origin/main..HEAD)
  --subject pr:<number>      GitHub PR (e.g., pr:123)
  --subject files:<pattern>  File pattern (e.g., files:lib/**/*.rb)
  --subject task:<ref>       Task reference (e.g., task:145)
  --subject staged           Staged changes
  --subject working          Unstaged changes

Examples:
  ace-review --preset code --subject diff:HEAD~3..HEAD
  ace-review --preset security --subject pr:123
  ace-review --preset docs --subject files:docs/**/*.md
```

### Empty Subject Resolution

```bash
$ ace-review --preset code --subject diff:origin/main..origin/main
Warning: Subject resolved to 0 files. Nothing to review.
```

### Unknown Subject Type

```bash
$ ace-review --preset code --subject commit:abc123
Error: Unknown subject type 'commit'.

Supported types: diff, pr, files, task
Did you mean: diff:abc123 (for commit range)?
```

## Backward Compatibility

All existing `--subject` usage continues to work:

```bash
# YAML syntax (still works)
ace-review --subject 'diffs: ["origin/main..HEAD"]' --auto-execute

# Keywords (still work)
ace-review --subject staged --auto-execute
ace-review --subject pr --auto-execute

# Auto-detection (still works)
ace-review --subject "HEAD~5..HEAD" --auto-execute  # Detected as git range
ace-review --subject "lib/**/*.rb" --auto-execute   # Detected as file pattern
```

The new `type:value` format is additive - it provides clearer, more explicit syntax without breaking existing behavior.

## Future Considerations

### Potential Additional Subject Types

- `commit:<sha>` - Single commit diff
- `branch:<name>` - Branch comparison
- `dir:<path>` - Directory contents
- `url:<url>` - Remote file/content

### Subject Presets (Phase 2)

Reusable subject definitions for common scopes:

```yaml
# .ace/review/subjects/my-gem.yml
type: files
patterns:
  - "ace-my-gem/lib/**/*.rb"
  - "ace-my-gem/test/**/*_test.rb"
exclude:
  - "**/fixtures/**"
```

```bash
ace-review --preset code --subject-preset my-gem
```

## Tips and Best Practices

1. **Use explicit types** for clarity in scripts and documentation:
   ```bash
   # Clear
   ace-review --preset code --subject diff:origin/main..HEAD

   # Less clear (auto-detected)
   ace-review --preset code --subject "origin/main..HEAD"
   ```

2. **Combine with `--dry-run`** to preview subject resolution:
   ```bash
   ace-review --preset code --subject files:lib/**/*.rb --dry-run
   ```

3. **Default preset** can be set in config, allowing subject-only commands:
   ```yaml
   # .ace/review/config.yml
   defaults:
     preset: code
   ```
   ```bash
   # Now just specify subject
   ace-review --subject diff:HEAD~1..HEAD --auto-execute
   ```

4. **Task integration** works with subject override:
   ```bash
   # Save to task directory, but review specific files
   ace-review --preset code --subject files:lib/**/*.rb --task 145 --auto-execute
   ```

## Migration Notes

### From --pr Flag

The existing `--pr` flag remains and is preferred for PR reviews (it includes metadata fetching and comment posting). The `--subject pr:123` syntax is an alias for basic PR diff review.

```bash
# Full PR review with metadata and comments
ace-review --pr 123 --auto-execute

# Just the PR diff (no metadata)
ace-review --preset code --subject pr:123 --auto-execute
```

### From Inline YAML

```bash
# Before
ace-review --subject 'diffs: ["origin/main..HEAD"], files: ["lib/**/*.rb"]'

# After (single type)
ace-review --subject diff:origin/main..HEAD

# Complex subjects still use YAML
ace-review --subject 'diffs: ["origin/main..HEAD"], files: ["lib/**/*.rb"]'
```
