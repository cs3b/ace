---
name: rebase
allowed-tools: Bash, Read
description: Rebase feature branch with automatic CHANGELOG.md and version file preservation
argument-hint: "[target-branch]"
doc-type: workflow
purpose: changelog-preserving rebase workflow
update:
  frequency: on-change
  last-updated: '2025-11-11'
---

# Changelog-Preserving Rebase Workflow

## Purpose

Rebase feature branches against target branch (default: main/master) while automatically preserving CHANGELOG.md entries and version file changes to prevent loss of important documentation and version tracking.

## Context

Common rebase problems this workflow solves:
- CHANGELOG.md conflicts that lose feature branch entries
- Version file conflicts that revert version bumps
- Manual conflict resolution introducing errors
- Lost commit messages during rebase

## Variables

- `$target_branch`: Branch to rebase against (default: origin/main or origin/master)
- `$preserve_files`: Files to preserve from feature branch (defaults: CHANGELOG.md, **/version.rb)

## Instructions

### 1. Pre-Rebase Verification

Check current repository state:

```bash
# Verify you're on the correct feature branch
git status

# Check what files have changed
git diff $target_branch --name-only

# Preview commits that will be rebased
git log $target_branch..HEAD --oneline
```

**Verify**:
- You're on a feature branch (not main/master)
- No uncommitted changes (or stash them: `git stash push -m "pre-rebase"`)
- You have the changes you expect to preserve

### 2. Backup Critical Files

Create backups of files that might conflict:

```bash
# Backup CHANGELOG.md if it exists
if [ -f CHANGELOG.md ]; then
  cp CHANGELOG.md CHANGELOG.md.backup
  echo "✓ Backed up CHANGELOG.md"
fi

# Backup version files
find . -name "version.rb" -type f | while read file; do
  cp "$file" "$file.backup"
  echo "✓ Backed up $file"
done
```

### 3. Fetch Latest Changes

```bash
# Fetch latest from origin without merging
git fetch origin

# Verify target branch is up to date
git log HEAD..$target_branch --oneline
```

### 4. Start Rebase

```bash
# Start interactive rebase for full control
git rebase -i $target_branch

# Or automatic rebase
git rebase $target_branch
```

### 5. Handle Conflicts

#### CHANGELOG.md Conflicts

When conflicts occur in CHANGELOG.md:

```bash
# Open CHANGELOG.md and look for conflict markers
# <<<<<<< HEAD (their changes - target branch)
# =======
# >>>>>>> commit-message (your changes - feature branch)

# Strategy: Accept both changes
git checkout --ours CHANGELOG.md      # Get feature branch version
git checkout --theirs CHANGELOG.md && cp CHANGELOG.md CHANGELOG.md.theirs  # Save target branch version temporarily

# Manual merge: Combine both CHANGELOGs
# 1. Keep version headers from feature branch
# 2. Merge entries chronologically
# 3. Preserve all significant changes from both branches
```

**CHANGELOG.md Merge Pattern**:
```markdown
# Changelog

## [Unreleased]
### Added (from feature branch)
- New feature A
- New feature B

### Fixed (from target branch)
- Bug fix from main branch

## [Previous Versions]
(existing entries)
```

**After resolving**:
```bash
git add CHANGELOG.md
git rebase --continue
```

#### Version File Conflicts

For version.rb or similar version files:

```bash
# Usually keep feature branch version (your changes)
git checkout --ours lib/ace/gem/version.rb
git add lib/ace/gem/version.rb
git rebase --continue
```

#### Code Conflicts

For actual code conflicts:

```bash
# Review conflicts
git status

# Edit each conflicted file to resolve
# Remove conflict markers: <<<<<<<, =======, >>>>>>>
# Keep semantically correct combination

# After resolving each file
git add <resolved-file>

# Continue rebase
git rebase --continue
```

### 6. Verify Preservation

After rebase completes:

