---
name: squash-pr
allowed-tools: Bash, Read
description: Squash commits by version for clean, maintainable history
argument-hint: "[version]"
doc-type: workflow
purpose: version-based commit squashing workflow
update:
  frequency: on-change
  last-updated: '2026-01-11'
---

# Version-Based Commit Squashing Workflow

## Purpose

Squash multiple commits into cohesive, logical commits for clean, maintainable git history. Group related changes together - this often means 2-5 commits rather than one, making history easier to understand, review, and revert if needed.

## Context

**Problem**: Development branches accumulate many small commits:
- Work-in-progress commits
- Fix commits
- Review feedback commits
- Documentation updates

**Solution**: Squash related commits into cohesive logical groups:
- **Prefer 2-5 logical commits** over one massive commit
- Group by: feature work, configuration/review fixes, unrelated changes
- Clear commit messages with consolidated changes
- Preserved CHANGELOG entries
- Easier to understand, review, and revert if needed

**Use Cases**:
- Preparing feature branch for merge
- Cleaning up development history
- Organizing commits by version/milestone
- Creating atomic commits for releases

## Variables

- `$version`: Version to squash (e.g., v0.9.0, v.0.9.0) - auto-detected by default
- `$base_commit`: Starting point for squash (default: last version tag)
- `$strategy`: Squashing strategy (version, manual, interactive)
- `$pr_number`: PR number when squashing for a specific PR

## Prerequisites - PR Base Detection

> ⚠️ **CRITICAL**: Before squashing ANY PR, you MUST determine the correct base commit.
> Do NOT assume `origin/main` is the correct base - PRs can be based on feature branches!

### Step 0: Run ace-git status (REQUIRED FIRST STEP)

```bash
ace-git status
```

This shows the PR's target branch clearly:
```
## Current PR

#102 [OPEN] 159: Extract ace-support-fs gem...
  Target: 157-extract-ace-config-gem-from-ace-support-core | Author: @cs3b
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
         THIS is your base branch, NOT origin/main!
```

**If Target is NOT `main`**: Your PR depends on another PR. Use `origin/<target-branch>` as your squash base.

### Step 1: Get PR's Base Branch

```bash
# Get the PR's target base branch (NOT always main!)
PR_NUMBER=<your-pr-number>
base_ref=$(gh pr view $PR_NUMBER --json baseRefName -q '.baseRefName')
echo "PR is based on: $base_ref"

# If base_ref is NOT 'main', this PR likely depends on another PR
if [ "$base_ref" != "main" ]; then
  echo "⚠️ WARNING: This PR is based on '$base_ref', not 'main'"
  echo "Verify parent PR is merged before proceeding!"
fi
```

### Step 2: Find Correct Merge Base

```bash
# Find the merge-base with the PR's actual base branch
git fetch origin $base_ref
base_commit=$(git merge-base HEAD origin/$base_ref)
echo "Squash base commit: $base_commit"
```

### Step 3: Verify Commit Scope

```bash
# Show commits that WILL be squashed - review carefully!
echo "=== Commits to be squashed ==="
git log --oneline $base_commit..HEAD

# Count commits
commit_count=$(git rev-list --count $base_commit..HEAD)
echo "Total commits to squash: $commit_count"
```

### Step 4: Check for Parent PRs

```bash
# Check if PR body mentions dependencies
gh pr view $PR_NUMBER --json body -q '.body' | grep -oE 'Depends on: #[0-9]+' || echo "No dependencies found"

# If parent PR exists, verify it's merged before proceeding
# The parent's merge commit should be your base_commit
```

**WARNING**: If `base_ref` is NOT `main`, the PR likely depends on another PR.
Always verify the parent PR is merged before squashing the child PR.

## Instructions

### 1. Analyze Current History

Understand what needs squashing:

```bash
# View commit history
git log --oneline --graph

# Find version boundary commits
git log --oneline | grep -E "v\.?[0-9]+\.[0-9]+\.[0-9]+"

# Count commits since last version
git rev-list --count HEAD ^$(git describe --tags --abbrev=0)

# View commits since specific version
git log v0.8.0..HEAD --oneline
```

### 2. Identify Version Boundaries

