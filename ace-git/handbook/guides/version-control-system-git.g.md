---
doc-type: guide
title: Version Control System Git Guide
purpose: Documentation for ace-git/handbook/guides/version-control-system-git.g.md
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
---

# Version Control System Git Guide

## Purpose

This guide provides comprehensive documentation for Git-specific version control operations and workflows. It focuses on Git command patterns, branching strategies, collaboration workflows, and troubleshooting procedures while complementing the [Version Control Message Guide](./version-control-system-message.g.md) for commit formatting standards.

## Git Workflow Fundamentals

### Repository Structure

This project uses a **mono-repo architecture** with all packages at the repository root:

- **ace-*/**: Ruby gems for specific functionality (ace-git, ace-task, ace-docs, etc.)
- **docs/**: Project documentation and architecture decisions
- **.ace-task/**: Task management and release coordination
- **_legacy/**: Archived content from previous multi-repo structure

#### Common Git Commands

```bash
# Check repository status
git status

# View recent activity
git log --oneline -10

# Commit with conventional message
git commit -m "feat(package): description"

# Push to remote
bin/gp

# Coordinated pull across all repositories
bin/gpull
```

### Basic Git Operations

#### Repository Setup

```bash
# Clone with submodules
git clone --recursive <repository-url>

# Initialize submodules in existing repository
git submodule update --init --recursive

# Check submodule status
git submodule status
```

#### Working with Changes

```bash
# Check repository status
git status

# Review changes
git diff                    # Unstaged changes
git diff --staged          # Staged changes
git diff HEAD              # All changes
git diff commit1..commit2  # Between commits
```

## Branching Strategies

### Branch Naming Conventions

Follow consistent naming patterns for different types of work:

```bash
# Feature development
git checkout -b feature/user-authentication
git checkout -b feature/search-functionality

# Bug fixes
git checkout -b fix/login-validation
git checkout -b fix/memory-leak

# Documentation updates
git checkout -b docs/api-documentation
git checkout -b docs/setup-guide

# Refactoring work
git checkout -b refactor/service-layer
git checkout -b refactor/error-handling
```

### Branch Lifecycle

#### Creating and Working on Branches

```bash
# Create and switch to new branch
git checkout -b feature/new-feature

# Work on changes (edit files, run tests)
# Stage and commit following message standards
git add .
git commit -m "feat(auth): add user login functionality"

# Keep branch updated with main
git fetch origin
git rebase origin/main

# Push branch for collaboration
git push -u origin feature/new-feature
```

#### Merging Strategies

**Fast-Forward Merge** (preferred for simple changes):

```bash
git checkout main
git pull origin main
git merge feature/simple-fix
git push origin main
```

**Squash Merge** (for feature branches with multiple commits):

```bash
git checkout main
git pull origin main
git merge --squash feature/complex-feature
git commit -m "feat(feature): implement complex feature functionality"
git push origin main
```

**Merge Commit** (for preserving branch history):

```bash
git checkout main
git pull origin main
git merge --no-ff feature/important-feature
git push origin main
```

### Long-Running Branches

#### Main Branch Protection

- **Never force push to main**
- **Always pull before pushing**
- **Ensure tests pass before merging**
- **Use pull requests for code review**

#### Branch Cleanup

```bash
# List merged branches
git branch --merged

# Delete local merged branches
git branch -d feature/completed-feature

# Delete remote branches
git push origin --delete feature/completed-feature

# Prune deleted remote branches
git remote prune origin
```

## Collaboration Workflows

### Pull Request Process

#### Creating Pull Requests

1. **Push your branch**:

   ```bash
   git push -u origin feature/your-feature
   ```

2. **Create PR through GitHub interface** or CLI:

   ```bash
   gh pr create --title "feat(feature): add new functionality" \
                --body "Description of changes..."
   ```

3. **Link to relevant issues/tasks**:

   ```markdown
   Implements #task-id
   Fixes #issue-number
   ```

#### Code Review Integration

**Before requesting review**:

```bash
# Run quality checks
bin/test
bin/lint
bin/build

# Update with latest changes
git fetch origin
git rebase origin/main

# Force push if rebased (use with caution)
git push --force-with-lease origin feature/your-feature
```

### Team Collaboration Patterns

#### Fork-Based Workflow

For external contributors:

```bash
# Fork repository on GitHub, then:
git clone https://github.com/your-username/project.git
cd project

# Add upstream remote
git remote add upstream https://github.com/original/project.git

# Stay updated with upstream
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

#### Conflict Resolution in Teams

**Prevention strategies**:

- Communicate about overlapping work areas
- Keep branches short-lived and focused
- Rebase frequently against main branch
- Coordinate changes to shared files

**Resolution process**:

```bash
# When conflicts occur during merge/rebase
git status  # See conflicted files

# Edit files to resolve conflicts
# Remove conflict markers: <<<<<<<, =======, >>>>>>>

# Stage resolved files
git add resolved-file.js

# Continue rebase or complete merge
git rebase --continue
# or
git commit
```

## Advanced Git Operations

### Interactive Rebase

**Cleaning up commit history**:

```bash
# Rebase last 3 commits interactively
git rebase -i HEAD~3

# Options during interactive rebase:
# pick = use commit
# reword = change commit message
# edit = stop for amending
# squash = combine with previous commit
# fixup = like squash but discard message
# drop = remove commit
```

**Example interactive rebase session**:

```bash
# Before: messy commit history
# fix typo
# add feature
# fix another typo
# add tests

# After interactive rebase:
# feat(feature): add new feature with tests
```

### Cherry-Picking

**Applying specific commits to other branches**:

```bash
# Apply commit from another branch
git cherry-pick <commit-hash>

# Apply range of commits
git cherry-pick <start-commit>..<end-commit>

# Cherry-pick without committing (for review)
git cherry-pick --no-commit <commit-hash>
```

### Git Stash

**Temporarily saving work**:

```bash
# Stash current changes
git stash

# Stash with message
git stash push -m "work in progress on feature"

# List stashes
git stash list

# Apply most recent stash
git stash pop

# Apply specific stash
git stash apply stash@{1}

# Drop stash
git stash drop stash@{0}
```

## Submodule Management

### Working with Submodules

**Updating submodules**:

```bash
# Update all submodules to latest commits
git submodule update --remote

# Update specific submodule
git submodule update --remote shared-handbook

# Commit submodule updates
git add .gitmodules shared-handbook shared-taskflow shared-tools
git commit -m "chore(submodules): update to latest versions"
```

**Working within submodules**:

```bash
# Make changes in submodule
cd shared-handbook
git checkout main
git pull origin main
# Make changes, commit as usual
git commit -m "docs: update guide"
git push origin main

# Return to main repo and update reference
cd ..
git add shared-handbook
git commit -m "chore(submodule): update shared-handbook reference"
```

### Multi-Repository Workflows

**Coordinated development across repositories**:

```bash
# Check status across all repos
git-status

# Make related changes in multiple repos
cd shared-handbook
# Edit guide files
git add . && git commit -m "docs: update workflow guide"

cd ../dev-taskflow
# Update task files
git add . && git commit -m "docs: update task status"

cd ..
# Update main repo references
git add .
git commit -m "chore: coordinate handbook and taskflow updates"

# Push all changes
bin/gp
```

## Git Hooks and Automation

### Pre-commit Hooks

**Validation before commits**:

```bash
#!/bin/sh
# .git/hooks/pre-commit

# Run tests
if ! bin/test; then
    echo "Tests failed. Commit aborted."
    exit 1
fi

# Run linting
if ! bin/lint; then
    echo "Linting failed. Commit aborted."
    exit 1
fi

echo "Pre-commit checks passed."
```

**Commit message validation**:

```bash
#!/bin/sh
# .git/hooks/commit-msg

commit_regex='^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
    echo "Invalid commit message format."
    echo "Please follow: <type>(<scope>): <subject>"
    echo "See: guides/version-control-system-message.g.md"
    exit 1
fi
```

### Automation Integration

**CI/CD Integration patterns**:

```yaml
# .github/workflows/main.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive
      
      - name: Run tests
        run: bin/test
      
      - name: Run linting
        run: bin/lint
```

## Release Management

### Semantic Versioning with Git Tags

**Creating releases**:

```bash
# Update version files
# Edit CHANGELOG.md with release notes

# Commit version changes
git add version.rb CHANGELOG.md
git commit -m "chore(release): prepare v1.2.0 publication"

# Create annotated tag
git tag -a v1.2.0 -m "Release v1.2.0 - Feature Release"

# Verify tag
git tag -l v1.2.0
git show v1.2.0

# Push release
git push origin main
git push origin v1.2.0
```

**Release branch workflow**:

```bash
# Create release branch
git checkout -b release/v1.2.0

# Finalize release changes
# Update versions, documentation
git commit -m "chore(release): finalize v1.2.0"

# Merge to main
git checkout main
git merge --no-ff release/v1.2.0
git tag -a v1.2.0 -m "Release v1.2.0"

# Clean up
git branch -d release/v1.2.0
git push origin main --tags
```

### Documentation Archival

**Archiving release documentation**:

```bash
# Move completed release docs
mv dev-taskflow/current/v1.2.0-release dev-taskflow/done/

# Commit archival
git add dev-taskflow/
git commit -m "chore(release): archive v1.2.0 documentation"

# Create new current release structure
mkdir -p dev-taskflow/current/v1.3.0-next
git add dev-taskflow/current/
git commit -m "chore(release): initialize v1.3.0 development"
```

## Troubleshooting Common Issues

### Merge Conflicts

**Identifying conflicts**:

```bash
# Check status during merge conflict
git status

# See which files have conflicts
git diff --name-only --diff-filter=U
```

**Resolving conflicts**:

```bash
# Manual resolution
# Edit files to remove conflict markers:
# <<<<<<< HEAD
# =======
# >>>>>>> branch-name

# Stage resolved files
git add resolved-file.js

# Continue merge or rebase
git rebase --continue
# or complete merge
git commit
```

**Aborting problematic merges**:

```bash
# Abort merge
git merge --abort

# Abort rebase
git rebase --abort

# Reset to clean state
git reset --hard HEAD
```

### Authentication Issues

**SSH key problems**:

```bash
# Test SSH connection
ssh -T git@github.com

# Add SSH key to agent
ssh-add ~/.ssh/id_rsa

# Check SSH agent
ssh-add -l
```

**HTTPS token issues**:

```bash
# Update stored credentials (macOS)
git config --global credential.helper osxkeychain

# Clear cached credentials
git config --global --unset credential.helper
git config --system --unset credential.helper
```

### Repository Corruption

**Checking repository integrity**:

```bash
# Check for corruption
git fsck --full

# Verify objects
git count-objects -v

# Clean up loose objects
git gc --aggressive
```

**Recovering lost commits**:

```bash
# Find lost commits
git reflog

# Recover commit
git checkout <commit-hash>
git checkout -b recovery-branch

# Or create new branch from reflog
git branch recovery <commit-hash>
```

### Large File Issues

**Identifying large files**:

```bash
# Find large files in history
git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  awk '/^blob/ {print substr($0,6)}' | \
  sort --numeric-sort --key=2 | \
  tail -20
```

**Git LFS setup**:

```bash
# Install Git LFS
git lfs install

# Track large file types
git lfs track "*.zip"
git lfs track "*.pdf"

# Add .gitattributes
git add .gitattributes
git commit -m "chore: configure Git LFS for large files"
```

### Performance Optimization

**Optimizing large repositories**:

```bash
# Clean up repository
git gc --aggressive --prune=now

# Enable partial clone for large repos
git clone --filter=blob:none <url>

# Shallow clone for CI
git clone --depth 1 <url>
```

**Submodule performance**:

```bash
# Parallel submodule updates
git submodule update --init --recursive --jobs 4

# Shallow submodule clones
git submodule update --init --recursive --depth 1
```

## Security and Compliance

### Signed Commits

**Setting up GPG signing**:

```bash
# Generate GPG key
gpg --gen-key

# List keys
gpg --list-secret-keys --keyid-format LONG

# Configure Git to use GPG key
git config --global user.signingkey <key-id>
git config --global commit.gpgsign true

# Sign commits
git commit -S -m "feat(security): add GPG signing"
```

### Sensitive Data Handling

**Preventing sensitive data commits**:

```bash
# Add to .gitignore
echo "*.env" >> .gitignore
echo "secrets/" >> .gitignore
echo "*.key" >> .gitignore

# Use git-secrets tool
git secrets --register-aws
git secrets --install
```

**Removing sensitive data from history**:

```bash
# Use git filter-branch (destructive)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/sensitive-file" \
  --prune-empty --tag-name-filter cat -- --all

# Use BFG Repo Cleaner (recommended)
bfg --delete-files sensitive-file.txt
git reflog expire --expire=now --all && git gc --prune=now --aggressive
```

### Access Control

**Repository permissions**:

- Use branch protection rules
- Require pull request reviews
- Enforce status checks
- Restrict push access to main branch

**Audit trails**:

```bash
# Review commit history
git log --author="user@example.com" --oneline

# Check file history
git log --follow -- path/to/file

# Review tag history
git for-each-ref --format="%(refname) %(taggerdate) %(taggername)" refs/tags
```

## Best Practices Summary

### Repository Hygiene

1. **Keep commits atomic**: One logical change per commit
2. **Write descriptive commit messages**: Follow [conventional commit standards](./version-control-system-message.g.md)
3. **Test before committing**: Run `bin/test` and `bin/lint`
4. **Keep branches focused**: One feature or fix per branch
5. **Clean up branches**: Delete merged branches regularly

### Collaboration Excellence

1. **Pull before pushing**: Always sync with remote changes
2. **Rebase for clean history**: Use interactive rebase to clean up commits
3. **Review code thoroughly**: Use pull requests for all changes
4. **Communicate conflicts**: Coordinate on overlapping work areas
5. **Document decisions**: Use commit messages to explain why, not just what

### Security and Compliance

1. **Never commit secrets**: Use environment variables and secure storage
2. **Sign important commits**: Use GPG signing for releases and security fixes
3. **Review history**: Regularly audit commits for sensitive information
4. **Use branch protection**: Protect main branches with required reviews
5. **Monitor access**: Track who has push access to critical branches

### Multi-Repository Coordination

1. **Use project scripts**: Leverage `git-commit`, `git-status`, `git-log` for coordination
2. **Coordinate related changes**: Update submodules and main repo together
3. **Test across repositories**: Ensure changes work across the full system
4. **Document cross-repo changes**: Explain relationships in commit messages
5. **Sync submodule updates**: Keep submodule references current

## Related Documents

- [Version Control Message Guide](./version-control-system-message.g.md) - Commit message formatting standards
- [Commit Workflow](../workflow-instructions/commit.wf.md) - Step-by-step commit process
- [Code Review Process](./code-review-process.g.md) - Review procedures and quality gates
- [Quality Assurance Guide](./quality-assurance.g.md) - Testing and validation standards

## Tools and Automation

### Project-Specific Commands

- `git-commit -i "intention"` - Multi-repository commit with contextual messages
- `git-status` - Status check across all repositories
- `git-log` - Unified log view across repositories
- `bin/gp` - Coordinated push to all repositories
- `bin/gpull` - Coordinated pull from all repositories

### Recommended Git Configuration

```bash
# Set up useful Git aliases
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.br "branch"
git config --global alias.ci "commit"
git config --global alias.unstage "reset HEAD --"
git config --global alias.last "log -1 HEAD"
git config --global alias.visual "!gitk"

# Configure line ending handling
git config --global core.autocrlf input

# Set default branch name
git config --global init.defaultBranch main

# Configure pull behavior
git config --global pull.rebase false
```

## References

- [Pro Git Book](https://git-scm.com/book) - Comprehensive Git documentation
- [GitHub Flow](https://guides.github.com/introduction/flow/) - Simplified branching workflow
- [Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials) - Visual Git learning resources
- [Conventional Commits](https://www.conventionalcommits.org/) - Commit message specification
