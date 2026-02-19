---
name: git/create-pr
allowed-tools: Bash, Read
description: Create pull requests with structured templates and best practices
argument-hint: "[pr-type]"
doc-type: workflow
purpose: pull request creation workflow
update:
  frequency: on-change
  last-updated: '2025-11-11'
---

# Pull Request Creation Workflow

## Purpose

Create well-documented pull requests using structured templates and GitHub CLI, ensuring comprehensive PR descriptions that facilitate effective code review.

## Context

Creating quality PRs requires:
- Clear description of changes and motivation
- Testing information and validation steps
- Proper labeling and reviewer assignment
- Consistent format across team

This workflow uses:
- **Primary**: GitHub CLI (`gh`) for PR creation
- **Templates**: Structured PR templates for different change types
- **Best practices**: Checklist-driven PR quality

## Variables

- `$pr_type`: Type of PR (feature, bugfix, default) - determines template
- `$target_branch`: Target branch for PR (default: main)
- `$draft`: Whether to create as draft PR (default: false)

## Instructions

### 1. Pre-PR Verification

Ensure branch is ready for PR:

```bash
# Verify you're on feature branch
git branch --show-current

# Check all changes are committed
git status

# Review commits that will be in PR
git log origin/$target_branch..HEAD --oneline

# Verify tests pass
bundle exec rake test
# Or: npm test, make test, etc.
```

**Checklist**:
- [ ] All changes committed
- [ ] Tests pass locally
- [ ] CHANGELOG.md updated (if applicable)
- [ ] Documentation updated
- [ ] No sensitive data in commits

### 2. Determine Target Branch

**Use worktree metadata** (preferred method):

```bash
# Find the task spec file (stored in _current/ directory)
task_file=$(ls _current/*.s.md 2>/dev/null | head -1)

if [ -n "$task_file" ]; then
  # Try yq first (fastest), then Ruby fallback (guaranteed available)
  if command -v yq >/dev/null 2>&1; then
    # yq can read YAML frontmatter from markdown files
    target_branch=$(yq eval --front-matter=extract '.worktree.target_branch // "main"' "$task_file" 2>/dev/null || echo "main")
  else
    # Ruby fallback - extract YAML frontmatter and parse
    target_branch=$(ruby -ryaml -e '
      content = File.read(ARGV[0])
      if content.start_with?("---")
        frontmatter = content.split("---", 3)[1]
        data = YAML.safe_load(frontmatter, permitted_classes: [Date])
        puts data.dig("worktree", "target_branch") || "main"
      else
        puts "main"
      end
    ' "$task_file" 2>/dev/null || echo "main")
  fi
else
  echo "Warning: No task file found in _current/, defaulting target to main" >&2
  target_branch="main"
fi

# Verify the target branch exists (either locally or on remote)
if ! git show-ref --verify --quiet "refs/heads/$target_branch" && \
   ! git show-ref --verify --quiet "refs/remotes/origin/$target_branch"; then
  echo "Warning: Target branch '$target_branch' not found, using 'main'" >&2
  target_branch="main"
fi
```

This method:
- Uses the `target_branch` saved when worktree was created (in task spec frontmatter)
- Automatically set to parent's branch for subtasks
- Falls back to `main` for orchestrator tasks or when metadata unavailable
- Most reliable for task-aware workflows
- Uses Ruby fallback when `yq` is not available (Ruby guaranteed in ACE environment)

**Legacy detection method** (fallback):

```bash
ace-taskflow status
```

**Target Branch Rules:**

| Task Type | Example | Target Branch |
|-----------|---------|---------------|
| Subtask (has Parent Task) | `140.10` | Parent task branch `140-*` |
| Main task (no parent) | `140` | `main` |
| No task context | - | `main` |

**Detection from taskflow status** (when metadata unavailable):

If `ace-taskflow status` shows "Parent Task" section:
1. Get parent task ID (e.g., `140` from `v.0.9.0+task.140`)
2. Find branch matching `<parent-id>-*` pattern
3. Use as target branch

```bash
# Check if subtask has parent (using JSON for robustness)
parent_id=$(ace-taskflow status --json | jq -r '.parent_task.id // empty' | sed 's/.*\.//')

# Find parent branch if parent exists
if [ -n "$parent_id" ]; then
  target_branch=$(git branch -r | grep -E "origin/${parent_id}-" | head -1 | sed 's/origin\///' | xargs)
fi
```

**Important:** Always verify target branch exists before creating PR.