> ⚠️ **IMPORTANT**: If you're squashing a PR, run the **Prerequisites - PR Base Detection** section first!
> The methods below assume you're squashing to `main`, which may not be correct for all PRs.

#### Auto-detect Version (Recommended)

```bash
# Find last version tag
last_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
echo "Last version: $last_version"

# If no tags, find version bump commit
if [ -z "$last_version" ]; then
  last_version=$(git log --oneline | grep -E "bump|version" | head -1 | awk '{print $1}')
fi

# Count commits to squash
commits_to_squash=$(git rev-list --count HEAD ^$last_version)
echo "Commits to squash: $commits_to_squash"
```

#### Manual Version Specification

```bash
# Specify version explicitly
version="v0.9.0"
base_commit=$(git log --oneline | grep "$version" | head -1 | awk '{print $1}')
```

### 3. Prepare Squash Commit Message

Analyze commits to create comprehensive message:

```bash
# Extract commit messages
git log $base_commit..HEAD --format="- %s"

# Group by type (feat, fix, docs, etc.)
git log $base_commit..HEAD --format="%s" | \
  awk '{if ($0 ~ /^feat/) print "Feature: " $0;
        else if ($0 ~ /^fix/) print "Fix: " $0;
        else if ($0 ~ /^docs/) print "Docs: " $0;
        else print "Other: " $0}' | sort

# Identify breaking changes
git log $base_commit..HEAD --format="%B" | grep -i "BREAKING"
```

### 4. Perform Squash

> **RECOMMENDED**: Use **Method A (Soft Reset + Path-Based Staging)** for most PRs.
> This method gives you full control over commit organization and generates messages automatically with `ace-git-commit`.

#### Method A: Soft Reset + Path-Based Staging (Recommended)

**Best for**: Most PRs, multi-package changes, when you want logical commit organization

```bash
# Step 1: Soft reset to base (keeps all changes staged)
git reset --soft $base_commit

# Step 2: Reset all staging - we'll stage manually by path
git reset HEAD

# Step 3: Stage and commit by logical path groups

# Generic pattern:
# git add <new-files-or-dirs>/ <deleted-files-or-dirs>/
# ace-git-commit paths --intention "describe the logical change"

# Example: ace-config rename organized by package

# Commit 1: The renamed gem itself (new dir + deleted dir)
# NOTE: Adding the OLD directory (ace-config/) stages the DELETIONS
git add ace-support-config/ ace-config/
ace-git-commit paths --intention "rename ace-config to ace-support-config gem for naming consistency"
# CRITICAL: Verify after each commit!
git status  # Should show only unstaged files for next commit(s)

# Commit 2: Core dependency (delegation)
git add ace-support-core/lib/ ace-support-core/test/
ace-git-commit paths --intention "delegate config to Ace::Support::Config namespace"
git status

# Commit 3: Dependent gem - ace-bundle
git add ace-bundle/lib/ ace-bundle/test/ ace-bundle/ace-bundle.gemspec
ace-git-commit paths --intention "update for ace-config rename"
git status

# Continue for each package...
# Commit N: Monorepo files
git add Gemfile Gemfile.lock .ace/test/suite.yml
ace-git-commit paths --intention "update dependencies for renamed gem"
git status  # Should be clean (only untracked files)
```

**Why this is better:**
- Full control over commit organization by package/path
- `ace-git-commit` generates appropriate messages based on actual changes
- `--intention` provides context for the change
- Verification after each commit catches issues immediately
- No complex rebase conflicts

> ⚠️ **WARNING: Glob Patterns in Fish/Zsh**
>
> Shell globs may not expand as expected in fish/zsh:
>
> ```bash
> # BAD - May fail silently or expand incorrectly:
> git add */gemspec
> git add ace-*/lib/
>
> # GOOD - Use explicit paths or find:
> find . -maxdepth 2 -name "*.gemspec" -exec git add {} +
> # OR list packages explicitly:
> git add ace-bundle/ace-bundle.gemspec ace-docs/ace-docs.gemspec ...
> ```

#### Method B: Interactive Rebase (Advanced)

**Best for**: Complex rebase operations, preserving specific commits, advanced users

