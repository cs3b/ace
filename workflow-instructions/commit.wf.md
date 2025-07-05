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
    # Version Control System Message Guide

    ## Purpose

    This guide provides comprehensive documentation for version control commit message standards, specifically documenting the Conventional Commits specification required by project workflows. It serves as a standalone reference for creating clear, consistent, and actionable commit messages.

    ## Conventional Commits Specification

    ### Message Structure

    All commit messages must follow the Conventional Commits specification:

    ```
    <type>(<scope>): <subject>

    <body>

    <footer>
    ```

    ### Components

    #### Type (Required)

    The type indicates the nature of the change:

    - **feat**: A new feature for the user
    - **fix**: A bug fix
    - **docs**: Documentation only changes
    - **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc.)
    - **refactor**: A code change that neither fixes a bug nor adds a feature
    - **test**: Adding missing tests or correcting existing tests
    - **chore**: Changes to the build process or auxiliary tools and libraries

    #### Scope (Optional)

    The scope indicates the section of the codebase affected:

    - **Common scopes**: `api`, `ui`, `auth`, `db`, `config`, `cli`, `docs`
    - **Component scopes**: `parser`, `router`, `validator`, `middleware`
    - **Domain scopes**: `users`, `orders`, `payments`, `inventory`

    #### Subject (Required)

    The subject contains a succinct description of the change:

    - Use imperative mood ("add" not "added" or "adds")
    - Keep it 50 characters or less
    - Do not capitalize the first letter
    - Do not end with a period

    #### Body (Optional)

    The body provides additional context:

    - Wrap lines at 72 characters
    - Explain the what and why, not the how
    - Use bullet points for multiple items
    - Separate from subject with blank line

    #### Footer (Optional)

    The footer contains metadata:

    - **Breaking changes**: Use `BREAKING CHANGE:` prefix
    - **Issue references**: Use `Fixes #123`, `Closes #456`
    - **Co-authors**: Use `Co-authored-by: Name <email>`

    ## Commit Types in Detail

    ### feat: New Features

    Use `feat` for new functionality that adds value to users:

    ```git
    feat(auth): add password reset functionality

    Implement secure password reset flow with email verification.
    - Add password reset request endpoint
    - Create secure token generation
    - Implement email notification system
    - Add password reset confirmation page

    Implements #234
    ```

    **Guidelines:**

    - Always include tests for new features
    - Update documentation when adding user-facing features
    - Consider breaking changes and version impact

    ### fix: Bug Fixes

    Use `fix` for resolving issues or correcting unintended behavior:

    ```git
    fix(api): handle null values in user response

    Root cause: Missing null check in user serialization
    Solution: Add proper validation before processing

    - Add null checks for optional fields
    - Update tests to cover edge cases
    - Fix TypeScript types for nullable fields

    Fixes #123
    ```

    **Guidelines:**

    - Include root cause analysis when helpful
    - Reference the issue being fixed
    - Ensure fix is covered by tests

    ### docs: Documentation

    Use `docs` for documentation-only changes:

    ```git
    docs(readme): update installation instructions

    - Add prerequisites section
    - Update Node.js version requirement
    - Include troubleshooting steps
    - Fix formatting issues
    ```

    **Guidelines:**

    - No functional code changes
    - May include example updates
    - Can affect README, comments, or separate docs

    ### style: Code Style

    Use `style` for formatting changes that don't affect logic:

    ```git
    style(parser): fix indentation and spacing

    - Standardize indentation to 2 spaces
    - Remove trailing whitespace
    - Fix line length violations
    - Organize imports alphabetically
    ```

    **Guidelines:**

    - No functional changes
    - Often automated by linters/formatters
    - Include scope of formatting changes

    ### refactor: Code Improvements

    Use `refactor` for code changes that improve structure without changing behavior:

    ```git
    refactor(service): simplify request handling logic

    - Extract common patterns to helper methods
    - Reduce code duplication
    - Improve readability and maintainability
    - Consolidate error handling

    No functional changes
    ```

    **Guidelines:**

    - Explicitly state "No functional changes"
    - Include reasoning for refactoring
    - Ensure all tests still pass

    ### test: Testing

    Use `test` for adding or modifying tests:

    ```git
    test(validator): add comprehensive email validation tests

    - Test valid email formats
    - Test invalid email formats
    - Test edge cases (empty, null, special chars)
    - Add performance tests for large inputs
    ```

    **Guidelines:**

    - Focus on test coverage improvements
    - May include test infrastructure changes
    - Can be combined with fixes or features

    ### chore: Maintenance

    Use `chore` for maintenance tasks that don't affect source code:

    ```git
    chore(deps): update dependencies to latest versions

    - Update Express to v4.18.2
    - Update Jest to v29.0.0
    - Update TypeScript to v4.8.0
    - Resolve security vulnerabilities
    ```

    **Guidelines:**

    - Dependency updates
    - Build tool changes
    - CI/CD configuration
    - Development environment changes

    ## Scope Usage Guidelines

    ### When to Include Scope

    **Always include scope when:**

    - Multiple modules exist in the project
    - Change affects a specific component
    - Scope provides meaningful context

    **Optional scope when:**

    - Change affects entire application
    - Scope would be too generic (`app`, `main`)
    - Project has simple structure

    ### Scope Naming Conventions

    - **Lowercase**: Use lowercase for scopes
    - **Kebab-case**: Use hyphens for multi-word scopes (`user-auth`)
    - **Consistent**: Use established scopes from project history
    - **Descriptive**: Make scope meaningful to team members

    ### Common Scope Patterns

    #### By Layer

    - `api`: Backend API changes
    - `ui`: User interface changes
    - `db`: Database-related changes
    - `config`: Configuration changes

    #### By Feature

    - `auth`: Authentication and authorization
    - `search`: Search functionality
    - `payments`: Payment processing
    - `notifications`: Notification system

    #### By Component

    - `parser`: Code parsing logic
    - `router`: Routing logic
    - `validator`: Validation logic
    - `middleware`: Middleware components

    ## Breaking Changes

    ### Format for Breaking Changes

    Breaking changes must be indicated in the footer:

    ```git
    feat(api): update user authentication endpoint

    Change authentication endpoint to use JWT tokens instead of sessions.

    BREAKING CHANGE: Authentication endpoint now requires JWT token in Authorization header instead of session cookies. Update client applications to use new authentication flow.

    Implements #456
    ```

    ### Guidelines for Breaking Changes

    - Always use `BREAKING CHANGE:` prefix in footer
    - Explain what changed and why
    - Provide migration guidance
    - Consider major version bump
    - Document in changelog

    ## Multi-line Messages

    ### When to Use Body

    Use body section when:

    - Change requires explanation
    - Multiple files affected
    - Context needed for reviewers
    - Implementation details important

    ### Body Structure

    ```git
    feat(search): implement advanced search filters

    Add support for complex search queries with multiple criteria.
    This enables users to search by date range, category, and tags
    simultaneously, improving search precision.

    Implementation details:
    - Add query builder for complex conditions
    - Create filter component for UI
    - Implement search result ranking
    - Add caching for performance

    Implements #789
    ```

    ## Common Patterns

    ### Revert Commits

    ```git
    revert: "feat(auth): add password reset functionality"

    This reverts commit abc123def456.

    Reason: Password reset feature caused issues in production
    with email delivery service.
    ```

    ### Co-authored Commits

    ```git
    feat(api): implement user profile endpoints

    Add CRUD operations for user profiles with validation.

    Co-authored-by: Alice Developer <alice@example.com>
    Co-authored-by: Bob Engineer <bob@example.com>
    ```

    ### Multiple Issue References

    ```git
    fix(validator): resolve validation edge cases

    - Fix null handling in email validator
    - Resolve regex issues with special characters
    - Update error messages for clarity

    Fixes #123, #456
    Closes #789
    ```

    ## Validation Rules

    ### Automated Validation

    Projects should implement git hooks to validate commit messages:

    ```bash
    # Example: Validate Conventional Commits format
    if ! echo "$COMMIT_MSG" | grep -qE '^(feat|fix|docs|style|refactor|test|chore)(\(\S+\))?:\s.+'; then
      echo "ERROR: Invalid commit message format." >&2
      echo "Please follow the Conventional Commits specification: <type>(<scope>): <subject>" >&2
      echo "Example: feat(api): add new endpoint" >&2
      exit 1
    fi
    ```

    ### Manual Validation Checklist

    Before committing, verify:

    - [ ] Type is one of: feat, fix, docs, style, refactor, test, chore
    - [ ] Scope is lowercase and descriptive (if included)
    - [ ] Subject uses imperative mood
    - [ ] Subject is 50 characters or less
    - [ ] Subject doesn't end with period
    - [ ] Body lines are 72 characters or less
    - [ ] Footer includes issue references
    - [ ] Breaking changes are properly documented

    ## Common Anti-patterns

    ### Avoid These Patterns

    **Vague messages:**

    ```git
    # Bad
    fix: bug fix

    # Good
    fix(auth): handle expired tokens gracefully
    ```

    **Past tense:**

    ```git
    # Bad
    feat(api): added new endpoint

    # Good
    feat(api): add new endpoint
    ```

    **Capitalized subject:**

    ```git
    # Bad
    feat(ui): Add dark mode toggle

    # Good
    feat(ui): add dark mode toggle
    ```

    **Missing type:**

    ```git
    # Bad
    update user validation

    # Good
    refactor(validator): update user validation logic
    ```

    ## Integration with Workflows

    ### Semantic Versioning

    Commit types determine version bumps:

    - **feat**: Minor version bump (1.0.0 → 1.1.0)
    - **fix**: Patch version bump (1.0.0 → 1.0.1)
    - **BREAKING CHANGE**: Major version bump (1.0.0 → 2.0.0)

    ### Changelog Generation

    Conventional commits enable automated changelog generation:

    ```markdown
    ## [1.2.0] - 2023-12-01

    ### Features
    - **auth**: add password reset functionality (#234)
    - **search**: implement advanced search filters (#789)

    ### Bug Fixes
    - **api**: handle null values in user response (#123)
    - **validator**: resolve validation edge cases (#456)

    ### Breaking Changes
    - **api**: update user authentication endpoint (#456)
    ```

    ## Tools and Automation

    ### Recommended Tools

    - **commitizen**: Interactive commit message prompts
    - **commitlint**: Automated commit message validation
    - **conventional-changelog**: Automated changelog generation
    - **semantic-release**: Automated version management

    ### Git Hook Example

    ```bash
    #!/bin/sh
    # .git/hooks/commit-msg

    commit_regex='^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,50}'

    if ! grep -qE "$commit_regex" "$1"; then
        echo "Invalid commit message format."
        echo "Please use: <type>(<scope>): <subject>"
        echo "Example: feat(api): add user authentication"
        exit 1
    fi
    ```

    ## Best Practices Summary

    1. **Be consistent**: Follow the same patterns across your project
    2. **Be descriptive**: Write clear, meaningful commit messages
    3. **Be atomic**: One logical change per commit
    4. **Be imperative**: Use imperative mood in subject line
    5. **Be concise**: Keep subject line under 50 characters
    6. **Be thorough**: Include context in body when needed
    7. **Be traceable**: Reference issues and pull requests
    8. **Be breaking-aware**: Document breaking changes clearly

    ## Related Documents

    - [Version Control Git Guide](./version-control-system-git.g.md) - Complete Git workflow practices
    - [Commit Workflow](../workflow-instructions/commit.wf.md) - Step-by-step commit process
    - [Code Review Process](./code-review-process.g.md) - Review guidelines including commit quality

    ## References

    - [Conventional Commits Specification](https://www.conventionalcommits.org/)
    - [Semantic Versioning](https://semver.org/)
    - [Git Best Practices](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project)

</guide>
</documents>