### 3. Push Branch

```bash
# Push feature branch to origin
git push -u origin $(git branch --show-current)

# Verify push succeeded
git status
```

### 4. Select PR Template

Choose template based on change type:

- **feature**: New functionality or enhancements
- **bugfix**: Bug fixes and corrections
- **default**: General changes, refactoring, docs

Templates available via ace-git package:
- `handbook/templates/pr/feature.template.md`
- `handbook/templates/pr/bugfix.template.md`
- `handbook/templates/pr/default.template.md`

### 5. Create PR with GitHub CLI

**PR Title Format:**

When `ace-git status` shows a task pattern, use task ID prefix:

| Context | Title Format | Example |
|---------|--------------|---------|
| Has task pattern | `<task-id>: <description>` | `140.10: Add PR activity awareness` |
| No task pattern | `<type>(<scope>): <description>` | `feat(auth): Add OAuth support` |

This keeps PR titles consistent with task tracking and PR Activity display.

#### Option A: Interactive Creation

```bash
# GitHub CLI interactive mode
gh pr create --fill

# Or with template (using ace-nav protocol)
gh pr create --fill --body "$(ace-nav template://ace-git/handbook/templates/pr/feature.template.md)"
```

#### Option B: Command Line with Template

For **feature PR**:

```bash
gh pr create \
  --title "feat: add user authentication system" \
  --body "$(cat <<'EOF'
## Summary

Implemented OAuth2-based authentication system with session management.

### What Changed
- Added OAuth2 authentication flow
- Implemented session management
- Created user profile endpoints
- Added authentication middleware

### Why This Change
- Required for user-specific features
- Improves security over basic auth
- Enables third-party integrations

## Implementation Details

### New Components
- `lib/auth/oauth.rb` - OAuth2 flow implementation
- `lib/auth/session.rb` - Session management
- `lib/middleware/auth.rb` - Authentication middleware

### Modified Components
- `config/routes.rb` - Added auth routes
- `app/models/user.rb` - Added OAuth fields

### Configuration
- New env vars: `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`
- Updated `.env.example` with auth config

## Testing

### Test Coverage
- Unit tests for auth module (95% coverage)
- Integration tests for OAuth flow
- Manual testing with Google OAuth

### Test Commands
\`\`\`bash
bundle exec rake test:auth
bundle exec rake test:integration
\`\`\`

### Manual Testing Steps
1. Start server: `rails server`
2. Navigate to `/auth/login`
3. Complete OAuth flow
4. Verify session persistence

## Documentation

- Updated README.md with auth setup
- Added API documentation for auth endpoints
- Created authentication guide in docs/

## Checklist

- [x] Tests pass locally
- [x] Tests added for new functionality
- [x] Documentation updated
- [x] CHANGELOG.md updated
- [x] No breaking changes
- [ ] Security review completed
- [ ] Performance tested

## Breaking Changes

None

## Migration Required

No database migrations needed. Configuration only:
\`\`\`bash
cp .env.example .env
# Add OAuth credentials
\`\`\`
EOF
)" \
  --base main \
  --head feature/user-authentication
```

For **bugfix PR**:

```bash
gh pr create \
  --title "fix: resolve memory leak in session store" \
  --body "$(cat <<'EOF'
## Problem

Memory leak in session store causing increased memory usage over time.

### Symptoms
- Memory usage grows continuously
- Server requires frequent restarts
- Performance degrades after ~1000 sessions

### Root Cause
Session cleanup not triggered properly. Expired sessions remained in memory.

## Solution

Implemented automatic session cleanup with configurable interval.

### Changes Made
- Added background cleanup task
- Implemented LRU cache for sessions
- Added session expiry monitoring

### Files Changed
- `lib/session_store.rb` - Added cleanup logic
- `config/initializers/session.rb` - Configured cleanup interval
- `lib/tasks/session_cleanup.rake` - Manual cleanup task

## Testing

### Reproduction Steps (Before Fix)
1. Create 1000+ sessions
2. Monitor memory usage
3. Observe continuous growth

### Verification (After Fix)
1. Run with fix: `SESSION_CLEANUP_INTERVAL=60 rails server`
2. Create 1000+ sessions
3. Memory usage stabilizes after cleanup runs

### Test Results
- Memory usage stable after 2000 sessions
- Cleanup runs every 60 seconds
- No performance impact

## Checklist

- [x] Tests pass locally
- [x] Root cause identified
- [x] Fix verified
- [x] No breaking changes
- [x] Documentation updated
EOF
)" \
  --base main \
  --label bug
```

