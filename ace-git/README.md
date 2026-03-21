---
doc-type: user
title: ace-git
purpose: Documentation for ace-git/README.md
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
---

# ace-git

Git workflow instructions for ACE projects - comprehensive guidance for rebase operations, PR creation, and commit reorganization.

## Overview

ace-git is a workflow-first gem that provides essential git workflows and context commands for developers and AI agents:

**CLI Commands:**
- **Status** (`ace-git status`): Repository context with branch, PR, and activity information
- **Diff** (`ace-git diff`): Smart diff with filtering and configuration
- **Branch** (`ace-git branch`): Current branch with tracking status
- **PR** (`ace-git pr`): PR metadata lookup

**Workflows:**
- **Rebase Workflow** (`wfi://git/rebase`): Changelog-preserving rebase operations
- **PR Creation Workflow** (`wfi://github/pr/create`): Pull request creation with structured templates
- **Reorganize Commits Workflow** (`wfi://git/reorganize-commits`): Reorganize commit history into logical groups

## Installation

Add to your Gemfile:

```ruby
gem 'ace-git', '~> 0.1.0'
```

Or install directly:

```bash
gem install ace-git
```

## Quick Start

### Access Workflows

Load workflows directly with `ace-bundle`:

```bash
# Rebase with changelog preservation
ace-bundle wfi://git/rebase

# Create pull request with template
ace-bundle wfi://github/pr/create

# Squash commits by version
ace-bundle wfi://git/reorganize-commits
```

Use `ace-nav` only for discovery or path lookup.

### Configuration (Optional)

Create `.ace/git/config.yml` for user preferences:

```yaml
git:
  default_branch: main  # Your preferred main branch
  remote: origin       # Your preferred remote name
```

Note: Workflows contain sensible defaults inline. Configuration is only for user preferences.

## Workflows

### 1. Rebase Workflow

Rebase feature branches while preserving CHANGELOG.md and version files.

**Access**: `ace-bundle wfi://git/rebase`

**Use Cases**:
- Update feature branch with latest main
- Resolve conflicts in CHANGELOG.md
- Preserve version bumps during rebase

**Key Features**:
- Automatic CHANGELOG.md conflict resolution
- Version file preservation strategies
- Recovery procedures for failed rebases

### 2. PR Creation Workflow

Create well-documented pull requests using structured templates.

**Access**: `ace-bundle wfi://github/pr/create`

**Use Cases**:
- Create feature PRs with comprehensive descriptions
- Document bug fixes with root cause analysis
- Generate PRs with consistent format across team

**Templates Available**:
- `feature.template.md` - New features and enhancements
- `bugfix.template.md` - Bug fixes with reproduction steps
- `default.template.md` - General changes and refactoring

**Example**:
```bash
# GitHub CLI with template
gh pr create \
  --title "feat: add authentication" \
  --body "$(ace-nav template://pr/feature)"
```

### 3. Reorganize Commits Workflow

Reorganize commits into logical groups for clean, maintainable history.

**Access**: `ace-bundle wfi://git/reorganize-commits`

**Use Cases**:
- Clean up feature branch history before merge
- Organize commits by version/milestone
- Create atomic commits for releases

**Strategies**:
- **Version-based**: One commit per version (recommended)
- **Interactive**: Manual control over squashing
- **Logical grouping**: Group by feature/fix

## Templates

Templates are accessible via template:// protocol:

```bash
# PR templates
template://pr/default
template://pr/feature
template://pr/bugfix

# Commit templates
template://commit/squash
```

### Override Templates

Create local templates in `.ace/templates/`:

```bash
mkdir -p .ace/templates/pr
cat > .ace/templates/pr/custom.template.md <<'EOF'
## Your Custom Template
...
EOF
```

## Usage Examples

### Example 1: Feature Branch Rebase

```bash
# 1. Access workflow
ace-bundle wfi://git/rebase

# 2. Follow guided steps
git fetch origin
cp CHANGELOG.md CHANGELOG.md.backup
git rebase origin/main

# 3. Resolve CHANGELOG conflicts (guided by workflow)
# Accept both changes, merge chronologically

# 4. Verify and push
git push --force-with-lease
```

### Example 2: Create Feature PR

```bash
# 1. Push branch
git push -u origin feature/authentication

# 2. Create PR with template
gh pr create \
  --title "feat: OAuth2 authentication" \
  --body "$(cat handbook/templates/pr/feature.template.md)"

# 3. Add metadata
gh pr edit --add-reviewer @teammate
gh pr edit --add-label "enhancement"
```

### Example 3: Squash by Version

```bash
# 1. Access workflow
ace-bundle wfi://git/reorganize-commits

# 2. Identify version boundary
git log --oneline | grep "v0.9.0"

# 3. Squash commits
git reset --soft v0.8.0
git commit -m "v0.9.0: Authentication and performance improvements

## Features
- OAuth2 authentication
- Session management

## Fixes
- Memory leak resolved
- Performance optimization"

# 4. Force push if needed
git push --force-with-lease
```

## Configuration Reference

Minimal configuration in `.ace/git/config.yml`:

```yaml
git:
  # General preferences
  default_branch: main
  remote: origin
  verbose: false

  # Optional: Rebase preferences
  # rebase:
  #   preserve_files:
  #     - CHANGELOG.md
  #     - "**/version.rb"

  # Optional: PR preferences
  # pr:
  #   template: default
  #   draft: false
  #   reviewers: []

  # Optional: Squash preferences
  # squash:
  #   strategy: version
  #   interactive: false
```

## Integration

### Claude Code

Workflows are automatically available in Claude Code via handbook integration:

```bash
# Workflows accessible through ace-nav
/ace-bundle wfi://git/rebase
```

### Other ACE Tools

Works seamlessly with:
- **ace-git-commit**: Commit message generation
- **ace-git-worktree**: Worktree management
- **ace-taskflow**: Version and task management

## Requirements

- Ruby >= 3.2.0
- Git >= 2.23.0 (for `--force-with-lease` and modern rebase features)
- GitHub CLI (optional, for PR creation workflow)
- ace-support-core ~> 0.10 (installed automatically)

## Development

```bash
# Clone repository
git clone https://github.com/cs3b/ace.git
cd ace/ace-git

# Install dependencies
bundle install

# Build gem
gem build ace-git.gemspec

# Install locally
gem install ace-git-0.1.0.gem
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Run tests (if added)
5. Submit pull request

## License

MIT License. See LICENSE file for details.

## Related Projects

- [ace-support-core](../ace-support-core) - Core configuration and utilities
- [ace-git-commit](../ace-git-commit) - Commit message generation
- [ace-git-worktree](../ace-git-worktree) - Worktree management
- [ace-taskflow](../ace-taskflow) - Task and version management
- [ace-nav](../ace-nav) - Protocol-based resource navigation

## Support

- Issues: https://github.com/cs3b/ace/issues
- Documentation: See workflow files in `handbook/workflow-instructions/`

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.
