# Commit Workflow Instruction

**Goal:** Create well-structured, atomic Git commits following project conventions with intelligent strategy selection based on context.

## Prerequisites

- Changes ready to be committed (implemented, tested, linted)
- Understanding of conventional commit format
- Git repository initialized

## Quick Start

For experienced users:

1. **Auto-detect strategy**: `git-commit` (analyzes changes and selects best approach)
2. **Explicit strategy**: `git-commit --strategy [all|files|review]`
3. **With intention**: `git-commit --intention "implement new feature"`

## Process Steps

### 1. Strategy Determination

The workflow automatically selects the optimal commit strategy based on context:

```bash
# Check repository status
git-status

# Auto-detection logic:
# - Single logical change across few files → all
# - Specific files mentioned → files
# - Multiple unrelated changes → review
# - Large changeset (>10 files) → review
# - Mixed staged/unstaged → review
```

**Manual Strategy Override:**
- `--strategy all`: Commit all changes immediately
- `--strategy files`: Commit specific files only
- `--strategy review`: Analyze changes before committing

### 2. Execute Selected Strategy

#### Strategy: All (Commit Everything)

**When Used:**
- All changes relate to single logical unit
- Working directory should be clean after commit
- No selective staging needed

```bash
# Commit all changes with auto-generated message
git-commit

# Commit all changes with intention
git-commit --intention "description of changes"

# Verification
git-status
```

#### Strategy: Files (Specific Files)

**When Used:**
- Specific files need to be committed
- Partial changes from larger work
- Excluding certain files from commit

```bash
# Commit specific files
git-commit file1.md file2.rb file3.js

# With intention
git-commit file1.md file2.rb --intention "update documentation"

# With glob patterns
git-commit "src/*.js" "docs/*.md" --intention "update source and docs"

# Verification
git-status
```

#### Strategy: Review (Analyze First)

**When Used:**
- Multiple unrelated changes present
- Large changesets needing organization
- Selective staging required
- Quality review before committing

```bash
# Review all changes
git-status
git diff --stat

# Stage selectively
git-add file1.md file2.rb
git diff --staged

# Review and organize more if needed
git-restore --staged unwanted.txt
git-add additional.js

# Commit organized changes
git-commit --intention "focused change description"

# Verify
git-status
```

### 3. Commit Message Generation

Following Conventional Commits specification:

```
<type>(<scope>): <subject>

[body]

[footer]
```

**Auto-generation based on changes:**
- Analyzes modified files and diff content
- Determines appropriate type (feat, fix, docs, etc.)
- Extracts scope from file paths
- Generates descriptive subject
- Includes body for complex changes

**Manual intention enhancement:**
- User-provided intention guides message generation
- Maintains conventional format while incorporating intent
- Adds context-specific details to body

### 4. Post-Commit Actions

```bash
# Verify commit created successfully
git-status
git log -1 --oneline

# Check if more commits needed for remaining changes
git diff --stat

# Push when ready (if working on pushed branch)
git push origin branch-name
```

## Conventional Commit Templates

<templates>
<template name="feature">
feat(<scope>): <description>

- <change-point-1>
- <change-point-2>
- <change-point-3>

Implements #<task-id>
</template>

<template name="fix">
fix(<scope>): <description>

Root cause: <problem-description>
Solution: <solution-description>

Fixes #<issue-id>
</template>

<template name="docs">
docs(<scope>): <description>

- <doc-change-1>
- <doc-change-2>

Updates #<task-id>
</template>

<template name="refactor">
refactor(<scope>): <description>

- <improvement-1>
- <improvement-2>

No functional changes
</template>

<template name="test">
test(<scope>): <description>

- <test-addition-1>
- <test-addition-2>

Improves coverage for #<issue-id>
</template>

<template name="chore">
chore(<scope>): <description>

- <maintenance-task-1>
- <maintenance-task-2>
</template>
</templates>

## Strategy Auto-Detection Logic

