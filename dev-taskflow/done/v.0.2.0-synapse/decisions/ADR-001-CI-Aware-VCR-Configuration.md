# ADR-001: CI-Aware VCR Configuration for Integration Tests

## Status

Accepted
Date: 2025-06-07

## Context

The project needed a robust solution for testing the `llm-gemini-query` command's integration with the Google Gemini API. The challenge was to create tests that:

1. **Run consistently** across development and CI environments
2. **Don't require API keys in CI** to avoid security risks and external dependencies
3. **Automatically record new interactions** during development without manual intervention
4. **Maintain simplicity** and use standard Ruby testing patterns
5. **Prevent accidental API costs** from test runs in CI

Initial approaches considered custom test runners and complex environment management, but these added unnecessary complexity and deviated from standard Ruby/RSpec patterns.

The key insight was that VCR already provides powerful configuration options that could be leveraged with minimal custom code.

## Decision

We implemented a CI-aware VCR configuration using VCR's built-in recording mode options with environment-based switching:

```ruby
# CI-aware recording mode
recording_mode = if ENV['CI']
                   :none  # Never record in CI
                 else
                   case ENV['VCR_RECORD']
                   when 'true', '1', 'all'
                     :all
                   when 'new_episodes', 'new'
                     :new_episodes  
                   when 'none', 'false', '0'
                     :none
                   else
                     :once  # Auto-record missing cassettes in development
                   end
                 end

config.default_cassette_options[:record] = recording_mode
```

This configuration automatically:
- **In CI environments** (`ENV['CI']` is set): Uses `:none` mode - only replays existing cassettes, never makes API calls
- **In development**: Uses `:once` mode by default - automatically records missing cassettes, replays existing ones
- **Provides overrides**: Allows explicit control via `VCR_RECORD` environment variable when needed

The solution uses standard `bin/test` command (wrapper around `bundle exec rspec`) with environment variables for control, eliminating the need for custom tooling.

## Consequences

### Positive

- **Zero Configuration**: Works out of the box for developers and CI
- **Standard Ruby Patterns**: Uses familiar `bin/test` commands and RSpec conventions
- **Automatic CI Detection**: No manual configuration needed across different CI platforms
- **Developer Friendly**: Missing cassettes are recorded automatically during development
- **Security**: No API keys required in CI, automatic sensitive data filtering
- **Fast CI Builds**: No external API calls means faster, more reliable test runs
- **Cost Control**: Prevents accidental API usage in CI environments
- **Maintainable**: Any Ruby developer can understand and modify the configuration

### Negative

- **Initial Recording Requires API Key**: Developers need a real API key to record new cassettes (though this is unavoidable)
- **Cassette Maintenance**: Cassettes need to be updated when API responses change (though this provides value by catching API changes)

### Neutral

- **Cassettes in Repository**: VCR cassettes are committed to version control, increasing repository size slightly but providing test reliability
- **Environment Variable Dependency**: Relies on CI platforms setting `ENV['CI']` (which is standard practice)

## Alternatives Considered

### Custom Test Runner Script
- **Why rejected**: Added unnecessary complexity and deviated from standard Ruby patterns
- **Trade-offs**: Would have provided more fine-grained control but at the cost of maintainability and developer experience

### Manual VCR Mode Switching
- **Why rejected**: Required developers to remember to set different modes for different scenarios
- **Trade-offs**: Would have been simpler to implement but error-prone and poor developer experience

### Always Recording in Development
- **Why rejected**: Would make unnecessary API calls and potentially hit rate limits
- **Trade-offs**: Would have been simpler but wasteful of API quota and slower test runs

### Separate Test Suites for CI vs Development
- **Why rejected**: Would create maintenance overhead and potential for CI/development drift
- **Trade-offs**: Might have been cleaner separation but would duplicate test maintenance

## Related Decisions

- Integration test strategy for `llm-gemini-query` command
- API key management and security practices
- Test automation and CI/CD pipeline design

## References

- [VCR Documentation - Recording Modes](https://relishapp.com/vcr/vcr/docs/record-modes)
- [VCR GitHub Repository](https://github.com/vcr/vcr)
- [Ruby CI Environment Detection Patterns](https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables)
- [Google Gemini API Documentation](https://ai.google.dev/api/rest)