```bash
# Start interactive rebase from base commit
git rebase -i $base_commit

# Editor opens with commits:
# pick abc1234 chore: bump version to v0.9.0
# pick def5678 feat: add feature A
# pick ghi9012 feat: add feature B
# pick jkl3456 fix: resolve bug X
# pick mno7890 docs: update README
# pick pqr1234 fix: typo in feature A

# Change to squash/fixup strategy:
# pick abc1234 chore: bump version to v0.9.0
# squash def5678 feat: add feature A
# squash ghi9012 feat: add feature B
# fixup jkl3456 fix: resolve bug X
# fixup mno7890 docs: update README
# fixup pqr1234 fix: typo in feature A

# Save and close editor - will prompt for commit message
```

**squash vs fixup:**
- `squash` - combines commit into previous, prompts to edit combined message (use for meaningful commits)
- `fixup` - combines commit into previous, discards the message (use for typo fixes, WIP commits)

**Note**: Method B is more complex and can lead to conflicts. Use Method A for most cases.

### 4.1. Verification Checklist (CRITICAL)

> ⚠️ **After EACH commit, you MUST verify:**

```bash
# 1. Check git status - should show clean or only next package's files
git status

# 2. Verify commit contains expected files
git show --stat HEAD

# 3. Repeat for EACH commit!
```

