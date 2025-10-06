# Unified Content Aggregation: ace-context with Git/Diff Support

## Document Type: Reference + How-To Guide

## Overview

ace-context now serves as the universal content aggregator for the ACE ecosystem, with support for files, commands, presets, AND git diffs. This enables unified configuration across all tools and eliminates duplication between ace-review and ace-context.

**What's New:**
- `diffs:` configuration key for git diff ranges
- Unified schema across ace-context and ace-review
- Compose files + commands + presets + diffs in one config
- Single API for all content extraction

## Unified Configuration Schema

### Complete Reference

```yaml
context:
  # File patterns (glob support)
  files:
    - "lib/**/*.rb"
    - "docs/architecture.md"

  # Shell commands to execute
  commands:
    - "git log --oneline -5"
    - "ls -la"

  # Include patterns (glob)
  include:
    - "src/**/*.js"

  # Exclude patterns
  exclude:
    - "**/*_test.rb"
    - "node_modules/**"

  # ace-context presets
  presets:
    - project
    - architecture

  # NEW: Git diff ranges
  diffs:
    - "origin/main...HEAD"
    - "HEAD~5..HEAD"
    - "abc123..def456"
```

### Key Naming Convention

**IMPORTANT**: Use `files:` not `patterns:` for file globs.

```yaml
# ✅ CORRECT
files: ["lib/**/*.rb"]

# ❌ WRONG
patterns: ["lib/**/*.rb"]
```

## Command-Line Interface

### ace-context CLI

```bash
# Load context with git diffs
ace-context --config 'diffs: ["origin/main...HEAD"]' --output ./context.md

# Compose multiple sources
ace-context --config '
  files: ["lib/**/*.rb"]
  diffs: ["HEAD~3..HEAD"]
  presets: [project]
' --output stdio
```

### ace-review CLI

ace-review now uses ace-context for all content extraction.

```bash
# Subject with files
ace-review --subject 'files: ["new-feature/**/*.rb"]' --auto-execute

# Subject with git diff
ace-review --subject 'diffs: ["origin/main...HEAD"]' --auto-execute

# Context with presets (now works!)
ace-review --context 'presets: [project, architecture]' --auto-execute

# Compose subject and context
ace-review \
  --subject 'files: ["lib/**/*.rb"], diffs: ["HEAD~3..HEAD"]' \
  --context 'presets: [project]' \
  --auto-execute
```

## Configuration Examples

### Example 1: Multi-Source Review Subject

**File**: `.ace/review/presets/comprehensive.yml`

```yaml
description: "Comprehensive review with all content types"

subject:
  files:
    - "src/new-feature/**/*.js"     # New feature code
  diffs:
    - "origin/main...HEAD"          # All changes since main
  commands:
    - "git log --oneline -10"       # Recent commits

context:
  presets: [project, architecture]  # Documentation
```

**Usage**:
```bash
ace-review --preset comprehensive --auto-execute
```

### Example 2: Multi-Repository Diff Review

**File**: `.ace/review/presets/multi-repo.yml`

```yaml
description: "Review changes across main repo and submodules"

subject:
  diffs:
    - "origin/main...HEAD"                    # Main repo
    - "ace-context/origin/main...HEAD"        # Submodule 1
    - "ace-review/origin/main...HEAD"         # Submodule 2

context:
  presets: [project]
  files: ["docs/architecture.md"]
```

**Usage**:
```bash
ace-review --preset multi-repo --auto-execute
```

### Example 3: ace-context Preset with Git Context

**File**: `.ace/context/presets/recent-changes.md`

```yaml
---
description: Recent code changes with project context
context:
  files:
    - "README.md"
    - "docs/architecture.md"
  diffs:
    - "HEAD~5..HEAD"
  commands:
    - "git log --oneline -5 --stat"
---

# Recent Changes Context

This preset provides context about recent changes including documentation and git history.
```

