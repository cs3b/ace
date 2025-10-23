# ace-git-diff Usage Guide

## Document Type: How-To Guide + Reference

## Overview

`ace-git-diff` is a unified git diff utility that provides consistent diff behavior across all ACE tools. It extracts and consolidates git diff functionality from ace-context and ace-docs into a single, configurable gem.

**Key Features:**
- **Unified Configuration**: Configure diff behavior once in `.ace/diff/config.yml` for all ACE tools
- **No Hardcoded Patterns**: All exclude patterns are user-configurable
- **Smart Filtering**: Raw, filtered, or compact output formats
- **Smart Defaults**: Automatically shows unstaged changes or branch diffs
- **Fast Execution**: No caching needed - diffs generate in <500ms
- **Flexible Integration**: Use `diff:` key for consistency or `commands:` for custom needs

## Installation

```bash
# Add to Gemfile
gem 'ace-git-diff', '~> 0.1.0'

# Or install directly
gem install ace-git-diff

# Verify installation
ace-git-diff --version
```

## Quick Start (5 minutes)

Get started with the most basic usage:

```bash
# Show diff with smart defaults
# (unstaged changes OR branch vs origin/main)
ace-git-diff

# Expected output:
diff --git a/lib/example.rb b/lib/example.rb
--- a/lib/example.rb
+++ b/lib/example.rb
@@ -10,3 +10,4 @@ class Example
   def method
     # changes here
   end
+  # new code
 end
```

**Success criteria**: You see filtered diff output (test files and lock files excluded by default)

## Command Interface

### Basic Usage

```bash
# Smart defaults based on git state
ace-git-diff

# Specific diff range
ace-git-diff HEAD~5..HEAD
ace-git-diff origin/main...HEAD

# Date-based diff
ace-git-diff --since "2025-01-01"    # Absolute date
ace-git-diff --since 7d               # Relative (7 days)
ace-git-diff --since "1 week ago"     # Human-friendly
```

### Output Formats

```bash
# diff (default) - filtered diff output
ace-git-diff                          # Default format
ace-git-diff --format diff            # Explicit

# summary - LLM-powered markdown summary
ace-git-diff --format summary
```

### Command Options

| Option | Short | Description | Example |
|--------|-------|-------------|---------|
| `--format FORMAT` | `-f` | Output format (diff or summary) | `--format summary` |
| `--since DATE` | `-s` | Show changes since date/duration | `--since 7d` |
| `--paths PATTERNS` | `-p` | Include only matching paths (glob) | `--paths "lib/**/*.rb"` |
| `--exclude PATTERNS` | `-e` | Exclude matching paths (glob) | `--exclude "test/**/*"` |
| `--config PATH` | `-c` | Load config from path | `--config .ace/diff/config.yml` |
| `--help` | `-h` | Show help message | `--help` |
| `--version` | `-v` | Show version | `--version` |

## Common Scenarios

### Scenario 1: Review Unstaged Changes (Filtered)

**Goal**: See what changes you've made, excluding test files and noise

**Commands**:
```bash
# Shows unstaged changes with default filtering
ace-git-diff
```

**Expected Output**:
```diff
diff --git a/lib/ace/git_diff/atoms/command_executor.rb b/lib/ace/git_diff/atoms/command_executor.rb
--- a/lib/ace/git_diff/atoms/command_executor.rb
+++ b/lib/ace/git_diff/atoms/command_executor.rb
@@ -15,6 +15,9 @@ module Ace
         def execute_git_command(*command_parts)
           stdout, stderr, status = Open3.capture3(*command_parts)
+          # Add error handling
+          raise GitError, stderr unless status.success?
+
           {
             success: status.success?,
```

**Next Steps**: Stage relevant changes with `git add`

### Scenario 2: Review PR Changes Before Creating PR

**Goal**: See all changes between your branch and origin/main before creating a pull request

**Commands**:
```bash
# Show all changes since branching from origin/main
ace-git-diff origin/main...HEAD
```

**Expected Output**:
```diff
diff --git a/lib/ace/git_diff.rb b/lib/ace/git_diff.rb
new file mode 100644
--- /dev/null
+++ b/lib/ace/git_diff.rb
@@ -0,0 +1,42 @@
+# frozen_string_literal: true
+
+require "ace/core"
+require "ace/git_diff/version"
...
```

**Next Steps**: Use output to write PR description or create PR with `gh pr create`

### Scenario 3: Override Global Exclusions for Debugging

