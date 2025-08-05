# Test Maintenance Guide

This guide provides best practices and workflows for maintaining a reliable test suite in the Coding Agent Tools project.

## Overview

Test maintenance is crucial for ensuring a trustworthy development process. This guide covers:
- Identifying and fixing flaky tests
- Optimizing slow tests
- Tracking test reliability metrics
- Migration strategies for deprecated tools

## Test Reliability Tracking

### Automatic Tracking

The test suite automatically tracks execution metrics for all tests:

```bash
# Run tests with reliability tracking enabled (default)
bundle exec rspec

# View reliability report after test run
SHOW_RELIABILITY_REPORT=1 bundle exec rspec

# Disable tracking if needed
DISABLE_TEST_TRACKING=1 bundle exec rspec
```

### Manual Analysis

Use the `test-reliability` CLI tool to analyze test metrics:

```bash
# Generate comprehensive report
bin/test-reliability report

# Show only flaky tests
bin/test-reliability flaky

# Show slow tests (default threshold: 1s)
bin/test-reliability slow

# Show slow tests with custom threshold
bin/test-reliability slow --threshold 0.5

# Export data as JSON
bin/test-reliability report --format json

# Clear tracking data
bin/test-reliability clear
```

## Identifying Flaky Tests

### What Makes a Test Flaky?

Flaky tests are tests that fail intermittently without code changes. Common causes:
- Race conditions
- Time-dependent logic
- External dependencies
- Shared state between tests
- Random data generation

### Detection Strategy

1. **Automatic Detection**: Tests with 20-80% failure rate are flagged as flaky
2. **Manual Verification**: Run suspected flaky tests multiple times:
   ```bash
   # Run specific test 10 times
   for i in {1..10}; do bundle exec rspec path/to/spec.rb:line; done
   ```

### Fixing Flaky Tests

1. **Add Retry Logic**: For known flaky tests, add retry metadata:
   ```ruby
   it 'handles network timeouts', retry: 2 do
     # Test that occasionally fails due to network issues
   end
   ```

2. **Fix Root Causes**:
   - Use deterministic test data
   - Mock time-dependent operations
   - Ensure proper test isolation
   - Add explicit waits for async operations

## Optimizing Slow Tests

### Identifying Slow Tests

```bash
# Run tests with profiling
bundle exec rspec --profile 10

# Use test-reliability tool
bin/test-reliability slow --threshold 0.5
```

### Optimization Strategies

1. **Reduce Timeout Values**: For timeout tests, use minimal values:
   ```ruby
   # Before: Takes 2+ seconds
   it 'times out long-running commands' do
     result = execute('sleep 2', timeout: 1)
   end
   
   # After: Takes ~1 second
   it 'times out long-running commands' do
     result = execute('sleep 1.1', timeout: 1)
   end
   ```

2. **Use Faster Test Doubles**:
   ```ruby
   # Before: Real HTTP request
   response = client.get('https://api.example.com/data')
   
   # After: Stubbed response
   allow(client).to receive(:get).and_return(mock_response)
   ```

3. **Batch Similar Tests**: Group related assertions to reduce setup overhead

## Ruby 3.4.2 Compatibility

### VCR Migration

VCR is currently disabled for Ruby 3.4.2 due to compatibility issues. To migrate existing VCR cassettes:

```bash
# Convert VCR cassette to WebMock stubs
ruby spec/support/vcr_migration_helper.rb spec/cassettes/old_test.yml

# This creates spec/cassettes/old_test_webmock.rb
# Include it in your spec:
require_relative '../cassettes/old_test_webmock'

before do
  setup_webmock_stubs
end
```

### Keyword Arguments

Ruby 3.4.2 enforces stricter keyword argument separation:

```ruby
# Before (Ruby 2.x style)
def method(opts = {})
  value = opts[:key]
end

# After (Ruby 3.x style)
def method(**opts)
  value = opts[:key]
end

# Or with explicit keywords
def method(key: nil)
  value = key
end
```

## Test Suite Health Metrics

### Key Metrics to Track