**Usage**:
```bash
# Via ace-context
ace-context recent-changes --output ./recent-changes.md

# Via ace-review
ace-review --context 'presets: [recent-changes]' --subject 'files: ["lib/**/*.rb"]'
```

## API Reference

### ace-context Ruby API

```ruby
require 'ace/context'

# Load with git diffs
config = {
  'files' => ['lib/**/*.rb'],
  'diffs' => ['origin/main...HEAD'],
  'presets' => ['project']
}

context = Ace::Context.load_auto(config, format: 'markdown')
puts context.content
```

### Git Diff Formats

The `diffs:` key accepts any valid git diff range:

```yaml
diffs:
  # Two-dot diff (difference between branches)
  - "main..feature"

  # Three-dot diff (changes since divergence)
  - "origin/main...HEAD"

  # Commit range
  - "abc123..def456"

  # Relative to HEAD
  - "HEAD~5..HEAD"
  - "HEAD~1..HEAD"

  # Special keywords (expanded automatically)
  - "staged"          # git diff --staged
  - "working"         # git diff (unstaged)
  - "pr"              # git diff tracking-branch...HEAD
```

## Usage Scenarios

### Scenario 1: Review New Feature with Full Context

**Goal**: Review new feature code with project documentation and recent changes

**Command**:
```bash
ace-review \
  --subject 'files: ["features/auth/**/*.rb"]' \
  --context 'presets: [project], diffs: ["HEAD~10..HEAD"]' \
  --preset security \
  --auto-execute
```

**What happens**:
1. Subject includes all auth feature files
2. Context includes project preset + last 10 commits
3. Review focuses on security (from preset)
4. LLM reviews with full context

**Expected Output**:
```
✓ Review Complete

  Subject: 15 files from features/auth/
  Context: Project docs + 10 recent commits
  Focus: Security analysis

  Review saved: .ace-taskflow/v.0.9.0/reviews/review-20251006-HHMMSS/review.md
```

### Scenario 2: Daily PR Review

**Goal**: Quick review of today's changes

**Command**:
```bash
ace-review \
  --subject 'diffs: ["origin/main...HEAD"]' \
  --context 'presets: [project]' \
  --auto-execute
```

**What happens**:
1. Subject is git diff from main branch
2. Context is project documentation
3. Default PR review preset used
4. Automatic execution

### Scenario 3: Compose Multiple Diff Sources

**Goal**: Review changes from multiple branches/commits

**Command**:
```bash
ace-review \
  --subject 'diffs: ["main..feature-1", "main..feature-2"]' \
  --context 'files: ["docs/api.md"]' \
  --auto-execute
```

**What happens**:
1. Both feature branch diffs included in subject
2. API documentation provides context
3. Review compares both feature implementations

## Configuration Options

### Global Defaults

**File**: `~/.ace/context/config.yml`

```yaml
defaults:
  format: markdown-xml
  max_size: 10485760  # 10MB
  timeout: 30          # seconds
```

### Project Configuration

**File**: `.ace/context/config.yml`

```yaml
defaults:
  format: markdown
  base_dir: ./src

# Project-specific presets
presets:
  quick-review:
    context:
      diffs: ["HEAD~1..HEAD"]
      files: ["README.md"]
```

### ace-review Configuration

**File**: `.ace/review/config.yml`

```yaml
defaults:
  model: "google:gemini-2.5-flash"
  context: "project"  # Use 'project' preset by default

# Storage (uses ace-taskflow)
# storage:
#   base_path: ".ace-taskflow/%{release}/reviews"
```

## Troubleshooting

### Problem: "Preset not found"

**Symptom**:
```
Error: Preset 'project' not found
```

**Solution**:
```bash
# List available presets
ace-context --list-presets

# Check preset file exists
ls -la .ace/context/presets/project.md

# Check preset format (needs frontmatter)
head -20 .ace/context/presets/project.md
```

### Problem: "Invalid git range"

**Symptom**:
```
Error: Failed to extract diff origin/main...HEAD
```

