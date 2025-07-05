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

   Follow the Conventional Commits specification detailed in the [Version Control Message Guide](../guides/version-control-system-message.g.md).

   **Quick Reference:**

   ```
   type(scope): subject
   
   [optional body]
   
   [optional footer(s)]
   ```

   **Common Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

   **Key Guidelines:**
   - Subject: 50 characters or less, imperative mood
   - Body: 72 characters per line, explain what and why
   - Footer: Reference issues/tasks, document breaking changes

   **Examples:**

   ```bash
   git commit -m "feat(auth): add password reset functionality"
   git commit -m "fix(api): handle null values in user response

   - Add null checks for optional fields
   - Update tests to cover edge cases

   Fixes #123"
   ```

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

For comprehensive Git troubleshooting, see the [Version Control Git Guide](../guides/version-control-system-git.g.md#troubleshooting-common-issues).

### Workflow-Specific Issues

**Pre-commit Hook Failures:**

**Symptoms:**

- `git commit` fails with hook error messages
- Lint, formatting, or test failures during commit

**Recovery Steps:**

1. Read hook error message carefully
2. Fix identified issues: `bin/lint` and `bin/test`
3. Re-stage fixed files: `git add .`
4. Retry commit: `git commit`

**Prevention:** Always run `bin/lint` and `bin/test` before committing

**Empty or Invalid Commit Message:**

**Symptoms:**

- Commit fails due to empty message
- Message doesn't follow conventional format
- Git editor opens unexpectedly

**Recovery Steps:**

1. If in editor, write proper commit message and save
2. If commit failed, retry with proper message following [Conventional Commits format](../guides/version-control-system-message.g.md)
3. For amending message: `git commit --amend`

**Prevention:**

- Follow the [Version Control Message Guide](../guides/version-control-system-message.g.md)
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

<guide path="dev-handbook/guides/version-control-system-message.g.md">
Complete reference guide for version control commit message standards using Conventional Commits specification.
Provides comprehensive documentation of commit types, scopes, formatting rules, examples, and best practices.
</guide>
</documents>