**Why this matters**: If you skip verification, you might miss files (like the ace-config deletions that weren't staged in our incident).

### 5. Craft Consolidated Commit Message

Use structured format:

```
v[X.Y.Z]: [Brief Summary of Version]

## Features
- List of new features
- With clear descriptions
- One per line

## Fixes
- Bug fixes
- With issue references
- Clear impact statement

## Documentation
- Doc updates
- Guide additions
- README improvements

## Technical Details
- Implementation notes
- Architecture changes
- Performance improvements

## Breaking Changes
- Any breaking changes
- Migration requirements
- Deprecation notices

## Dependencies
- New dependencies added
- Updated dependencies
- Removed dependencies

Refs: #123, #456
Co-authored-by: Name <email>
```

### 6. Handle CHANGELOG Preservation

Ensure CHANGELOG entries aren't lost:

```bash
# Before squashing, extract CHANGELOG entries
git show HEAD:CHANGELOG.md > CHANGELOG.current.md

# After squashing, verify CHANGELOG is intact
diff CHANGELOG.current.md CHANGELOG.md

# If entries lost, manually restore
cat CHANGELOG.current.md
# Manually add missing entries to CHANGELOG.md
```

### 7. Verify Squashed Commit

```bash
# Check history
git log --oneline -5

# Verify changes included
git show HEAD --stat

# Ensure CHANGELOG intact
cat CHANGELOG.md | head -50

# Run tests
bundle exec rake test
```

### 8. Pre-Push Verification (CRITICAL)

> ⚠️ **Before force pushing, verify everything is correct:**

```bash
# 1. Check git status - should be clean (only untracked files)
git status
# Expected: "nothing to commit, working tree clean" (except untracked files)

# 2. Verify all squashed commits
git log $base_commit..HEAD --oneline
# Count should match your intended number of commits

# 3. Verify file count matches expectations
git diff --stat $base_commit..HEAD
# Compare with original: git diff --stat $base_commit@{1} HEAD@{1}

# 4. Run tests for affected packages
ace-test  # or bundle exec rake test
```

**If any verification fails:**
- Use `git reflog` to find the pre-squash state
- `git reset --hard HEAD@{n}` to go back
- Fix issues and retry

### 9. Force Push (If Needed)

```bash
# If squashing published commits (use with caution!)
git push --force-with-lease origin $(git branch --show-current)

# Verify remote state
git fetch origin
git log origin/$(git branch --show-current) -5 --oneline
```

## Squashing Strategies

> **RECOMMENDED**: Use **Logical Grouping** for most PRs.
> Squashing to a single commit loses valuable context about what changed and why.
> Example: 16 commits → 3 logical commits (features, fixes, unrelated work)

### Strategy 1: Logical Grouping (Recommended)

**Best for**: Most PRs, feature branches, multi-topic work

Group commits by logical concern rather than squashing everything into one:

```bash
# Analyze commits by type
git log $base_commit..HEAD --format="%s" | sort

# Common groupings:
# 1. Core feature commits → single "feat:" commit
# 2. Review/fix commits → single "chore:" or "fix:" commit
# 3. Unrelated changes → keep separate

# Use merge --squash for each group
git checkout -b squash-temp $base_commit
git merge --squash <last-commit-of-group-1>
git commit -m "feat: Core feature implementation"
git merge --squash <last-commit-of-group-2>
git commit -m "chore: Review fixes and configuration"
# ... continue for each group
```

**Why this is better:**
- Preserves logical separation of concerns
- Easier to review, understand, and revert
- Cherry-picking specific changes remains possible
- History tells a coherent story

### Strategy 2: Commit Per Feature

**Best for**: PRs with multiple independent features

```bash
# Keep one commit per major feature
# Squash only WIP and fix commits within each feature

# Example result:
# feat: OAuth authentication (squashed from 5 WIP commits)
# feat: Session management (squashed from 3 commits)
# docs: API documentation updates
```

### Strategy 3: One Commit Per Version

**Best for**: Simple PRs, single-feature work, release tags

```bash
# Squash all commits since last version tag
last_tag=$(git describe --tags --abbrev=0)
git reset --soft $last_tag
git commit -m "v0.9.0: Complete feature set for Q4 release

[Comprehensive list of changes]"
```

**When to use**: Only when all commits are tightly related to a single logical change.

### Real-World Example: PR #72 (16 → 3 commits)

**Before** (16 commits):
```
feat: Rename done → _archive (131.02)
feat: Rename backlog → _backlog (131.04)
feat: Implement undone command (131.03)
feat: Add _parked folder support (131.07)
feat: Add migrate command (131.05)
feat: Add _deferred folder support (131.06)
chore: Archive task 131
fix: PR review critical items
fix: PR review high/medium/low items
chore: Configure Ruby tool
feat: ADR-022 config pattern
feat: Implement ADR-022
refactor: Remove fallback constant
fix: PR review items + bump version
fix: undone command crash
chore: Create task 154
```

**After** (3 logical commits):
```
1. feat(taskflow): v0.23.0 - Folder reorganization and task lifecycle
   (All Task 131 feature work squashed together)

2. chore(taskflow): ADR-022 configuration pattern and PR review fixes
   (Config pattern + all review fixes + bug fixes)

3. chore(task-154): Create task for ace-test error message improvement
   (Unrelated work kept separate)
```

**Why 3 commits, not 1:**
- Commit 1: Core feature work (logical unit)
- Commit 2: Supporting work (config + fixes)
- Commit 3: Unrelated change (shouldn't be mixed with PR scope)

## Advanced Patterns

### Pattern: Selective Squashing

Squash only specific commit ranges:

```bash
# Squash commits 3-7, keep others
git rebase -i HEAD~10

# In editor:
# pick commit1
# pick commit2
# pick commit3
# squash commit4
# squash commit5
# squash commit6
# squash commit7
# pick commit8
```

### Pattern: Preserve Meaningful Commits

Keep important commits separate:

```bash
# Keep: version bumps, major features, breaking changes
# Squash: WIP, fixes, typos, minor tweaks

pick abc123 chore: bump version to v0.9.0
squash def456 WIP: initial auth implementation
squash ghi789 fix: auth bugs
pick jkl012 feat: complete authentication system
squash mno345 typo fix
pick pqr678 BREAKING: change auth API
```

### Pattern: Automated Squash Script

```bash
#!/bin/bash
# squash-by-version.sh

version=$1
if [ -z "$version" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

# Find base commit
base=$(git log --oneline | grep "$version" | head -1 | awk '{print $1}')

# Generate message from commits
message=$(cat <<EOF
$version: Development Milestone

$(git log $base..HEAD --format="- %s" | sort | uniq)
EOF
)

# Perform squash
git reset --soft $base
git commit -m "$message"

echo "✓ Squashed to commit: $(git rev-parse --short HEAD)"
```

## Recovery Procedures

### Undo Squash

```bash
# Find pre-squash state in reflog
git reflog | head -20

# Reset to before squash
git reset --hard HEAD@{1}

# Or use SHA
git reset --hard <commit-before-squash>
```

### Fix Squash Mistakes

```bash
# Amend squashed commit
git commit --amend

# Edit commit message
git commit --amend -m "New message"

# Add missed files
git add forgotten-file
git commit --amend --no-edit
```

## Configuration

Place in `.ace/git/config.yml`:

```yaml
git:
  squash:
    strategy: version        # version, manual, interactive
    interactive: false       # Use interactive mode
    preserve_messages: true  # Keep commit messages in squashed commit
    auto_detect_version: true  # Auto-detect version from tags/commits
```

## Success Criteria

- ✓ Commits squashed successfully
- ✓ Clear, comprehensive commit message
- ✓ CHANGELOG entries preserved
- ✓ Tests still pass
- ✓ History is cleaner and more maintainable
- ✓ No lost changes

## Troubleshooting

**Problem**: Lost commits after squash

**Solution**: Use reflog to recover:
```bash
git reflog
git reset --hard HEAD@{n}  # n = before squash
```

**Problem**: CHANGELOG entries missing

**Solution**: Restore from backup:
```bash
git show HEAD@{1}:CHANGELOG.md > CHANGELOG.md
```

**Problem**: Tests fail after squash

**Solution**: Squash didn't lose changes, but may have introduced conflicts:
```bash
# Check diff from before squash
git diff HEAD@{1} HEAD

# Fix test issues
# Amend squashed commit
git add .
git commit --amend --no-edit
```

**Problem**: Can't force push

**Solution**: Use force-with-lease:
```bash
git push --force-with-lease origin branch-name
# This fails if remote changed, protecting against overwrites
```

**Problem**: "index.lock" or "Unable to create index" errors

**Solution**: Git operation was interrupted, leaving a lock file:
```bash
# Remove lock files from main git dir
rm -f .git/index.lock

# For worktrees, also remove worktree lock
rm -f /path/to/worktree/.git/index.lock
rm -f /path/to/main/repo/.git/worktrees/worktree-name/index.lock

# Then retry your command
```

**Root cause**: This happens when a git command is interrupted (Ctrl+C, error, crash). The lock file prevents concurrent git operations from corrupting the index.

## Best Practices

1. **Squash Before Merge**: Clean history before PR merge
2. **Test After Squash**: Always run tests post-squash
3. **Preserve CHANGELOG**: Don't lose documentation
4. **Comprehensive Messages**: Include all relevant changes
5. **Use force-with-lease**: Safer than force push
6. **Communicate**: Tell team before force pushing shared branches

## Response Template

**Squash Status:** ✓ Complete | ⚠ Conflicts | ✗ Aborted
**Commits Squashed:** [Number of commits]
**Version:** [v0.9.0]
**Base Commit:** [SHA]
**Message Preview:** [First line of commit message]
**Tests Status:** [Pass/Fail]
**Next Steps:** [Force push, continue work, etc.]

<documents>
<template path="ace-git/handbook/templates/commit/squash.template.md">
v[X.Y.Z]: [Brief Summary of Version]

## Features
- [New feature description]
- [Another feature]
- [Feature with details]

## Fixes
- [Bug fix description]
- [Another fix with issue reference #123]
- [Performance fix]

## Documentation
- [Documentation updates]
- [Guide additions]
- [README improvements]

## Technical Details
- [Implementation notes]
- [Architecture changes]
- [Refactoring performed]

## Breaking Changes
[List any breaking changes, or state "None"]

- [Breaking change description]
- [Migration required]

## Dependencies
- Added: [new-dependency] v[X.Y] - [reason]
- Updated: [dependency] [old-version] → [new-version]
- Removed: [deprecated-dependency] - [reason]

## Performance
- [Performance improvement description]
- [Metric]: [before] → [after]

## Security
- [Security fix or improvement]
- [Vulnerability addressed]

## Migration Notes
[If users need to take action, describe steps. Otherwise, state "No migration required"]

```bash
# Migration commands if needed
```

Refs: #[issue], #[issue]
Co-authored-by: [Name] <[email]>
</template>
</documents>