1. **Overall Success Rate**: Should be > 99%
2. **Flaky Test Count**: Should be < 1% of total tests
3. **Average Execution Time**: Full suite should run in < 2 minutes
4. **Slow Test Count**: < 5% of tests should take > 1 second

### Regular Maintenance Tasks

#### Daily
- Review CI failures for flaky tests
- Fix any broken tests immediately

#### Weekly
- Run `bin/test-reliability report` to identify trends
- Address top 3 slowest tests
- Fix or mark flaky tests for investigation

#### Monthly
- Full test suite audit
- Update deprecated testing patterns
- Review and update test documentation

## Best Practices

### Writing Reliable Tests

1. **Isolation**: Each test should be independent
   ```ruby
   before(:each) do
     # Reset state
     DatabaseCleaner.start
   end
   
   after(:each) do
     DatabaseCleaner.clean
   end
   ```

2. **Deterministic Data**: Avoid randomness
   ```ruby
   # Bad
   let(:user) { create(:user, age: rand(18..65)) }
   
   # Good
   let(:user) { create(:user, age: 25) }
   ```

3. **Clear Assertions**: Be specific about expectations
   ```ruby
   # Bad
   expect(result).to be_truthy
   
   # Good
   expect(result.success?).to be true
   expect(result.message).to eq('Operation completed')
   ```

### Test Organization

1. **Descriptive Names**: Test names should explain the behavior
   ```ruby
   # Bad
   it 'works' do
   
   # Good
   it 'returns error when timeout exceeds maximum allowed value' do
   ```

2. **Logical Grouping**: Use contexts to organize related tests
   ```ruby
   context 'with valid input' do
     it 'processes successfully' do
     
   context 'with invalid input' do
     it 'raises ArgumentError' do
   ```

3. **Shared Examples**: DRY up common test patterns
   ```ruby
   shared_examples 'a timeout handler' do
     it 'respects the timeout value' do
       # Common timeout behavior
     end
   end
   ```

## Troubleshooting

### Common Issues

1. **"No such file or directory" errors**
   - Ensure test files use absolute paths or proper fixtures
   - Check for missing test data files

2. **Timeout failures in CI**
   - CI environments may be slower
   - Consider increasing timeouts for CI: `timeout * (ENV['CI'] ? 2 : 1)`

3. **Database connection errors**
   - Ensure proper cleanup between tests
   - Check for connection pool exhaustion

### Debug Techniques

```bash
# Run with debug output
DEBUG=1 bundle exec rspec

# Run with seed for reproducibility
bundle exec rspec --seed 12345

# Run in documentation format for clarity
bundle exec rspec --format documentation

# Run with backtrace for errors
bundle exec rspec --backtrace
```

## Migration Guides

### From VCR to WebMock

1. Identify specs using VCR:
   ```bash
   grep -r "vcr: true" spec/
   ```

2. Convert each cassette:
   ```bash
   ruby spec/support/vcr_migration_helper.rb spec/cassettes/[cassette].yml
   ```

3. Update the spec:
   ```ruby
   # Remove
   it 'makes API call', vcr: true do
   
   # Add
   require_relative '../cassettes/[cassette]_webmock'
   
   before do
     setup_webmock_stubs
   end
   
   it 'makes API call' do
   ```

### Updating Timeout Tests

For tests that check timeout behavior:

1. Use integer timeout values (Ruby 3.4.2 requirement)
2. Ensure sleep duration exceeds timeout
3. Consider reducing timeouts for faster execution

```ruby
# Template for timeout tests
it 'handles timeout correctly' do
  # Minimum reliable timeout test
  result = execute('sleep 1.5', timeout: 1)
  expect(result.success?).to be false
  expect(result.stderr).to include('timed out')
end
```

## Resources

- [RSpec Best Practices](https://www.betterspecs.org/)
- [Ruby 3.0 Keyword Arguments](https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/)
- [WebMock Documentation](https://github.com/bblimke/webmock)
- [Test Reliability Tracker Source](../../spec/support/test_reliability_tracker.rb)