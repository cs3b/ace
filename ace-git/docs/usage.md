---
doc-type: user
title: ace-git CLI Usage Reference
purpose: Command reference for ace-git
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-git CLI Usage Reference

Reference for `ace-git` commands, options, and configuration.

## Installation

```bash
# In Gemfile
gem 'ace-git'

# Or install directly
gem install ace-git
```

## Command Overview

`ace-git` ships five commands:

- `diff` for filtered or formatted git diffs
- `status` for repository context and PR activity
- `branch` for current branch and tracking state
- `pr` for PR metadata lookup
- `version` for the installed package version

`ace-git` with no arguments shows help. Git range shorthand such as `HEAD~5..HEAD` routes to `diff`.

## Commands

### `ace-git --help`

Show formatted command help and examples.

```bash
ace-git --help
ace-git -h
```

`ace-git` with no arguments also shows help.

### `ace-git diff [RANGE]`

Generate git diff with configurable filtering and formatting.

```bash
# Smart defaults (unstaged changes OR branch diff)
ace-git diff
ace-git diff --since "7d"

# Specific range
ace-git diff HEAD~10..HEAD
ace-git diff origin/main...HEAD

# Range shorthand (routes to diff)
ace-git HEAD~5..HEAD
ace-git HEAD

# Time-based filtering
ace-git diff --since "1 week ago"
ace-git diff --since "2025-01-01"

# Path filtering (glob patterns)
ace-git diff --paths "lib/**/*.rb" "src/**/*.js"
ace-git diff --exclude "test/**/*" "vendor/**/*"

# Save to file
ace-git diff --output changes.diff
ace-git diff HEAD~5..HEAD --output /tmp/my-changes.diff

# Summary format (human-readable)
ace-git diff --format summary

# Grouped stats format (package/layer grouped)
ace-git diff --format grouped-stats

# Raw unfiltered diff
ace-git diff --raw
```

**Options:**
- `--format, -f` - Output format: `diff` (default), `summary`, `grouped-stats`
- `--since, -s` - Changes since date/duration (e.g., "7d", "1 week ago")
- `--paths, -p` - Include only these glob patterns
- `--exclude, -e` - Exclude these glob patterns
- `--output, -o` - Write diff to file instead of stdout
- `--config, -c` - Load config from specific file
- `--raw` - Raw unfiltered output (no exclusions)

### `ace-git status`

Display comprehensive repository context including current branch, associated PR information, recent commits, and PR activity (merged/open PRs).

```bash
# Full status output (markdown)
ace-git status

# Skip PR lookups (faster, local-only)
ace-git status --no-pr
ace-git status -n

# Control recent commits shown
ace-git status --commits 5    # Show 5 recent commits
ace-git status --commits 0    # Disable recent commits

# JSON output
ace-git status --format json

# Include PR diff in output
ace-git status --with-diff
```

**Options:**
- `--format, -f` - Output format: `markdown` (default), `json`
- `--no-pr, -n` - Skip PR metadata and activity lookups (faster)
- `--commits N` - Number of recent commits to show (default: 3 from config)
- `--with-diff` - Include PR diff in output

**Output includes:**
- Current branch name with git status -sb output
- Remote tracking status (ahead/behind)
- Detected task pattern (from branch name)
- Recent commits (configurable count)
- Associated PR metadata (if found)
- PR activity: recently merged PRs and open PRs

### `ace-git branch`

Display current branch name and remote tracking status.

```bash
ace-git branch
# Output: 140-feature-name (tracking: origin/140-feature-name)

ace-git branch --format json
# Output:
# {
#   "name": "140-feature-name",
#   "detached": false,
#   "tracking": "origin/140-feature-name",
#   "ahead": 2,
#   "behind": 0,
#   "up_to_date": false,
#   "status_description": "2 ahead"
# }
```

**Options:**
- `--format, -f` - Output format: `text` (default), `json`

### `ace-git pr [NUMBER]`

Fetch and display PR metadata using GitHub CLI.

```bash
# Auto-detect PR from current branch
ace-git pr

# Specific PR number
ace-git pr 123

# Cross-repository PR
ace-git pr owner/repo#456

# JSON output
ace-git pr --format json
```

**Options:**
- `--format, -f` - Output format: `markdown` (default), `json`
- `--with-diff` - Include PR diff in output

**PR Number Formats:**
- Simple number: `123`
- Qualified: `owner/repo#456`
- GitHub URL: `https://github.com/owner/repo/pull/789`

**Requirements:** GitHub CLI (`gh`) must be installed and authenticated.

```bash
# Install gh
brew install gh

# Authenticate
gh auth login
```

### `ace-git version`

Print the installed `ace-git` version.

```bash
ace-git version
ace-git --version
```

## Configuration

ace-git uses the ACE configuration cascade:

- **Global config:** `~/.ace/git/config.yml`
- **Project config:** `.ace/git/config.yml`
- **Example config:** `ace-git/.ace-defaults/git/config.yml`

### Example Configuration

```yaml
# .ace/git/config.yml
diff:
  exclude_patterns:
    - "vendor/**/*"
    - "node_modules/**/*"
    - "*.lock"
  exclude_whitespace: true
  exclude_renames: false
  max_lines: 10000
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `exclude_patterns` | Array | See below | Glob patterns to exclude from diff |
| `exclude_whitespace` | Boolean | `true` | Ignore whitespace-only changes |
| `exclude_renames` | Boolean | `false` | Exclude renamed files from diff |
| `exclude_moves` | Boolean | `false` | Exclude moved files from diff |
| `max_lines` | Integer | `10000` | Maximum lines in diff output |
| `timeout` | Integer | `30` | Command timeout in seconds |
| `grouped_stats.layers` | Array | `["lib","test","handbook"]` | Preferred layer grouping order |
| `grouped_stats.collapse_above` | Integer | `5` | Collapse markdown groups above this file count |
| `grouped_stats.show_full_tree` | String | `collapsible` | Tree rendering strategy hint |
| `grouped_stats.dotfile_groups` | Array | `[".ace-taskflow",".ace"]` | Dot-directories to prioritize in grouping |

**Default exclude_patterns** (from `.ace-defaults/git/config.yml`):
- Lock files: `**/*.lock`, `package-lock.json`, `yarn.lock`, `Gemfile.lock`
- Vendored deps: `vendor/**/*`, `node_modules/**/*`
- Build artifacts: `coverage/**/*`, `dist/**/*`, `build/**/*`, `.cache/**/*`
- Test fixtures: `**/fixtures/**/*`, `**/testdata/**/*`

Note: `test/**/*` and `spec/**/*` are NOT excluded by default - test changes are typically important to review.

## Exit Codes

- `0` - Success
- `1` - Error (configuration error, git error, etc.)

## Related Tools

- **ace-git-commit** - Smart git commit generation
- **ace-git-worktree** - Git worktree management
- **ace-bundle** - Load ACE workflow instructions directly
- **ace-nav** - Discover workflow and template protocol paths

## Reusable GitHub Issue Primitives

`ace-git` also exposes reusable library primitives for issue synchronization flows used by other ACE packages:

- `Ace::Git::Molecules::GhCliExecutor` - shared `gh` command execution with timeout and auth/install error handling
- `Ace::Git::Molecules::GithubIssueSync.sync_task(...)` - sticky comment upsert, `ace:tracked` label management, and close/reopen lifecycle actions

These are intended for package integrations such as `ace-task` and are not invoked directly through `ace-git` CLI commands.
