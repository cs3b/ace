# Version Control Guide

## Goal

This guide establishes the standards and workflow for using Git version control within this project, focusing on
commit message conventions, branching strategies, and pull request processes to ensure a clean, understandable, and
collaborative development history.

## 1. Commit Message Structure

```text
<type>(<scope>): <subject>

<body>

<footer>
```

Example:

```git
feat(ui): Add dark mode toggle

Implement a user-configurable dark mode setting.
- Adds toggle switch to settings panel.
- Saves preference to local storage.
- Updates CSS variables based on selection.

References #123
```

## 2. Commit Types

| Type     | Description                        | Example |
|----------|------------------------------------|---------|
| feat     | New features                       | `feat(api): Add user profile endpoint` |
| fix      | Bug fixes                          | `fix(parser): Handle malformed input correctly` |
| docs     | Documentation                      | `docs(readme): Update setup instructions` |
| style    | Code style/formatting              | `style(core): Apply linter auto-fixes` |
| refactor | Code improvements                  | `refactor(auth): Simplify token validation logic` |
| test     | Testing                           | `test(utils): Add unit tests for helper functions` |
| chore    | Maintenance                        | `chore(deps): Update framework to v2.5` |

## 3. Commit Guidelines

1. **Subject Line**:

   ```git
   # Good
   feat(agent): Add support for concurrent tool execution

   # Bad
   Added some new features to make tools run faster
   ```

2. **Body Format**:

   ```git
   feat(registry): Implement thread-safe tool registration

   - Add mutex protection for registry operations
   - Implement atomic tool updates
   - Add specs for concurrent access

   This change ensures thread safety when multiple agents
   access the tool registry simultaneously.

   Breaking: Registry.register is now synchronized
   ```

3. **References**:

   ```git
   fix(agent): Handle LLM timeout errors

   - Add retry mechanism
   - Implement exponential backoff
   - Log failed attempts

   Fixes: #234
   Related: #235, #236
   ```

## 4. Branching Strategy

1. **Branch Types**:

   ```bash
   # Feature branches
   git checkout -b feature/browser-tool

   # Bug fixes
   git checkout -b fix/memory-leak

   # Documentation
   git checkout -b docs/api-reference
   ```

2. **Branch Flow**:

   ```bash
   # Start new feature
   git checkout -b feature/new-tool develop

   # Regular commits
   git commit -m "feat(tool): Add basic implementation"
   git commit -m "test(tool): Add integration specs"

   # Prepare for PR
   git fetch origin
   git rebase origin/develop

   # Push for review
   git push origin feature/new-tool
   ```

## 5. Pull Request Template

```markdown
## Changes
- Implemented new browser tool
- Added thread safety measures
- Updated documentation

## Testing
- [ ] Unit tests added
- [ ] Integration tests updated
- [ ] Thread safety verified

## Documentation
- [ ] API docs updated
- [ ] Examples added
- [ ] CHANGELOG updated

## Breaking Changes
- Tool initialization now requires explicit configuration
```

## 6. Git Hooks

Git hooks (client-side scripts that run automatically at certain points, like pre-commit or commit-msg) can help
enforce standards.

1. **Pre-commit Hook Example**:
   Runs before a commit is created. Useful for running linters, formatters, and quick tests.

   ```bash
   #!/bin/sh

   echo "Running pre-commit checks..."

   # Run linter (replace with your project's linter command)
   your-linter-command --options

   # Run formatter (optional, if not integrated with linter)
   # your-formatter-command

   # Run quick tests (e.g., unit tests)
   your-test-runner --filter=unit

   # Check if any command failed
   if [ $? -ne 0 ]; then
     echo "Pre-commit checks failed. Please fix the issues and try again."
     exit 1
   fi

   echo "Pre-commit checks passed."
   exit 0
   ```

   *Note: Setting up Git hooks often involves placing executable scripts in the `.git/hooks/` directory or using
   specialized hook management tools.*

2. **Commit-msg Hook Example**:
   Runs after the commit message is entered but before the commit is created. Useful for validating the commit message format.

   ```bash
   #!/bin/sh

   COMMIT_MSG_FILE=$1
   COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

   # Example: Validate Conventional Commits format
   if ! echo "$COMMIT_MSG" | grep -qE '^(feat|fix|docs|style|refactor|test|chore)(\(\S+\))?:\s.+'; then
     echo "ERROR: Invalid commit message format." >&2
     echo "Please follow the Conventional Commits specification: <type>(<scope>): <subject>" >&2
     echo "Example: feat(api): Add new endpoint" >&2
     exit 1
   fi

   exit 0
   ```

## 7. Practical Commit Workflow

1. **Pre-Commit Review**:
   Before committing, review your changes and run local validation checks.

   ```bash
   # Review changes
   git status
   git diff

   # Run validations (linters, tests, etc. - use your project's commands)
   your-lint-command
   your-test-command
   # or: make check / equivalent build system task
   # or: ./scripts/validate.sh
   ```

2. **Stage Changes**:
   Stage logically related changes together in chunks. Avoid overly large commits.

   ```bash
   # Stage specific files or directories
   git add src/feature-a/
   git add tests/feature-a/
   git add docs/feature-a.md

   # Or stage interactively
   # git add -p

   # Review staged changes
   git diff --staged
   ```

3. **Create Commit**:
   Write a clear and concise commit message following the Conventional Commits standard.

   ```bash
   # Opens your editor to write the commit message
   git commit

   # Or provide the message directly (for simple commits)
   # git commit -m "fix(ui): Correct button alignment"
   ```

4. **Post-Commit Steps**:
   - Push changes: `git push origin <branch>`
   - Update project board
   - Open pull request if ready

Common file groupings (examples):

- Source code: `src/`, `lib/`, `app/`
- Tests: `tests/`, `spec/`, `__tests__/`
- Documentation: `docs/`, `docs-dev/`
- Configuration: `config/`, `*.json`, `*.yaml`, `*.toml`
- Build/Package: `Makefile`, `Dockerfile`, `package.json`, `pom.xml`, `setup.py`, `Cargo.toml`

## 8. Best Practices

1. **Atomic Commits**:
   - One logical change per commit
   - Group related changes
   - Separate refactoring from features

2. **History Management**:
   - Rebase feature branches regularly
   - Squash fixup commits
   - Write clear commit messages

3. **Code Review**:
   - Review your own changes first
   - Respond to feedback promptly
   - Keep discussions focused

4. **Documentation**:
   - Update docs with code changes
   - Include example updates
   - Keep CHANGELOG current

## Language/Environment-Specific Examples

For specific examples of setting up Git hooks with specialized hook management tools, please refer to the examples in
the [./version-control/](./version-control/) sub-directory.

## Related Documentation

- [Project Management Guide](docs-dev/guides/project-management.md) (Task workflow integration)
- [Release Process Guide](docs-dev/guides/ship-release.md) (Tagging, Changelog)
- [Quality Assurance Guide](docs-dev/guides/quality-assurance.md) (PR Template, Code Review)
- Relevant Workflow Instructions: `docs-dev/workflow-instructions/lets-commit.md`
