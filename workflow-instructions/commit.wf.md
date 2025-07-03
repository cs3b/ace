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

**Accidentally committed to wrong branch:**

```bash
# Create new branch with current commits
git branch new-branch

# Reset current branch
git reset --hard origin/main

# Switch to new branch
git checkout new-branch
```

**Need to modify last commit:**

```bash
# Add more changes
git add files

# Amend without changing message
git commit --amend --no-edit

# Or change the message too
git commit --amend
```

**Committed sensitive data:**

```bash
# Remove from history (requires force push)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/sensitive-file" \
  --prune-empty --tag-name-filter cat -- --all
```

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
