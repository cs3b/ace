# Let's Fix Tests Command

A systematic approach to diagnose and fix failing tests in the AI Ruby Agent SDK. For detailed testing practices and framework info, see [Testing Guide](../guides/testing.md).

## Process Steps

1. Initial Analysis:
   - Run the test suite
   - Identify failing tests
   - Gather test output details

2. Prioritize Failures:
   - Start with unit tests
   - Then integration tests
   - Finally end-to-end tests

3. Fix and Verify:
   - Address one failure at a time
   - Run affected test suite
   - Check for side effects
   - Document root causes

## Project Structure

Test files are organized as:
```
spec/
├── aira/      # Unit tests
│   ├── agent_spec.rb
│   ├── tools_spec.rb
│   └── prompt_spec.rb
├── integration/        # Integration tests
└── e2e/               # End-to-end tests
```

## Common Issues

1. Environment Setup:
   ```bash
   # Check Ruby version
   ruby -v

   # Verify dependencies
   bundle install
   bundle exec gem list

   # Clear temp files
   rm -rf tmp/*
   ```

2. Test Isolation:
   - Review `spec_helper.rb`
   - Check shared contexts
   - Verify cleanup hooks

## Reference Documentation

- [Testing Guide](../guides/testing.md)
- [Testing Frameworks](../guides/testing/frameworks.md)
- [Coding Standards](../guides/coding-standards.md)

## Success Criteria

1. All Tests Pass:
   ```bash
   bundle exec rspec --format documentation
   ```

2. Quality Metrics:
   - No flaky tests
   - Good test coverage
   - Clear failure messages
   - Documented fixes