```yaml
Auto-Detection Rules:
  # Rule 1: Small, focused changes
  - condition: "changes <= 5 files AND all in same directory"
    strategy: all
    reason: "Single logical unit of work"

  # Rule 2: Documentation only
  - condition: "all changes in *.md files"
    strategy: all
    reason: "Documentation updates are typically atomic"

  # Rule 3: Mixed staged/unstaged
  - condition: "both staged and unstaged changes exist"
    strategy: review
    reason: "Partial staging indicates selective commit needed"

  # Rule 4: Large changeset
  - condition: "changes > 10 files"
    strategy: review
    reason: "Large changes benefit from review and organization"

  # Rule 5: Multiple modules
  - condition: "changes span multiple top-level directories"
    strategy: review
    reason: "Cross-module changes may need separation"

  # Rule 6: Specific files mentioned
  - condition: "user provides file paths"
    strategy: files
    reason: "Explicit file selection requested"

  # Rule 7: Test files only
  - condition: "all changes in test/ or spec/ directories"
    strategy: all
    reason: "Test additions are typically atomic"

  # Default fallback
  - condition: "no specific rule matches"
    strategy: review
    reason: "Conservative default for safety"
```

## Error Handling

### No Changes to Commit

**Error:** "No changes detected"

**Resolution:**
```bash
# Check status
git-status

# Check if changes are in submodules
git submodule foreach git status

# Stage changes if needed
git-add .
```

### Pre-commit Hook Failures

**Error:** "Pre-commit hook failed"

**Resolution:**
```bash
# Fix linting issues
bin/lint --fix

# Fix test failures
bin/test

# Retry commit
git-commit --intention "..."
```

### Invalid File Paths

**Error:** "File not found: [path]"

**Resolution:**
```bash
# List available changed files
git-status

# Use correct paths
git-commit path/to/actual/file.ext
```

### Commit Message Validation

**Error:** "Commit message doesn't follow conventional format"

**Resolution:**
- Ensure message starts with valid type: feat, fix, docs, style, refactor, test, chore
- Use lowercase for scope
- Keep subject under 50 characters
- Use imperative mood

## Advanced Usage

### Multi-Repository Commits

```bash
# Commit in main repo and submodules
git-commit --recursive --intention "synchronize versions"

# Commit only in specific submodule
cd submodule-dir && git-commit --intention "..."
```

### Amending Commits

```bash
# Amend last commit with new changes
git-add forgotten-file.txt
git-commit --amend

# Amend only the message
git-commit --amend --message "feat(scope): better description"
```

### Interactive Staging

```bash
# Stage changes interactively
git add -p

# Then commit staged changes
git-commit --strategy all --intention "..."
```

## Success Criteria

- Commit created with conventional format message
- Only intended changes included in commit
- All tests pass after commit
- Working directory in expected state
- Clear commit history maintained

## Common Patterns

### Feature Implementation

```bash
# Complete feature across multiple files
git-commit --strategy all --intention "implement user authentication"
# Generated: feat(auth): implement user authentication
```

### Bug Fix

```bash
# Fix specific issue
git-commit src/validator.js tests/validator.test.js --intention "fix email validation"
# Generated: fix(validator): fix email validation edge case
```

### Documentation Update

```bash
# Update docs
git-commit README.md docs/api.md --intention "update API documentation"
# Generated: docs(api): update API documentation
```

### Refactoring

```bash
# Review and refactor
git-commit --strategy review --intention "simplify request handling"
# After review, generated: refactor(service): simplify request handling logic
```

## Tool Integration

This workflow integrates with:
- `git-commit`: Enhanced commit wrapper with message generation
- `git-status`: Repository status with context
- `git-add`: Intelligent file staging
- `git-diff`: Change review and analysis

## Usage Examples

> "Commit my changes"
> → Auto-detects strategy based on changes

> "Commit just the documentation updates"
> → Uses files strategy with *.md pattern

> "Review and commit these changes properly"
> → Uses review strategy for careful organization

> "Commit everything with message about fixing auth"
> → Uses all strategy with intention "fixing auth"

---

This workflow provides intelligent, context-aware commit creation while maintaining flexibility for explicit control when needed.