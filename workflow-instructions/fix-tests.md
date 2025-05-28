# Fix Tests Workflow Instruction

## Goal

Systematically diagnose and fix failing automated tests (unit, integration, etc.) - focusing specifically on test failures
rather than general application bugs.

## Prerequisites

- Test suite has been run and failures have been identified.
- Access to test output (error messages, stack traces).
- Development environment is set up correctly (dependencies installed, services running if needed).

A systematic approach to diagnose and fix failing tests - distinct from general bug fixing. This workflow focuses
specifically on test failures, which often require specialized knowledge of testing frameworks and patterns. For
detailed testing practices and framework info, see [Testing Guide](docs-dev/guides/testing.md).

## When to Use This Workflow

- When automated tests are failing in your test suite
- When you need to systematically address test-specific issues
- When failures are related to test setup, isolation, or execution
- When test infrastructure needs repair

This workflow is NOT intended for:

- Fixing general application bugs that aren't causing test failures
- Feature development or implementation of new requirements
- Performance optimization unrelated to tests

## Process Steps

1. **Initial Analysis:**
    - Run the test suite (e.g., `bundle exec rspec` from project root).
    - Identify failing tests from the output.
    - Gather error messages and stack traces.

2. **Prioritize Failures:**
    - Focus on unit tests first (usually faster to run and debug).
    - Address integration tests next.
    - Handle end-to-end tests last.

3. **Fix and Verify:**
    - Isolate one failure at a time. Run only the failing test or file (e.g.,
      `bundle exec rspec spec/path/to/failing_spec.rb:line_number` from project root).
    - Analyze the code related to the failure.
    - Implement a fix.
    - Re-run the specific test to confirm it passes.
    - Run the broader suite (e.g., the whole file or component) to check for unintended side effects.
    - Document the root cause and fix if non-trivial (e.g., in commit message or code comments).

## Test-Specific Issues

1. **Environment Setup:**
    - Ensure correct language version (e.g., `ruby -v`).
    - Verify dependencies are installed and up-to-date (`bundle install` from project root).
    - Check for required environment variables or configuration files (e.g., `.env`).
    - Clear temporary files or caches if applicable (`rm -rf tmp/*`, `rake tmp:clear` from project root).

2. **Test Isolation:**
    - Review test helper files (e.g., `spec/spec_helper.rb`).
    - Check `before`/`after` hooks for proper setup and cleanup.
    - Ensure mocks/stubs are correctly configured and reset between tests.
    - Look for state leakage between tests.

3. **External Dependencies:**
    - Verify external services (databases, APIs) are running if needed for integration tests.
    - Ensure network connectivity.
    - Check API keys or credentials.

## Reference Documentation

- [Testing Guide](docs-dev/guides/testing.md)
- [Coding Standards](docs-dev/guides/coding-standards.md)

## Output / Success Criteria

1. **All Tests Pass:** The full test suite runs without failures (e.g., `bundle exec rspec`).
2. **Targeted Fix:** The fix addresses the root cause of the test failure.
3. **No Regressions:** The fix does not introduce new failures.
4. **Quality Metrics:** Failing tests are addressed promptly; fixes are documented.
5. **Learning:** The underlying cause of test failures is understood and documented to prevent similar issues.

## Relationship to Bug Fixing

While this workflow shares some similarities with general bug fixing, it is specifically focused on test-related issues
which often require:

- Specialized knowledge of testing frameworks and patterns
- Understanding of test isolation and data dependencies
- Familiarity with mocking, stubbing, and test doubles
- Awareness of test infrastructure and execution environment

If the issue you're addressing is primarily an application bug that happens to be revealed by tests
(rather than an issue with the tests themselves), consider following a more general bug-fixing
approach after understanding the test failure.