**Goal**: See specific files that are normally excluded (like test files)

**Commands**:
```bash
# Override global excludes to see test files
ace-git-diff --exclude ""  # Empty excludes = no filtering

# Or bypass ace-git-diff entirely for raw git
git diff HEAD~1
```

**Expected Output**:
```diff
diff --git a/Gemfile.lock b/Gemfile.lock
--- a/Gemfile.lock
+++ b/Gemfile.lock
@@ -15,7 +15,7 @@ GEM
-    ace-core (0.9.0)
+    ace-core (0.9.1)
...
diff --git a/test/atoms/command_executor_test.rb b/test/atoms/command_executor_test.rb
...
```

**Next Steps**: Analyze specific files to understand full scope of changes

### Scenario 4: Review Recent Changes in Specific Directory

**Goal**: See only changes to library code since last week

**Commands**:
```bash
# Show filtered changes in lib/ from last 7 days
ace-git-diff --since 7d --paths "lib/**/*.rb"
```

**Expected Output**:
```diff
diff --git a/lib/ace/git_diff/molecules/diff_generator.rb b/lib/ace/git_diff/molecules/diff_generator.rb
--- a/lib/ace/git_diff/molecules/diff_generator.rb
+++ b/lib/ace/git_diff/molecules/diff_generator.rb
@@ -23,6 +23,12 @@ module Ace
           # Generate diff with options
           def generate(ranges, options = {})
+            # Handle special types
+            case options[:type]
+            when :staged
+              return staged_diff
+            when :working
+              return working_diff
```

**Next Steps**: Use this to update documentation or write release notes

### Scenario 5: Get Summary for LLM Analysis

**Goal**: Generate high-level markdown summary of changes for quick review

**Commands**:
```bash
# Summary format uses LLM to analyze and categorize changes
ace-git-diff origin/main...HEAD --format summary
```

**Expected Output**:
```markdown
# Change Summary

HIGH Impact:
- lib/ace/git_diff.rb: Created new gem for unified diff functionality
- ace-review/preset.yml: Added diff: key support for consistent configuration

MEDIUM Impact:
- lib/ace/git_diff/atoms/command_executor.rb: Added error handling (+3 lines)
- lib/ace/git_diff/molecules/diff_generator.rb: Added special type support (+8 lines)

LOW Impact:
- CHANGELOG.md: Documented version 0.1.0
- README.md: Added usage examples

Files changed: 15 | Additions: 450 | Deletions: 120
```

**Next Steps**: Use summary for PR description, release notes, or code review prep

## Configuration

### Project Configuration

Create `.ace/diff/config.yml` in your project root:

```yaml
# Project-wide diff configuration
# All ACE tools will use these settings

# Default exclude patterns (fully customizable, not hardcoded!)
exclude_patterns:
  # Common patterns (modify for your project)
  - "test/**/*"
  - "spec/**/*"
  - "**/*.lock"
  - "vendor/**/*"
  - "node_modules/**/*"
  - "coverage/**/*"
  - "**/fixtures/**/*"
  # Project-specific additions
  - "tmp/**/*"
  - "**/*.generated.rb"
  - "docs/archive/**/*"

# Default diff options
exclude_whitespace: true   # Skip whitespace-only changes
exclude_renames: false      # Include file renames (false = show renames)
exclude_moves: false        # Include moved files (false = show moves)

# Output defaults
max_lines: 10000         # Prevent huge diffs
```

### Global Configuration

Place in `~/.ace/diff/config.yml` for user-wide defaults:

```yaml
# User-wide defaults across all projects

exclude_patterns:
  - "**/*.log"
  - "**/.DS_Store"
  - "**/.env"

exclude_whitespace: true
```

### Configuration Cascade

ace-git-diff uses ace-core's configuration cascade with **complete override** (no merging):

1. **Global**: `~/.ace/diff/config.yml` (user defaults)
2. **Project**: `.ace/diff/config.yml` (project-specific)
3. **Instance**: Command-line options (per-command)

**Important**: Instance config **completely replaces** global config, no array merging.

**Example**:
```yaml
# Global config
exclude_patterns:
  - "test/**/*"
  - "spec/**/*"

# Project config
exclude_patterns:
  - "tmp/**/*"

# Result: ONLY "tmp/**/*" is excluded
# (Global patterns are NOT merged)
```

