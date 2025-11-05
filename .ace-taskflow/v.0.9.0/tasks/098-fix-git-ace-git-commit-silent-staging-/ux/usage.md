# ace-git-commit Enhanced User Experience

## Overview

The improved ace-git-commit tool provides transparent feedback throughout the staging and commit process, ensuring users always know what's happening with their changes.

## Key Features

- Clear staging status messages (visible by default, not debug-only)
- Immediate failure detection and reporting
- Accurate error messages that reflect actual outcomes
- Actionable guidance when issues occur
- Proper handling of pre-commit hook modifications

## Command Structure

```bash
ace-git-commit [options]
  -m, --message MESSAGE    Commit message to use
  -i, --inline MESSAGE     Short inline message
  -s, --staged             Only commit currently staged files
  -f, --files FILE1,FILE2  Stage specific files
  -d, --debug             Enable debug output
  -v, --verbose           Enable verbose output (default: true)
  -q, --quiet             Suppress informational messages
```

## Usage Scenarios

### Scenario 1: Normal Operation with Unstaged Files

**Goal:** Commit all unstaged changes with automatic staging

**Commands:**
```bash
$ ace-git-commit -i "fix: resolve authentication bug"
```

**Expected Output:**
```
Analyzing repository status...
Found 3 modified files, 1 new file

Staging all changes...
  ✓ app/auth/login.rb (modified)
  ✓ app/auth/session.rb (modified)
  ✓ test/auth_test.rb (modified)
  ✓ docs/auth.md (new)
✓ Successfully staged 4 files

Generating commit message...
✓ Message generated based on changes

Committing changes...
✓ Committed successfully: abc1234 fix: resolve authentication bug

Summary:
- Files changed: 4
- Insertions: 42 lines
- Deletions: 15 lines
```

### Scenario 2: Staging Permission Failure

**Goal:** Handle file permission errors gracefully

**Commands:**
```bash
$ ace-git-commit -i "feat: add config"
```

**Expected Output:**
```
Analyzing repository status...
Found 2 modified files

Staging all changes...
  ✓ config/settings.yml (modified)
  ✗ config/protected.yml (modified) - Permission denied
✗ Failed to stage all changes

Error: Unable to stage 1 file due to permission issues:
  - config/protected.yml: Permission denied

Suggestions:
  1. Fix file permissions: chmod 644 config/protected.yml
  2. Stage manually: git add config/protected.yml (with sudo if needed)
  3. Commit only staged files: ace-git-commit --staged

Currently staged files (1):
  - config/settings.yml
```

### Scenario 3: Pre-commit Hook Modifications

**Goal:** Properly handle when pre-commit hooks modify files

**Commands:**
```bash
$ ace-git-commit -i "style: format code"
```

**Expected Output:**
```
Analyzing repository status...
Found 5 modified files

Staging all changes...
  ✓ lib/processor.rb (modified)
  ✓ lib/analyzer.rb (modified)
  ✓ lib/formatter.rb (modified)
  ✓ test/processor_test.rb (modified)
  ✓ test/analyzer_test.rb (modified)
✓ Successfully staged 5 files

Generating commit message...
✓ Message generated based on changes

Committing changes...
ℹ Pre-commit hook applied formatting to 2 files
  - lib/processor.rb (formatted)
  - lib/analyzer.rb (formatted)
✓ Committed successfully: def5678 style: format code

Note: Pre-commit hooks modified files during commit.
All changes have been included in the commit.
```

### Scenario 4: No Changes to Commit

**Goal:** Inform user when there are no changes

**Commands:**
```bash
$ ace-git-commit
```

**Expected Output:**
```
Analyzing repository status...
✓ Working directory clean

No changes to commit.

Status:
  - No modified files
  - No staged changes
  - No untracked files

Tip: Use 'git status' to see current repository state
```

### Scenario 5: Large File Warning

**Goal:** Warn about large files before staging

**Commands:**
```bash
$ ace-git-commit -i "feat: add video assets"
```