#### Option C: Using Template File

```bash
# Create PR body from template file
gh pr create \
  --title "feat: implement feature X" \
  --body-file pr-description.md \
  --base main
```

### 6. Set PR Properties

After creation, enhance PR with additional metadata:

```bash
# Add reviewers
gh pr edit --add-reviewer @teammate1,@teammate2

# Add labels
gh pr edit --add-label "enhancement,needs-review"

# Add to project
gh pr edit --add-project "Q4 Release"

# Add milestone
gh pr edit --milestone "v2.0.0"

# Convert to draft if needed
gh pr ready --undo
```

### 7. Link Issues

```bash
# Link PR to issue (closes issue when PR merges)
gh pr edit --body "$(gh pr view --json body -q .body)

Closes #123"

# Or edit PR description manually to add:
# Fixes #123
# Resolves #456
```

### 8. Verify PR

```bash
# View PR in terminal
gh pr view

# Open PR in browser
gh pr view --web

# Check CI status
gh pr checks
```

## Alternative Methods

### GitLab

```bash
# Push with MR creation
git push -u origin feature-branch \
  -o merge_request.create \
  -o merge_request.title="feat: feature title" \
  -o merge_request.description="Description here"

# Or use GitLab CLI
glab mr create --fill
```

### Bitbucket

```bash
# Push branch
git push -u origin feature-branch

# Create PR via Bitbucket CLI
bb pr create --title "feat: feature" --source feature-branch
```

### Manual (Web Interface)

1. Push branch: `git push -u origin feature-branch`
2. Open repository in browser
3. Click "Create Pull Request"
4. Fill in template manually
5. Set reviewers and labels

## Draft PR Workflow

For work-in-progress PRs:

```bash
# Create as draft
gh pr create --draft \
  --title "WIP: implementing feature X" \
  --body "Early draft for discussion. Not ready for review."

# Continue pushing commits
git push

# Mark ready when complete
gh pr ready
```

## PR Templates

Templates are embedded in ace-git gem at:
- `handbook/templates/pr/default.template.md`
- `handbook/templates/pr/feature.template.md`
- `handbook/templates/pr/bugfix.template.md`

### Override Templates

Create local templates in `.ace/templates/pr/`:

```bash
# Copy default template
mkdir -p .ace/templates/pr
cat > .ace/templates/pr/custom.template.md <<'EOF'
## Summary
[Your custom template structure]
EOF
```

## Configuration

Place in `.ace/git/config.yml`:

```yaml
git:
  default_branch: main
  pr:
    template: default      # Default template to use
    draft: false          # Create as draft by default
    reviewers: []         # Auto-assign reviewers
    labels: []            # Auto-add labels
    auto_link_issues: true  # Auto-detect issue references
```

## Success Criteria

- ✓ PR created successfully
- ✓ Comprehensive description provided
- ✓ Reviewers assigned
- ✓ Appropriate labels added
- ✓ CI checks triggered
- ✓ Issues linked (if applicable)

## Troubleshooting

**Problem**: `gh` command not found

**Solution**: Install GitHub CLI:
```bash
# macOS
brew install gh

# Linux
sudo apt install gh

# Authenticate
gh auth login
```

**Problem**: Branch not pushed

**Solution**:
```bash
git push -u origin $(git branch --show-current)
gh pr create
```

**Problem**: PR creation fails with "no commits between base and head"

**Solution**: Ensure you have commits:
```bash
git log origin/$target_branch..HEAD
# If empty, add commits first
```

**Problem**: Template not found

**Solution**: Use inline body or verify template path:
```bash
# Inline body instead of template
gh pr create --title "..." --body "..."
```

## Best Practices

1. **Small, Focused PRs**: One feature/fix per PR
2. **Clear Titles**: Use conventional commit prefixes (feat:, fix:, docs:)
3. **Comprehensive Description**: Answer what, why, how
4. **Test Evidence**: Show that changes work
5. **Review-Ready**: Pass tests, no conflicts, clean commits
6. **Responsive**: Address feedback promptly

## Response Template

**PR Created:** [URL]
**PR Number:** #[number]
**Title:** [PR title]
**Type:** [feature/bugfix/docs]
**Reviewers:** [@user1, @user2]
**Status:** ✓ Created | 🔄 Draft | ✗ Failed
**CI Checks:** [Pass/Running/Failed]

