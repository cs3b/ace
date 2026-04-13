# Contributing to ace-support-markdown

Thank you for your interest in contributing to ace-support-markdown! This document provides guidelines for maintaining code quality and documentation accuracy.

## Development Setup

```bash
git clone https://github.com/your-org/ace-support-markdown.git
cd ace-support-markdown
bundle install
bundle exec rake test
```

## Code Architecture

This gem follows the **ATOM architecture pattern**:

- **Atoms**: Pure functions with no side effects (`lib/ace/support/markdown/atoms/`)
- **Molecules**: Composed operations (`lib/ace/support/markdown/molecules/`)
- **Organisms**: High-level orchestration (`lib/ace/support/markdown/organisms/`)
- **Models**: Immutable data structures (`lib/ace/support/markdown/models/`)

### Design Principles

1. **Immutability**: Models return new instances on transformation
2. **Safety First**: All file operations include backup and rollback
3. **Validation**: Pre-write and post-write validation prevents corruption
4. **Atomicity**: Operations succeed completely or fail completely
5. **Clear Errors**: Detailed error messages with actionable information

## Making Changes

### 1. Adding New Features

When adding new functionality:

1. **Identify the layer**: Determine if it's an atom, molecule, organism, or model
2. **Write tests first**: Add test cases before implementation
3. **Implement the feature**: Follow existing patterns and conventions
4. **Update documentation**: Add examples to README.md
5. **Add README tests**: Create tests in `test/feat/readme_examples_test.rb`
6. **Run full test suite**: `bundle exec rake test`
7. **Update CHANGELOG.md**: Document the new feature

### 2. Fixing Bugs

When fixing bugs:

1. **Write a failing test**: Reproduce the bug in a test case
2. **Fix the implementation**: Resolve the issue
3. **Verify the fix**: Ensure the test passes
4. **Check for regressions**: Run full test suite
5. **Update CHANGELOG.md**: Document the fix

### 3. Updating API

**IMPORTANT**: API changes require updating both code AND documentation.

When modifying the public API:

1. **Update implementation** in `lib/`
2. **Update corresponding tests** in `test/`
3. **Update README examples** - this is critical!
4. **Update README example tests** in `test/feat/readme_examples_test.rb`
5. **Run test suite** - README tests will catch doc/code mismatches
6. **Update CHANGELOG.md**
7. **Consider semver implications**:
   - Breaking changes → MAJOR version bump
   - New features → MINOR version bump
   - Bug fixes → PATCH version bump

### 4. Documentation Sync Strategy

**The Problem**: Documentation can become stale as code evolves.

**Our Solution**: Automated validation of README examples.

The test file `test/feat/readme_examples_test.rb` validates that:
- Code examples in README.md are syntactically correct
- Examples work against the current API
- API behavior matches what's documented

**When you change the API:**
1. Update the README examples
2. Update the README example tests
3. Run `bundle exec rake test`
4. If tests fail, either:
   - Fix the README (if docs are wrong)
   - Fix the test (if test is wrong)
   - Fix the implementation (if code is wrong)

**This ensures documentation never gets out of sync with reality.**

## Testing Guidelines

### Test Structure

```
test/
├── atoms/           # Unit tests for pure functions
├── molecules/       # Operation-focused tests
├── organisms/       # End-to-end tests for orchestration
├── models/          # Tests for data structures
└── feat/            # Full workflow tests + README validation
```

### Writing Tests

```ruby
class MyFeatureTest < Minitest::Test
  include TestHelpers

  def setup
    # Setup test environment
  end

  def teardown
    # Clean up
  end

  def test_feature_behavior
    # Arrange: Set up test data
    # Act: Execute the feature
    # Assert: Verify behavior
  end
end
```

### Test Coverage Requirements

- **Atoms**: 100% coverage (pure functions, easy to test)
- **Molecules**: 95%+ coverage
- **Organisms**: 95%+ coverage
- **Integration**: All major workflows covered

Run coverage report:
```bash
bundle exec rake test
# Coverage report in coverage/index.html
```

## Documentation Guidelines

### README Examples

Examples should be:
1. **Real-world**: Based on actual use cases from ACE gems
2. **Complete**: Include setup, execution, and verification
3. **Commented**: Explain *why*, not just *what*
4. **Tested**: Have corresponding tests in `readme_examples_test.rb`

### Code Comments

Add comments that explain:
- **Why** decisions were made (not what the code does)
- **Edge cases** and special handling
- **Performance** considerations
- **Safety** guarantees

Example:
```ruby
# Use ensure block for rollback to guarantee cleanup even if control flow is interrupted
# This handles early returns, raised exceptions, and other non-linear execution paths
ensure
  editor.rollback if original_backup && !success_flag
end
```

### CHANGELOG Format

Follow [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [0.1.2] - 2025-10-23

### Added
- New feature description

### Changed
- Modified behavior description

### Fixed
- Bug fix description
```

## Pull Request Process

1. **Create a feature branch**: `git checkout -b feature/my-feature`
2. **Make your changes**: Follow guidelines above
3. **Run tests**: `bundle exec rake test`
4. **Update CHANGELOG.md**: Document your changes
5. **Commit your changes**: Use clear commit messages
6. **Push to your fork**: `git push origin feature/my-feature`
7. **Create Pull Request**: With detailed description

### PR Checklist

- [ ] Tests added/updated and passing
- [ ] README updated (if API changed)
- [ ] README example tests updated (if examples changed)
- [ ] CHANGELOG.md updated
- [ ] Code follows ATOM architecture
- [ ] Comments explain *why*, not *what*
- [ ] No breaking changes (or clearly documented)

## Code Style

Follow Ruby community conventions:
- 2 spaces for indentation
- Snake_case for methods and variables
- CamelCase for classes and modules
- Descriptive names over short names
- Limit line length to 120 characters

## Questions?

- Open an issue for bugs or feature requests
- Start a discussion for questions or ideas
- Check existing issues and PRs first

Thank you for contributing to ace-support-markdown!
