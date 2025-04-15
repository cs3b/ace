# Let's Fix Tests Command

A systematic approach to diagnose and fix failing tests. For detailed testing practices and framework info, see [Testing Guide](../guides/testing.md).

## Process Steps

1.  **Initial Analysis:**
    *   Run the test suite (e.g., `bundle exec rspec`).
    *   Identify failing tests from the output.
    *   Gather error messages and stack traces.

2.  **Prioritize Failures:**
    *   Focus on unit tests first (usually faster to run and debug).
    *   Address integration tests next.
    *   Handle end-to-end tests last.

3.  **Fix and Verify:**
    *   Isolate one failure at a time. Run only the failing test or file (e.g., `bundle exec rspec spec/path/to/failing_spec.rb:line_number`).
    *   Analyze the code related to the failure.
    *   Implement a fix.
    *   Re-run the specific test to confirm it passes.
    *   Run the broader suite (e.g., the whole file or component) to check for unintended side effects.
    *   Document the root cause and fix if non-trivial (e.g., in commit message or code comments).

## Common Issues

1.  **Environment Setup:**
    *   Ensure correct language version (e.g., `ruby -v`).
    *   Verify dependencies are installed and up-to-date (`bundle install`).
    *   Check for required environment variables or configuration files.
    *   Clear temporary files or caches if applicable (`rm -rf tmp/*`, `rake tmp:clear`).

2.  **Test Isolation:**
    *   Review test helper files (e.g., `spec/spec_helper.rb`).
    *   Check `before`/`after` hooks for proper setup and cleanup.
    *   Ensure mocks/stubs are correctly configured and reset between tests.
    *   Look for state leakage between tests.

3.  **External Dependencies:**
    *   Verify external services (databases, APIs) are running if needed for integration tests.
    *   Ensure network connectivity.
    *   Check API keys or credentials.

## Reference Documentation

- [Testing Guide](../guides/testing.md)
- [Testing Frameworks](../guides/testing/frameworks.md) (if applicable)
- [Coding Standards](../guides/coding-standards.md)

## Success Criteria

1.  **All Tests Pass:** The full test suite runs without failures (e.g., `bundle exec rspec`).
2.  **Targeted Fix:** The fix addresses the root cause of the failure.
3.  **No Regressions:** The fix does not introduce new failures.
4.  **Quality Metrics:** Failing tests are addressed promptly; fixes are documented.
