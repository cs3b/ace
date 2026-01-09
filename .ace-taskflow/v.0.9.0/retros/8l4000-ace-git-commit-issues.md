# Retro: ace-git-commit Usage Issues

**Date:** 2025-10-05
**Topic:** Issues with ace-git-commit staging all changes by default
**Type:** Tool Usage Issue
**Duration:** Immediate observation

## What Happened

Used ace-git-commit to commit ace-review refactoring changes, but the tool staged ALL changes in the monorepo by default, including:
1. Test session files that should be gitignored (`ace-review/.ace-review-sessions/*`)
2. Unrelated changes from another package (`ace-nav/lib/ace/nav/molecules/protocol_scanner.rb`)

## The Problem

### 1. Unintended Files Committed
- **ace-review/.ace-review-sessions/**: Contains 29 test session files (100K+ lines)
  - These are temporary/test files that shouldn't be in version control
  - Should have been in .gitignore
- **ace-nav changes**: The protocol_scanner.rb file had unrelated changes
  - These changes were from a different work context
  - Should not be part of the ace-review refactoring commit

### 2. Root Cause: ace-git-commit Defaults
- ace-git-commit stages ALL changes by default (monorepo-friendly behavior)
- No warning when committing large numbers of untracked files
- No confirmation when including changes from multiple packages

## What Should Have Happened

### Better Approach
1. **Review staged files carefully** before accepting the commit
2. **Add .gitignore entries** BEFORE creating test files
3. **Use selective staging** for multi-package changes:
   ```bash
   # Option 1: Stage only ace-review changes
   ace-git-commit ace-review/

   # Option 2: Use --only-staged and stage manually first
   git add ace-review/
   ace-git-commit --only-staged
   ```

### Preventive Measures
1. **Create .gitignore first**:
   ```bash
   echo ".ace-review-sessions/" >> ace-review/.gitignore
   ```

2. **Review dry-run output more carefully**:
   - Check the file list, not just the message
   - Look for unexpected packages/paths
   - Verify file count makes sense

## Immediate Actions Needed

### 1. Add .gitignore Entry
```bash
echo ".ace-review-sessions/" >> /Users/mc/Ps/ace-meta/ace-review/.gitignore
git add ace-review/.gitignore
git commit -m "chore(ace-review): Add .gitignore for test sessions"
```

### 2. Consider Reverting or Amending
Since the commit is local (not pushed):
- Could amend to remove unwanted files
- Could create follow-up commit to clean up
- Document the issue for future reference

## Key Learnings

### 1. ace-git-commit Behavior
- **Default is ALL changes** - designed for monorepo workflows
- **Dry-run shows files** - must review the file list, not just message
- **No safeguards** for large file counts or cross-package commits

### 2. Development Workflow
- **Always add .gitignore entries** before creating test/temp files
- **Review staged files** carefully with dry-run
- **Use path-specific commits** when working on single package

### 3. Tool Design Considerations
ace-git-commit could benefit from:
- Warning when staging 10+ new untracked files
- Warning when staging files from multiple top-level directories
- Option to confirm file list before committing
- Integration with .gitignore patterns

## Recommendations

### For ace-git-commit Usage
1. **Always use --dry-run first** and review file list
2. **Use path arguments** to limit scope: `ace-git-commit path/`
3. **Pre-stage with git add** then use `--only-staged`
4. **Check for .gitignore** before creating test files

### For Tool Improvements
1. Add warning thresholds (e.g., >10 new files)
2. Add cross-package detection and confirmation
3. Add --interactive mode for file selection
4. Consider .gitignore awareness

### For Project Setup
1. Create comprehensive .gitignore at project start
2. Use .gitignore templates for common patterns
3. Document which paths should be ignored

## Impact Assessment

**Severity:** Medium
- No data loss or security issue
- Creates noisy git history
- Increases repo size unnecessarily
- May confuse future developers

**Recovery:** Straightforward
- Can be cleaned up with follow-up commits
- Local only, not pushed to remote
- Learning opportunity for better practices

## Session Metrics

- **Unintended Files Committed:** 30+ files
- **Unintended Lines Added:** 100,000+ lines
- **Packages Affected:** 2 (ace-review, ace-nav)
- **Commit Size:** 105K insertions (mostly test data)

---

*This retro captures issues with ace-git-commit's default behavior of staging all changes in a monorepo context.*