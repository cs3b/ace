# ace-git Package Usage

## Overview

The ace-git gem provides three essential git workflow instructions for developers and AI agents. It's a workflow-first package without executable commands, designed to guide through complex git operations with best practices.

Available workflows (via ace-nav protocol):
- **`wfi://rebase`**: Changelog-preserving rebase operations
- **`wfi://create-pr`**: Pull request creation with templates
- **`wfi://squash-pr`**: Version-based commit squashing

## Installation

```bash
# Install the gem
gem install ace-git

# Or add to Gemfile
gem 'ace-git', '~> 0.1.0'
```

## Protocol Registration

The package registers with ace-nav for seamless workflow and template discovery:

```bash
# Access workflows via ace-nav
ace-nav wfi://rebase          # Opens rebase workflow
ace-nav wfi://create-pr       # Opens PR creation workflow
ace-nav wfi://squash-pr       # Opens squash workflow

# Templates are accessible via template:// protocol
# (resolved by ace-support-core)
```

## Configuration

Minimal configuration for user preferences only. Place in `.ace/git/config.yml`:

```yaml
# .ace/git/config.yml - Minimal, preferences only
git:
  default_branch: main  # Your preferred main branch name
  remote: origin       # Your preferred remote name
  verbose: false       # Optional: verbose output
```

Note: Workflows contain sensible defaults inline. Configuration is only for user preferences, not behavior control.

## Usage Scenarios

### Scenario 1: Rebase with Changelog Preservation

**Goal**: Rebase feature branch against main while preserving CHANGELOG.md entries

**Claude Code Command**:
```
/ace:git-rebase
```

**Manual Steps**:
```bash
# 1. Check current status
git status
git log --oneline -5

# 2. Create backup of important files
cp CHANGELOG.md CHANGELOG.md.backup

# 3. Start rebase
git fetch origin
git rebase origin/main

# 4. If conflicts in CHANGELOG.md:
# - Accept both changes
# - Manually merge entries chronologically
# - Preserve version headers

# 5. Continue rebase
git add CHANGELOG.md
git rebase --continue

# 6. Verify preservation
diff CHANGELOG.md.backup CHANGELOG.md
```

### Scenario 2: Create Pull Request with Template

**Goal**: Create a well-formatted PR using template:// protocol templates

**Access Workflow**:
```bash
ace-nav wfi://create-pr
```

**GitHub CLI with Template** (workflow will guide through):
```bash
# 1. Ensure branch is pushed
git push -u origin feature-branch

# 2. Workflow references template://pr/feature for feature PRs
# User can override by creating .ace/templates/pr/feature.template.md

# 3. Create PR using resolved template
gh pr create \
  --title "feat: add new authentication system" \
  --body "$(ace-nav template://pr/feature | tail -n +2)"

# Or with inline template expansion:
gh pr create \
  --title "feat: add new authentication system" \
  --body "$(cat <<'EOF'
## Summary
- Implemented OAuth2 authentication
- Added session management
- Created user profile endpoints

## Changes
- New auth module in lib/auth/
- Updated user model with OAuth fields
- Added authentication middleware

## Testing
- Unit tests for auth module
- Integration tests for OAuth flow
- Manual testing with Google OAuth

## Checklist
- [x] Tests pass locally
- [x] Documentation updated
- [x] CHANGELOG.md updated
- [ ] Security review completed
EOF
)"

# 4. Set additional properties
gh pr edit --add-reviewer @teammate
gh pr edit --add-label "enhancement"
```

### Scenario 3: Squash Commits by Version

**Goal**: Clean up commit history by squashing all commits for v0.9.0 development

**Claude Code Command**:
```
/ace:squash-pr --version v.0.9.0
```

**Manual Interactive Steps**:
```bash
# 1. Identify version boundary commits
git log --oneline | grep -E "v\.[0-9]+\.[0-9]+\.[0-9]+"

# 2. Start interactive rebase from last release
git rebase -i v0.8.0

# 3. In editor, mark commits to squash:
# pick abc1234 chore: bump version to v0.9.0
# squash def5678 feat: add feature A
# squash ghi9012 fix: resolve bug B
# squash jkl3456 docs: update README

# 4. Create consolidated commit message:
# v0.9.0: Authentication and Performance Improvements
#
# Features:
# - OAuth2 authentication support
# - Session management
#
# Fixes:
# - Resolved memory leak in auth module
# - Fixed race condition in session store

# 5. Force push if needed (with caution)
git push --force-with-lease
```

### Scenario 4: Handle Complex Rebase Conflicts

**Goal**: Resolve multiple conflict types during rebase

**Steps**:
```bash
# 1. Start rebase
git rebase origin/main

# 2. Handle different conflict types:

# Version file conflict - keep feature branch version
git checkout --ours lib/ace/git/version.rb
git add lib/ace/git/version.rb

# CHANGELOG conflict - merge both
# Edit CHANGELOG.md manually to include both sets of entries

# Code conflict - merge semantically
# Edit conflicted files to preserve both functionalities

# 3. Continue after each resolution
git rebase --continue

# 4. If lost, check status
git rebase --abort  # Start over if needed
```

## Command Reference

### Workflow Access

Workflows are accessible via ace-nav protocol system:

```bash
# Direct workflow access
ace-nav wfi://rebase         # Rebase workflow
ace-nav wfi://create-pr      # PR creation workflow
ace-nav wfi://squash-pr      # Squash workflow

# Source-specific access (if multiple gems provide similar workflows)
ace-nav wfi://@ace-git/rebase

# List available workflows
ace-nav wfi:// --list
```

### Template Access

Templates use the template:// protocol (resolved by ace-support-core):

```bash
# Default templates provided
template://pr/default        # Default PR template
template://pr/feature        # Feature PR template
template://pr/bugfix         # Bugfix PR template
template://commit/squash     # Squashed commit template

# Override by creating local versions
.ace/templates/pr/default.template.md  # Local override
```

### Configuration

Minimal configuration in `.ace/git/config.yml`:

```yaml
git:
  default_branch: main  # Preferred main branch name
  remote: origin       # Preferred remote name
```

Note: Complex configuration removed - workflows contain sensible defaults inline.

## Tips and Best Practices

1. **Always backup before rebase**: Create copies of critical files like CHANGELOG.md
2. **Use draft PRs for WIP**: Set `pr.draft: true` for work-in-progress
3. **Squash before merging**: Clean history makes debugging easier
4. **Test after rebase**: Always run tests after rebasing to catch integration issues
5. **Document in PR description**: Use templates to ensure comprehensive PR documentation

## Troubleshooting

### Rebase Conflicts in CHANGELOG.md
- Accept both changes initially
- Manually reorganize entries by date/version
- Ensure version headers remain intact

### PR Creation Fails
- Verify branch is pushed: `git push -u origin branch-name`
- Check GitHub CLI auth: `gh auth status`
- Ensure you have repository permissions

### Squash Creates Huge Diff
- Break into smaller logical chunks
- Squash by feature rather than version if needed
- Use interactive mode for fine control

## Migration from Manual Workflows

If you've been using manual git workflows, ace-git provides:
- Structured approach to complex operations
- Consistent patterns across team
- Built-in best practices and safety checks
- Integration with other ace-* tools

Start with one workflow at a time and gradually adopt others as needed.