<documents>
<template path="ace-git/handbook/templates/pr/feature.template.md">
## Summary

[Brief description of the new feature]

### What Changed
- [New functionality added]
- [Components created]
- [Integration points]

### Why This Feature
- [User need or business requirement]
- [Problem this feature solves]
- [Value it provides]

## Implementation Details

### New Components
- [File/module path] - [Purpose and responsibility]
- [File/module path] - [Purpose and responsibility]

### Modified Components
- [File/module path] - [Changes made and why]
- [File/module path] - [Changes made and why]

### Architecture Decisions
- [Key architectural decision]
- [Alternative considered and why rejected]

### Configuration
- [New configuration options]
- [Environment variables added]
- [Default values]

## Testing

### Test Coverage
- Unit tests: [Coverage percentage]
- Integration tests: [What's covered]
- End-to-end tests: [Scenarios tested]

### Test Commands
```bash
# Run all tests
bundle exec rake test

# Run feature-specific tests
bundle exec rake test:feature_name
```

### Manual Testing Steps
1. [Setup step]
2. [Action to perform]
3. [Expected result]
4. [Verification step]

## Documentation

- [ ] README updated with feature description
- [ ] API documentation generated/updated
- [ ] Usage examples provided
- [ ] Configuration documented
- [ ] CHANGELOG.md updated

## Performance Impact

[Describe any performance implications, or state "No significant impact"]

- [Metric]: [Before] → [After]
- [Load time/memory/etc]: [Impact]

## Security Considerations

[Describe security implications, or state "No security concerns"]

- [Security aspect]: [How it's handled]

## Checklist

- [ ] Tests pass locally
- [ ] Tests added for new functionality
- [ ] Code follows project style guidelines
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No breaking changes (or documented below)
- [ ] Performance tested
- [ ] Security reviewed

## Breaking Changes

[If there are breaking changes, describe them in detail. Otherwise, state "None"]

## Migration Required

[If users need to take action, describe migration steps. Otherwise, state "No migration needed"]

```bash
# Migration commands if needed
```

## Screenshots / Examples

[If applicable, add screenshots or usage examples]

```ruby
# Code example showing feature usage
```

## Related Issues

Closes #[issue-number]
Refs #[related-issue]
</template>

<template path="ace-git/handbook/templates/pr/bugfix.template.md">
## Summary

[Description of the bug and what was fixed]

### Bug Description
- [What was the bug]
- [How it manifested]
- [Impact on users]

### Root Cause
- [Underlying cause of the bug]
- [Why it wasn't caught earlier]

## Fix Details

### Changes Made
- [File/module path] - [Changes made and why]
- [File/module path] - [Changes made and why]

### Fix Approach
- [Strategy used to fix]
- [Alternative approaches considered]

## Testing

### Bug Reproduction
```bash
# Steps to reproduce the bug (before fix)
```

### Fix Verification
```bash
# Commands to verify the fix works
```

### Test Coverage
- Unit tests: [Coverage percentage]
- Regression tests: [What's covered]

### Manual Testing Steps
1. [Setup step]
2. [Reproduce bug]
3. [Apply fix]
4. [Verify resolution]

## Risk Assessment

### Potential Side Effects
- [Potential impact areas]
- [Components that might be affected]

### Rollback Plan
- [How to revert if needed]
- [Data migration considerations]

## Documentation

- [ ] Bug documented in known issues
- [ ] Fix documented in release notes
- [ ] API documentation updated
- [ ] CHANGELOG.md updated

## Checklist

- [ ] Bug reproduced and understood
- [ ] Fix tested locally
- [ ] Regression tests added
- [ ] No new bugs introduced
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Breaking changes documented (if any)
- [ ] Rollback plan tested

## Breaking Changes

[If there are breaking changes, describe them in detail. Otherwise, state "None"]

## Related Issues

Fixes #[issue-number]
Refs #[related-issue]
</template>

<template path="ace-git/handbook/templates/pr/default.template.md">
## Summary

[Brief description of changes]

## Changes

### What Changed
- [Change 1]
- [Change 2]
- [Change 3]

### Why
- [Reason for change 1]
- [Reason for change 2]

## Testing

- [ ] Tests pass locally
- [ ] Manual testing completed
- [ ] No regressions identified

## Checklist

- [ ] Code reviewed
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No breaking changes (or documented)

## Additional Notes

[Any additional context or notes]
</template>
</documents>