To keep global patterns AND add project-specific ones, explicitly list both:
```yaml
# Project config
exclude_patterns:
  - "test/**/*"      # Include global pattern explicitly
  - "spec/**/*"      # Include global pattern explicitly
  - "tmp/**/*"       # Add project-specific pattern
```

## Integration with ACE Tools

### Using `diff:` Key in ACE Gems

The consistent way to use ace-git-diff across ACE tools:

**ace-docs** (document frontmatter):
```yaml
ace-docs:
  subject:
    diff:
      paths: ["lib/**/*.rb"]
      since: 7d
```

**ace-review** (preset configuration):
```yaml
pr:
  subject:
    diff:
      ranges: ["origin/main...HEAD"]  # Explicit git range
      # Global exclude patterns applied automatically
```

**ace-context** (context preset):
```yaml
context:
  diff:
    ranges: ["origin/main...HEAD"]
    exclude_patterns: []  # Override to include all files
```

### Fallback to Commands

For custom needs, still use `commands:` approach:
```yaml
# When you need specific git options
subject:
  commands:
    - "git diff --stat origin/main...HEAD"
    - "git log --oneline -10"
```

## Ruby API

### Direct Usage

```ruby
require 'ace/git_diff'

# Generate diff with options
diff = Ace::GitDiff.generate(
  ranges: ["origin/main...HEAD"],
  paths: ["lib/**/*.rb"],
  exclude: ["test/**/*"],
  format: :filtered
)

puts diff
```

### From Configuration

```ruby
# Load from YAML config
config = YAML.load_file(".ace/diff/config.yml")
diff = Ace::GitDiff.from_config(config["diff"])
```

### Integration Helpers

```ruby
# For ace-docs
diff = Ace::GitDiff.for_ace_docs(document)

# For ace-review
diff = Ace::GitDiff.for_ace_review(preset)

# For ace-context
diff = Ace::GitDiff.for_ace_context(config)
```

## Complete Command Reference

### Main Command: `ace-git-diff`

Generate git diffs with configurable filtering and formatting.

**Syntax**:
```bash
ace-git-diff [range] [options]
```

**Parameters**:
- `range`: Git range (e.g., HEAD~5..HEAD, origin/main...HEAD) - optional

**Options**:

| Flag | Short | Type | Description | Default |
|------|-------|------|-------------|---------|
| `--format` | `-f` | string | Output format: filtered, raw, compact | filtered |
| `--type` | `-t` | string | Diff type: staged, working, pr | auto-detect |
| `--since` | `-s` | string | Date or duration (e.g., "2025-01-01", "7d") | none |
| `--paths` | `-p` | array | Path patterns to include (glob) | all |
| `--exclude` | `-e` | array | Path patterns to exclude (glob) | from config |
| `--config` | `-c` | string | Config file path | .ace/diff/config.yml |
| `--help` | `-h` | boolean | Show help message | false |
| `--version` | `-v` | boolean | Show version | false |

**Examples**:

```bash
# Example 1: Default behavior (smart defaults)
ace-git-diff
# Output: Filtered diff of unstaged changes OR branch vs origin/main

# Example 2: Specific range with filtering
ace-git-diff HEAD~10..HEAD --format filtered
# Output: Last 10 commits, test files excluded

# Example 3: Raw diff of staged changes
ace-git-diff --type staged --format raw
# Output: Unfiltered staged changes including all files

# Example 4: Compact diff for specific paths
ace-git-diff --paths "lib/**/*.rb" "ace-*/lib/**/*.rb" --format compact
# Output: LLM-optimized diff of Ruby library files only

# Example 5: Recent changes excluding specific directories
ace-git-diff --since 3d --exclude "docs/**/*" "test/**/*"
# Output: Last 3 days of changes, excluding docs and tests
```

**Exit Codes**:
- `0`: Success
- `1`: General error (git command failed, invalid options)
- `2`: Configuration error (invalid config file)

**See Also**:
- `git diff` - Underlying git command
- `ace-context` - Context loading with diffs
- `ace-review` - Code review with diffs

## Troubleshooting

### Problem: "No changes to show"

**Symptom**: ace-git-diff runs but shows no output

**Solution**:
```bash
# Check git status
git status

# Try raw format to see if filtering is hiding changes
ace-git-diff --format raw

# Check if you're excluding everything
ace-git-diff --exclude ""  # Temporarily disable excludes
```

### Problem: "Command not found: ace-git-diff"

**Symptom**: Shell reports command not found

