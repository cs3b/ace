# ace-git Usage Documentation

## Overview

ace-git is the unified Git/GitHub package for the ACE mono-repo. It provides:

- **Repository Context** - Branch, PR, task pattern detection
- **Diff Operations** - Migrated from ace-git-diff with full backward compatibility
- **PR Information** - Fetch PR metadata via gh CLI
- **Branch Information** - Current branch and remote tracking status

## Command Types

### Bash CLI Commands

```bash
# All commands run from terminal
ace-git context              # Repository context (branch, PR, task pattern)
ace-git diff [range]         # Git diff (migrated from ace-git-diff)
ace-git pr [number]          # PR information
ace-git branch               # Branch info only
```

## Command Structure

```
ace-git <subcommand> [arguments] [options]
```

### Subcommands

| Command | Arguments | Description |
|---------|-----------|-------------|
| `context` | none | Full repository context |
| `diff` | [range] | Git diff with filtering |
| `pr` | [number] | PR metadata |
| `branch` | none | Current branch info |

### Common Options

| Option | Subcommands | Description |
|--------|-------------|-------------|
| `--format` | diff | Output format: diff, summary |
| `--since` | diff | Changes since date/duration |
| `--paths` | diff | Include only these glob patterns |
| `--exclude` | diff | Exclude these glob patterns |
| `--output` | diff | Write to file |
| `--raw` | diff | Raw unfiltered output |

## Usage Scenarios

### Scenario 1: Get Repository Context for Task Work

**Goal**: Understand current branch state and associated PR before starting work.

**Steps**:
```bash
# Get full context
ace-git context
```

**Expected Output**:
```markdown
# Repository Context

**Branch:** 140-add-git-context
**Remote:** origin/140-add-git-context (up to date)
**Task Pattern:** 140

## Pull Request

| Field | Value |
|-------|-------|
| Number | #75 |
| Title | Add Git Context |
| Status | open |
| Target | main |
| Author | username |
| URL | https://github.com/owner/repo/pull/75 |
```

### Scenario 2: Generate Diff for Code Review

**Goal**: Get filtered diff of recent changes for AI-assisted review.

**Steps**:
```bash
# Smart default (unstaged changes OR branch diff)
ace-git diff

# Specific range
ace-git diff origin/main...HEAD

# With path filtering
ace-git diff --paths "lib/**/*.rb" "src/**/*.js"

# Time-based
ace-git diff --since "7d"
```

**Expected Output**: Git diff content with configurable filtering applied.

### Scenario 3: Check PR Status

**Goal**: Get PR metadata without leaving the terminal.

**Steps**:
```bash
# Current branch PR
ace-git pr

# Specific PR
ace-git pr 123
ace-git pr owner/repo#456
ace-git pr https://github.com/owner/repo/pull/789
```

**Expected Output**:
```markdown
## Pull Request #123

| Field | Value |
|-------|-------|
| Title | Feature implementation |
| Status | open |
| Draft | false |
| Author | developer |
| Base | main |
| Head | feature-branch |
| URL | https://github.com/owner/repo/pull/123 |
```

### Scenario 4: Quick Branch Check

**Goal**: Verify current branch and remote status.

**Steps**:
```bash
ace-git branch
```

**Expected Output**:
```
140-add-git-context
  Remote: origin/140-add-git-context
  Status: up to date
  Task: 140
```

### Scenario 5: Backward Compatibility with ace-git-diff

**Goal**: Existing ace-git-diff commands continue to work.

**Steps**:
```bash
# Old command (still works via alias or path)
ace-git-diff HEAD~5..HEAD

# New equivalent
ace-git diff HEAD~5..HEAD

# All original options work
ace-git diff --since "1 week ago" --format summary
ace-git diff --exclude "test/**/*" "vendor/**/*"
ace-git diff --output changes.diff
```

### Scenario 6: Error Handling - No PR Found

**Goal**: Handle gracefully when no PR exists for current branch.

**Steps**:
```bash
ace-git context
```

**Expected Output**:
```markdown
# Repository Context

**Branch:** main
**Remote:** origin/main (up to date)
**Task Pattern:** none

## Pull Request

No PR found for current branch.
```

## Command Reference

### ace-git context

**Purpose**: Get full repository context including branch, PR, and task pattern.

**Syntax**: `ace-git context`

**Output Format**: Markdown with repository state

**Internal Implementation**:
- Uses `git rev-parse` for branch detection
- Uses `gh pr view` for PR metadata
- Uses task pattern regex for task ID extraction

### ace-git diff [range]

**Purpose**: Generate git diff with filtering (migrated from ace-git-diff).

**Syntax**: `ace-git diff [range] [options]`

**Options**:
- `--format, -f`: Output format (diff, summary)
- `--since, -s`: Changes since date/duration
- `--paths, -p`: Include only these glob patterns
- `--exclude, -e`: Exclude these glob patterns
- `--output, -o`: Write diff to file
- `--config, -c`: Load config from specific file
- `--raw`: Raw unfiltered output

**Configuration**:
- Global: `~/.ace/diff/config.yml`
- Project: `.ace/diff/config.yml`

### ace-git pr [identifier]

**Purpose**: Fetch PR metadata.

**Syntax**: `ace-git pr [number|owner/repo#number|url]`

**Identifier Formats**:
- Simple number: `123`
- Qualified: `owner/repo#456`
- URL: `https://github.com/owner/repo/pull/789`

**Output Format**: Markdown table with PR fields

### ace-git branch

**Purpose**: Get current branch information.

**Syntax**: `ace-git branch`

**Output Format**: Branch name with remote tracking status

## Tips and Best Practices

### Performance

- `ace-git context` with PR: ~500ms (network call to GitHub)
- `ace-git context` without PR: ~100ms (local git only)
- `ace-git diff`: ~50-100ms for typical repositories

### Common Patterns

1. **Task Context Before Work**:
   ```bash
   ace-git context | head -10  # Quick overview
   ```

2. **Review-Ready Diff**:
   ```bash
   ace-git diff --format summary  # Stats first
   ace-git diff > review.diff     # Full diff for review
   ```

3. **CI/CD Integration**:
   ```bash
   ACE_GIT_PR=$(ace-git pr --format json | jq -r '.number')
   ```

### Troubleshooting

**Issue**: `gh: command not found`
**Solution**: Install GitHub CLI: `brew install gh && gh auth login`

**Issue**: `Not authenticated with GitHub`
**Solution**: Run `gh auth login` to authenticate

**Issue**: `PR not found`
**Solution**: Ensure PR exists for current branch or specify PR number

**Issue**: Diff too large
**Solution**: Use `--paths` to filter or `--exclude` to remove noise

## Migration from ace-git-diff

### Key Differences

| ace-git-diff | ace-git |
|--------------|---------|
| `ace-git-diff` | `ace-git diff` |
| Standalone package | Unified package |
| Diff only | Context + Diff + PR + Branch |

### Migration Steps

1. Replace `ace-git-diff` with `ace-git diff` in scripts
2. ace-git-diff CLI will remain as alias during transition
3. Configuration files in `.ace/diff/` continue to work

### Backward Compatibility

- All ace-git-diff options work identically
- Configuration file format unchanged
- Exit codes unchanged