```bash
# Check CHANGELOG.md has all your entries
diff CHANGELOG.md CHANGELOG.md.backup
grep -A 5 "Unreleased" CHANGELOG.md

# Verify version files kept feature branch versions
find . -name "version.rb" -type f | while read file; do
  echo "=== $file ==="
  cat "$file"
done

# Check commit history
git log --oneline -10
```

### 7. Run Tests

```bash
# Run project tests to verify functionality
bundle exec rake test
# Or: npm test, make test, etc.

# Fix any test failures
# Tests catching integration issues is normal after rebase
```

### 8. Clean Up

```bash
# Remove backup files
rm -f CHANGELOG.md.backup
find . -name "version.rb.backup" -delete

# Force push if rebasing published branch (use with caution!)
git push --force-with-lease origin $(git branch --show-current)
```

## Recovery Procedures

### Abort Rebase

If things go wrong:

```bash
# Abort rebase and return to pre-rebase state
git rebase --abort

# Restore from backups if needed
cp CHANGELOG.md.backup CHANGELOG.md
```

### Resume After Interruption

If rebase was interrupted:

```bash
# Check rebase status
git status

# Skip problematic commit (use carefully)
git rebase --skip

# Or continue after resolving conflicts
git add <resolved-files>
git rebase --continue
```

### Lost Commit Recovery

If commits seem lost after rebase:

```bash
# Find lost commits in reflog
git reflog | head -20

# Cherry-pick lost commit
git cherry-pick <commit-hash>
```

## Common Patterns

### Pattern: Rebase Against Main

```bash
# Full workflow
git fetch origin
cp CHANGELOG.md CHANGELOG.md.backup
git rebase origin/main
# Resolve conflicts preserving CHANGELOG entries
git add CHANGELOG.md
git rebase --continue
diff CHANGELOG.md CHANGELOG.md.backup
git push --force-with-lease
```

### Pattern: Interactive Rebase for Cleanup

```bash
# Rebase and squash/reorder commits
git rebase -i origin/main
# In editor: pick, squash, reword commits as needed
# Preserve CHANGELOG.md during conflicts
```

### Pattern: Rebase with Autostash

```bash
# Automatically stash uncommitted changes
git rebase --autostash origin/main
# Your changes are restored after rebase
```

## Configuration

Place in `.ace/git/config.yml`:

```yaml
git:
  default_branch: main  # or master
  remote: origin
  rebase:
    preserve_files:
      - CHANGELOG.md
      - "**/version.rb"
      - VERSION
    auto_resolve: manual  # or 'ours' to auto-keep feature branch files
```

## Success Criteria

- ✓ Feature branch rebased on target branch
- ✓ CHANGELOG.md contains all entries from both branches
- ✓ Version files retain feature branch versions
- ✓ All tests pass
- ✓ No lost commits
- ✓ Clean commit history

## Troubleshooting

**Problem**: CHANGELOG.md conflicts on every commit

**Solution**: Squash feature branch commits first, then rebase:
```bash
git rebase -i HEAD~5  # Squash your commits
git rebase origin/main  # Now only one CHANGELOG conflict
```

**Problem**: Lost feature branch CHANGELOG entries

**Solution**: Restore from backup:
```bash
cp CHANGELOG.md.backup CHANGELOG.md
# Manually merge with target branch CHANGELOG
git add CHANGELOG.md
git rebase --continue
```

**Problem**: Version file shows wrong version

**Solution**: Force feature branch version:
```bash
git checkout --ours lib/ace/gem/version.rb
git add lib/ace/gem/version.rb
git rebase --continue
```

## Response Template

**Rebase Status:** ✓ Complete | ⚠ Conflicts | ✗ Aborted
**Target Branch:** [origin/main, origin/master, etc.]
**Conflicts Resolved:** [CHANGELOG.md, version.rb, code files]
**Commits Rebased:** [Number of commits]
**Tests Status:** [Pass/Fail]
**Next Steps:** [Force push, continue work, etc.]

<documents>
<!-- Rebase workflow doesn't reference external templates but includes self-contained examples -->
</documents>