**Solution**:
```bash
# Verify installation
gem list | grep ace-git-diff

# Install if missing
gem install ace-git-diff

# Check if gem bin path is in PATH
gem environment

# Add to PATH if needed (fish shell)
fish_add_path ~/.local/share/mise/shims
```

### Problem: Diff includes unwanted test files

**Symptom**: Output shows test files despite configuration

**Solution**:
```bash
# Check current config
cat .ace/diff/config.yml

# Verify exclude patterns are correct (glob syntax)
# Correct:   "test/**/*"
# Incorrect: "test/*" (only matches top-level)

# Test pattern matching
ace-git-diff --exclude "test/**/*" --format filtered
```

### Problem: Configuration not being used

**Symptom**: Config changes don't take effect

**Solution**:
```bash
# Verify config file location
ls -la .ace/diff/config.yml

# Check if config is valid YAML
ruby -ryaml -e "YAML.load_file('.ace/diff/config.yml')"

# Explicitly specify config path
ace-git-diff --config .ace/diff/config.yml

# Check configuration cascade (instance overrides project)
# If using --exclude flag, it REPLACES config completely
```

### Problem: Diff too large / slow performance

**Symptom**: Command hangs or produces enormous output

**Solution**:
```bash
# Limit output with max_lines in config
echo "max_lines: 1000" >> .ace/diff/config.yml

# Use more specific path filters
ace-git-diff --paths "lib/ace/git_diff/**/*.rb"

# Use compact format for large diffs
ace-git-diff --format compact

# Check if you're diffing against the wrong base
git log --oneline -20  # Verify your branch structure
```

## Best Practices

1. **Configure Once, Use Everywhere**: Set up `.ace/diff/config.yml` at project start for consistent behavior across all ACE tools

2. **Use Format Appropriately**:
   - `filtered`: Default for human review (excludes noise)
   - `raw`: Debugging and verification (see everything)
   - `compact`: LLM analysis and summaries (optimized for AI)

3. **Leverage Smart Defaults**: Run `ace-git-diff` without arguments during development - it shows what you need based on git state

4. **Customize Exclude Patterns**: Start with defaults, then tune for your project's specific needs (generated files, build artifacts, etc.)

5. **Complete Override Pattern**: Remember config doesn't merge - if you override `exclude_patterns`, list ALL patterns you want

6. **Integration Over Commands**: Use `diff:` key in ACE tools for consistency; fall back to `commands:` only for special cases

7. **Path Filtering**: Use `--paths` to focus on specific areas rather than generating full diff then filtering manually

## Migration Notes

### Migrating from Direct Git Commands

**From**:
```bash
git diff --cached | grep -v "test/" | grep -v ".lock"
```

**To**:
```bash
ace-git-diff --type staged
# Filtering handled by configuration
```

### Migrating ace-docs Document Frontmatter

**From**:
```yaml
ace-docs:
  subject:
    diff:
      filters: ["lib/**/*.rb"]
```

**To**:
```yaml
ace-docs:
  subject:
    diff:
      paths: ["lib/**/*.rb"]
      # Inherits global exclude patterns automatically
```

### Migrating ace-review Presets

**From**:
```yaml
pr:
  subject:
    commands:
      - "git diff origin/main...HEAD"
```

**To**:
```yaml
pr:
  subject:
    diff:
      type: pr  # Simpler and consistent
      # Global exclude patterns applied automatically
```

### Migrating ace-context Presets

**From**:
```yaml
context:
  diffs:
    - "origin/main...HEAD"
```

**To**:
```yaml
context:
  diff:
    ranges: ["origin/main...HEAD"]
    # Can now use all ace-git-diff options
```

## What Makes ace-git-diff Different

### Problem It Solves

**Before ace-git-diff**:
- Each ACE gem had its own git diff logic (duplication)
- Hardcoded exclude patterns in source code (no customization)
- Different filtering behavior across tools (inconsistent)
- No central place to configure project-wide diff preferences

**After ace-git-diff**:
- Single source of git diff functionality (DRY)
- Fully configurable exclude patterns (user control)
- Consistent filtering across all ACE tools (predictable)
- Global configuration with cascade (configure once)

### Key Benefits

1. **Consistency**: Same configuration = same results across ace-docs, ace-review, ace-context, and ace-git-commit

2. **User Control**: No hardcoded constants - customize everything in config files

3. **Simplicity**: One gem to maintain, one configuration to learn

4. **Performance**: No caching needed - fast enough for all use cases (<500ms)

5. **Flexibility**: Use `diff:` for consistency or `commands:` for power-user scenarios
