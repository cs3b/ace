# Commit Workflow Instruction

## Goal

Guide the developer through creating a well-structured, atomic Git commit following project conventions.

## Prerequisites

- Code changes have been implemented and tested
- Files related to a single logical change are ready to be staged
- Understanding of conventional commit format

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`

## High-Level Execution Plan

### Planning Steps

- Review and validate changes are ready for commit
- Verify all tests pass and code is linted
- Ensure changes represent a single logical unit

### Execution Steps

- Stage related changes appropriately
- Write conventional commit message following project standards
- Create the commit with proper message
- Update task status if applicable
- Push changes when ready

## Process Steps

1. **Review and Prepare Changes:**

   ```bash
   # View current status
   git status
   
   # Review unstaged changes
   git diff
   
   # Review specific file changes
   git diff path/to/file
   ```

   **Validation checklist:**
   - Changes relate to a single logical unit
   - New code has corresponding tests
   - All tests pass (`bin/test`)
   - Code has been linted (`bin/lint`)
   - No debugging code or temporary files included

2. **Stage Related Changes:**

   ```bash
   # Stage specific files
   git add path/to/file1 path/to/file2
   
   # Stage all changes in a directory
   git add path/to/directory/
   
   # Interactive staging for partial file changes
   git add -p
   ```

   **Review staged changes:**

   ```bash
   git diff --staged
   ```

3. **Write Conventional Commit Message:**

   **Format:**

   ```
   type(scope): subject
   
   [optional body]
   
   [optional footer(s)]
   ```

   **Types:**
   - `feat`: New feature
   - `fix`: Bug fix
   - `docs`: Documentation only
   - `style`: Formatting, missing semicolons, etc.
   - `refactor`: Code change that neither fixes nor adds feature
   - `test`: Adding missing tests
   - `chore`: Maintenance tasks, dependency updates

   **Examples:**

   ```bash
   # Simple commit
   git commit -m "feat(auth): add password reset functionality"
   
   # Commit with body
   git commit -m "fix(api): handle null values in user response
   
   - Add null checks for optional fields
   - Update tests to cover edge cases
   - Fix TypeScript types
   
   Fixes #123"
   ```

   **Guidelines:**
   - Subject line: 50 characters or less
   - Use imperative mood ("add" not "added")
   - Don't end subject with period
   - Separate subject from body with blank line
   - Body lines: 72 characters or less
   - Reference issues/tasks when applicable

4. **AI-Generated Code Review:**
   If changes were AI-assisted:
   - **Verify correctness**: Does it solve the intended problem?
   - **Check edge cases**: Are all scenarios handled?
   - **Review patterns**: Does it follow project conventions?
   - **Security check**: No credentials or vulnerabilities?
   - **Performance**: No obvious inefficiencies?

5. **Create the Commit:**

   ```bash
   # Commit with editor for detailed message
   git commit
   
   # Commit with inline message
   git commit -m "type(scope): description"
   
   # Amend last commit if needed
   git commit --amend
   ```

6. **Post-Commit Actions:**
   - Update task status if commit completes a task:

     ```yaml
     status: done
     ```

   - Push when ready:

     ```bash
     git push origin branch-name
     ```

   - Update any related documentation

## Commit Message Templates

### Feature Implementation

Use the feature implementation template for new functionality (see embedded template below).

### Bug Fix

Use the bug fix template for resolving issues (see embedded template below).

### Refactoring

Use the refactoring template for code improvements without functional changes (see embedded template below).

## Common Patterns

### Atomic Commits

Each commit should:

- Represent one logical change
- Be revertable without breaking functionality
- Include all related changes (code, tests, docs)
- Pass all tests independently

### Interactive Staging

For complex changes:

```bash
# Stage hunks interactively
git add -p

