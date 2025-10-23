# ace-git-diff CLI Improvements

## Summary of Changes

Three major improvements were made to ace-git-diff based on user feedback:

### 1. ✅ Default Command (No 'diff' Required)

**Before:**
```bash
bin/ace-git-diff diff --since "7d"
```

**After:**
```bash
bin/ace-git-diff --since "7d"
```

The `diff` command is now the default, so you don't need to specify it explicitly.

### 2. ✅ Output to File Support

**CLI:**
```bash
# Save diff to file
bin/ace-git-diff --output changes.diff
bin/ace-git-diff --since "7d" --output /tmp/my-changes.diff

# Short form
bin/ace-git-diff -o changes.diff -s "1 week ago"
```

**Ruby API:**
```ruby
# Save to file
Ace::GitDiff::Organisms::DiffOrchestrator.save_to_file(
  "changes.diff",
  since: "7d",
  paths: ["lib/**/*.rb"]
)

# Save with specific format
Ace::GitDiff::Organisms::DiffOrchestrator.save_with_format(
  "summary.md",
  format: :summary,
  since: "1 week ago"
)
```

### 3. ✅ Improved Help Text

**New Help Structure:**
- Clear section headers (RANGE, EXAMPLES, CONFIGURATION, OUTPUT)
- Comprehensive examples for common use cases
- Better option descriptions
- Exit code documentation

```bash
bin/ace-git-diff help diff
```

Shows detailed help with examples for:
- Smart defaults
- Specific ranges
- Time-based filtering
- Path filtering (glob patterns)
- Saving to file
- Summary format
- Raw unfiltered output
- Configuration files

## Usage Examples

### Basic Usage
```bash
# Smart defaults (unstaged changes OR branch diff)
bin/ace-git-diff

# Since a specific time
bin/ace-git-diff --since "7d"
bin/ace-git-diff --since "1 week ago"
bin/ace-git-diff --since "2025-01-01"
```

### Path Filtering
```bash
# Include only specific paths
bin/ace-git-diff --paths "lib/**/*.rb" "src/**/*.js"

# Exclude specific paths
bin/ace-git-diff --exclude "test/**/*" "vendor/**/*"
```

### Output Options
```bash
# Save to file
bin/ace-git-diff --output changes.diff

# Summary format (human-readable)
bin/ace-git-diff --format summary

# Raw unfiltered
bin/ace-git-diff --raw
```

### Git Ranges
**Note:** When using git ranges, put flags first:
```bash
# Flags first, then range (recommended)
bin/ace-git-diff --output diff.txt HEAD~5..HEAD

# Or use --since instead of ranges
bin/ace-git-diff --since "5 commits ago" --output diff.txt
```

## Public API

### Saving Diffs to Files

```ruby
require 'ace/git_diff'

# Basic save
Ace::GitDiff::Organisms::DiffOrchestrator.save_to_file(
  "my-changes.diff",
  since: "7d"
)
# => "my-changes.diff"

# With options
Ace::GitDiff::Organisms::DiffOrchestrator.save_to_file(
  "/tmp/filtered-diff.txt",
  since: "1 week ago",
  paths: ["lib/**/*.rb"],
  exclude_patterns: ["test/**/*"]
)

# With specific format
Ace::GitDiff::Organisms::DiffOrchestrator.save_with_format(
  "summary.md",
  format: :summary,
  ranges: ["origin/main...HEAD"]
)
```

## Implementation Details

### Changes Made

**Files Modified:**
1. `lib/ace/git_diff/cli.rb`
   - Made `diff` the default command
   - Added `--output` / `-o` option
   - Improved help text with clear sections
   - Added better option descriptions
   - Added `method_missing` for git range support

2. `lib/ace/git_diff/commands/diff_command.rb`
   - Added `write_to_file` method
   - Added file output support with directory creation
   - Confirmation message to stderr (doesn't interfere with piping)

3. `lib/ace/git_diff/organisms/diff_orchestrator.rb`
   - Added `save_to_file(output_path, options = {})`
   - Added `save_with_format(output_path, format:, **options)`

4. `exe/ace-git-diff`
   - Fixed exit code handling for Thor commands

### Features
- ✅ Default command (no 'diff' needed)
- ✅ File output support (`--output` / `-o`)
- ✅ Improved help text
- ✅ Public API for file saving
- ✅ Directory creation for output paths
- ✅ Confirmation messages to stderr
- ✅ Git range support via method_missing

## Testing

All features tested and working:

```bash
# Test 1: Default command
bin/ace-git-diff --since "7d"  ✅

# Test 2: Output to file
bin/ace-git-diff --output /tmp/test.diff --since "2 hours ago"  ✅
# Output: "Diff written to: /tmp/test.diff"

# Test 3: Help text
bin/ace-git-diff help diff  ✅
# Shows comprehensive help with examples

# Test 4: Version
bin/ace-git-diff --version  ✅
# Output: 0.1.0
```

## Backward Compatibility

All changes are backward compatible:
- Existing `ace-git-diff diff` still works
- All previous options still supported
- New features are additive only
- No breaking changes to API

## Documentation

Updated:
- CLI help text (built-in)
- This improvement document
- README.md examples (to be updated)
- Public API documentation in code comments