**Expected Output:**
```
Analyzing repository status...
Found 3 new files, 1 modified file

⚠ Warning: Large files detected:
  - assets/demo.mp4 (125 MB)
  - assets/tutorial.mov (89 MB)

Staging all changes...
  ✓ docs/video-guide.md (modified)
  ⚠ assets/demo.mp4 (new) - Large file (125 MB)
  ⚠ assets/tutorial.mov (new) - Large file (89 MB)
  ✓ assets/thumbnail.png (new)
✓ Successfully staged 4 files (including 2 large files)

Note: Consider using Git LFS for large files.
Run 'git lfs track "*.mp4" "*.mov"' to set up LFS tracking.

Generating commit message...
✓ Message generated based on changes

Committing changes...
✓ Committed successfully: ghi9012 feat: add video assets
```

### Scenario 6: Mixed Staged/Unstaged Changes

**Goal:** Clarify what will be committed when there are mixed changes

**Commands:**
```bash
$ ace-git-commit -i "fix: update API endpoints"
```

**Expected Output:**
```
Analyzing repository status...

Current status:
  Staged changes (2 files):
    - api/users.rb (modified)
    - api/auth.rb (modified)

  Unstaged changes (3 files):
    - api/posts.rb (modified)
    - api/comments.rb (modified)
    - test/api_test.rb (modified)

Staging all unstaged changes...
  ✓ api/posts.rb (modified)
  ✓ api/comments.rb (modified)
  ✓ test/api_test.rb (modified)
✓ Successfully staged 3 additional files

Ready to commit:
  - api/users.rb (was already staged)
  - api/auth.rb (was already staged)
  - api/posts.rb (newly staged)
  - api/comments.rb (newly staged)
  - test/api_test.rb (newly staged)

Generating commit message...
✓ Message generated based on all 5 files

Committing changes...
✓ Committed successfully: jkl3456 fix: update API endpoints
```

## Command Reference

### Basic Commands

```bash
# Commit all changes with generated message
ace-git-commit

# Commit with inline message
ace-git-commit -i "fix: resolve issue"

# Commit with full message
ace-git-commit -m "fix: resolve authentication issue

This commit addresses the login timeout problem by:
- Extending session duration
- Adding retry logic
- Improving error messages"

# Commit only currently staged files
ace-git-commit --staged

# Stage and commit specific files
ace-git-commit -f app/model.rb,test/model_test.rb
```

### Output Control

```bash
# Quiet mode (errors only)
ace-git-commit -q

# Verbose mode (default)
ace-git-commit -v

# Debug mode (detailed output)
ace-git-commit -d
```

### Internal Implementation

The tool internally uses:
- `git add -A` for staging all changes
- `git add <files>` for specific file staging
- `git diff --cached` to verify staged changes
- `git status --porcelain` to analyze repository state
- `git commit -m` to create the commit

## Tips and Best Practices

1. **Always review output**: The tool now shows exactly what's being staged
2. **Handle failures promptly**: Error messages include specific fix suggestions
3. **Use --staged for safety**: When unsure, commit only pre-staged files
4. **Check large files**: Tool warns about files over 50MB
5. **Understand pre-commit hooks**: Modifications by hooks are noted, not errors

## Migration from Legacy Behavior

### Key Differences

| Legacy Behavior | New Behavior |
|-----------------|--------------|
| Silent staging failures | Clear error messages with file names |
| Debug-only status messages | Staging status visible by default |
| Generic "Error" on success | Accurate success/failure indicators |
| No guidance on failures | Actionable suggestions provided |
| Pre-commit hook changes shown as errors | Shown as informational notes |

### Transition Guide

1. **Verbosity**: The tool is now verbose by default. Use `-q` for quiet mode if needed.
2. **Error handling**: Staging failures now stop the process immediately rather than continuing silently.
3. **Status visibility**: You'll see more information about what's happening - this is intentional for transparency.
4. **Pre-commit hooks**: Messages about file modifications by hooks are informational, not errors.

## Troubleshooting

### Common Issues and Solutions

**Issue:** "Failed to stage changes - Permission denied"
- **Solution:** Check file permissions with `ls -la`, fix with `chmod`

**Issue:** "No changes to commit" despite having modifications
- **Solution:** Check `.gitignore`, ensure files aren't ignored

**Issue:** "Pre-commit hook failed"
- **Solution:** This is from your git hooks, not ace-git-commit. Check `.git/hooks/pre-commit`

**Issue:** Large file warnings
- **Solution:** Consider using Git LFS or excluding large files from version control

**Issue:** Partial staging failures
- **Solution:** Tool lists which files failed and why, address each individually