**Solution**:
```bash
# Verify git range is valid
git log --oneline origin/main...HEAD

# Check you're in a git repository
git status

# Try simpler range
ace-review --subject 'diffs: ["HEAD~1..HEAD"]'
```

### Problem: "No code to review"

**Symptom**:
```
Error: No code to review
```

**Solution**:
```bash
# Check config uses 'files:' not 'patterns:'
# WRONG: --subject 'patterns: ["lib/**/*.rb"]'
# RIGHT: --subject 'files: ["lib/**/*.rb"]'

# Verify files exist
ls -la lib/**/*.rb

# Test with explicit file
ace-review --subject 'files: ["README.md"]' --dry-run
```

## Migration from ace-review 0.9.5

### Changed: Preset Support in Context

**Before** (0.9.5 - didn't work):
```bash
ace-review --context 'presets: [project]'
# Error: presets not supported
```

**After** (0.9.6 - works):
```bash
ace-review --context 'presets: [project]'
# ✓ Loads project preset via ace-context
```

### Changed: Use `files:` not `patterns:`

**Before** (confused):
```bash
ace-review --subject 'patterns: ["lib/**/*.rb"]'
# Error: No code to review
```

**After** (correct):
```bash
ace-review --subject 'files: ["lib/**/*.rb"]'
# ✓ Works correctly
```

### New: Compose Multiple Sources

**Now Possible**:
```bash
ace-review \
  --subject 'files: ["new/**/*"], diffs: ["main...HEAD"]' \
  --context 'presets: [project, arch], files: ["docs/api.md"]'
```

## Best Practices

### 1. Use Unified Schema Everywhere

Always use the same keys across ace-context and ace-review:
- `files:` for file paths/globs
- `commands:` for shell commands
- `diffs:` for git ranges
- `presets:` for ace-context presets

### 2. Compose Strategically

```yaml
subject:
  files: ["new/**/*"]        # What's new
  diffs: ["main...feature"]  # What changed

context:
  presets: [project]         # What matters
  files: ["docs/api.md"]     # Specific docs
```

### 3. Use Presets for Common Patterns

Create reusable presets instead of repeating configs:

```yaml
# .ace/review/presets/daily-review.yml
subject:
  diffs: ["origin/main...HEAD"]
context:
  presets: [project]
  diffs: ["HEAD~10..HEAD"]  # Recent context
```

Then: `ace-review --preset daily-review --auto-execute`

## Reference Tables

### Supported Configuration Keys

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `files` | Array | File paths and glob patterns | `["lib/**/*.rb"]` |
| `commands` | Array | Shell commands to execute | `["git log -5"]` |
| `include` | Array | Include patterns (globs) | `["src/**/*.js"]` |
| `exclude` | Array | Exclude patterns | `["**/test/**"]` |
| `presets` | Array | ace-context preset names | `["project", "arch"]` |
| `diffs` | Array | Git diff ranges | `["main...HEAD"]` |

### Git Diff Range Formats

| Format | Description | Example |
|--------|-------------|---------|
| `A..B` | Changes from A to B (two-dot) | `main..feature` |
| `A...B` | Changes since divergence (three-dot) | `origin/main...HEAD` |
| `COMMIT..COMMIT` | Between specific commits | `abc123..def456` |
| `HEAD~N..HEAD` | Last N commits | `HEAD~5..HEAD` |
| `staged` | Staged changes | `staged` |
| `working` | Unstaged changes | `working` |
| `pr` | PR diff vs tracking branch | `pr` |

### ace-review Command Options

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| `--subject` | | What to review | `--subject 'files: [...]'` |
| `--context` | | Background info | `--context 'presets: [project]'` |
| `--preset` | `-p` | Review preset | `--preset security` |
| `--auto-execute` | | Run LLM immediately | `--auto-execute` |
| `--dry-run` | | Prepare without executing | `--dry-run` |
| `--model` | `-m` | Override LLM model | `--model gpt-4` |