# Options:
# y - stage this hunk
# n - skip this hunk
# s - split into smaller hunks
# e - manually edit hunk
```

### Commit Series

When implementing a feature across multiple commits:

1. Infrastructure/setup commits first
2. Core implementation commits
3. Test commits
4. Documentation commits
5. Polish/cleanup commits

## Error Handling

### Common Issues

**Merge Conflicts During Commit:**

**Symptoms:**

- `git pull` fails with conflict markers
- Files contain `<<<<<<<`, `=======`, `>>>>>>>` markers
- Cannot proceed with commit

**Recovery Steps:**

1. Stop current operation: `git merge --abort` if in middle of merge
2. Review conflicted files: `git status`
3. For simple conflicts, resolve manually:

   ```bash
   # Edit conflicted files, remove markers, choose correct content
   git add resolved-file.ext
   git commit
   ```

4. For complex conflicts, escalate to user with clear description
5. Validate resolution: `git status` should show clean working tree

**Prevention:**

- Always `git pull` before making changes
- Check for upstream changes: `git fetch && git status`

**Pre-commit Hook Failures:**

**Symptoms:**

- `git commit` fails with hook error messages
- Lint, formatting, or test failures during commit
- Code style violations reported

**Recovery Steps:**

1. Read hook error message carefully
2. Fix identified issues:

   ```bash
   # Run linting
   bin/lint
   
   # Run tests
   bin/test
   
   # Fix any reported issues
   ```

3. Re-stage fixed files: `git add .`
4. Retry commit: `git commit`
5. If hook is incorrectly configured, ask user for guidance

**Prevention:**

- Run `bin/lint` before committing
- Run `bin/test` before committing
- Review quality standards in project documentation

**Authentication Failures:**

**Symptoms:**

- `git push` fails with 403/401 errors
- SSH key or token rejection
- Permission denied messages

**Recovery Steps:**

1. Check authentication status: `git remote -v`
2. Test connection: `ssh -T git@github.com`
3. Verify repository permissions
4. If token expired, ask user to refresh credentials
5. Document the issue for user resolution

**Prevention:**

- Test git authentication before starting: `git fetch`
- Verify push permissions for target repository

**File Path Issues:**

**Symptoms:**

- `git add` fails with "pathspec did not match"
- Files not staged as expected
- Untracked files not being added

**Recovery Steps:**

1. Verify file existence: `ls -la path/to/file`
2. Check current directory: `pwd`
3. Use `git status` to see actual file states
4. For renamed files, use `git add -A` to stage all changes
5. For new files, ensure proper paths and no typos

**Prevention:**

- Use `git status` to verify file states before staging
- Use tab completion for file paths
- Double-check file names and locations

**Large File Issues:**

**Symptoms:**

- Git warns about large files
- Push fails due to file size limits
- Performance degradation

**Recovery Steps:**

1. Identify large files: `git ls-files | xargs ls -la | sort -nr -k5`
2. Remove large files from staging: `git reset HEAD large-file.ext`
3. Add to .gitignore if appropriate
4. For legitimate large files, consider Git LFS
5. Ask user about file handling strategy

**Prevention:**

- Review file sizes before staging
- Use .gitignore for build artifacts and large binaries
- Consider Git LFS for necessary large files

**Accidentally Committed to Wrong Branch:**

**Symptoms:**

- Realized commit was made to incorrect branch
- Need to move commits to different branch

**Recovery Steps:**

```bash
# Create new branch with current commits
git branch new-branch

# Reset current branch
git reset --hard origin/main

# Switch to new branch
git checkout new-branch
```

**Need to Modify Last Commit:**

**Symptoms:**

- Typo in commit message
- Forgot to include file in commit
- Need to update commit content

**Recovery Steps:**

```bash
# Add more changes
git add files

# Amend without changing message
git commit --amend --no-edit

# Or change the message too
git commit --amend
```

**Committed Sensitive Data:**

**Symptoms:**

- Accidentally committed passwords, keys, or secrets
- Need to remove from git history

**Recovery Steps:**

```bash
# Remove from history (requires force push)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/sensitive-file" \
  --prune-empty --tag-name-filter cat -- --all
```

**⚠️ Warning:** This requires force push and affects all collaborators

**Empty or Invalid Commit Message:**

**Symptoms:**

- Commit fails due to empty message
- Message doesn't follow conventional format
- Git editor opens unexpectedly

**Recovery Steps:**

1. If in editor, write proper commit message and save
2. If commit failed, retry with proper message:

   ```bash
   git commit -m "type(scope): proper description"
   ```

3. For amending message: `git commit --amend`
4. Follow conventional commit format from workflow guidelines

**Prevention:**

- Always write descriptive commit messages
- Follow project's conventional commit format
- Review message before committing

## Success Criteria

- Changes are grouped logically into atomic commits
- Each commit message follows conventional format
- All commits pass tests independently
- No temporary or debug code committed
- Task status updated if applicable
- Changes pushed to appropriate branch

## Usage Example
>
> "I've finished implementing the user authentication feature. Help me commit these changes properly."

<documents>
<template path="dev-handbook/templates/commit/feature-implementation.template.md">
feat(module): implement new functionality

- Add main feature logic
- Include comprehensive tests
- Update documentation

Implements #task-id
</template>

<template path="dev-handbook/templates/commit/bug-fix.template.md">
fix(component): resolve issue with data handling

Root cause: Incorrect null check in process method
Solution: Add proper validation before processing

- Fix null pointer exception
- Add test cases for edge scenarios
- Update error messages

Fixes #bug-id
</template>

<template path="dev-handbook/templates/commit/refactoring.template.md">
refactor(service): simplify request handling logic

- Extract common patterns to helper methods
- Reduce code duplication
- Improve readability

No functional changes
</template>
</documents>
