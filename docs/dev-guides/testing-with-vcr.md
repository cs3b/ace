# Testing with VCR (Video Cassette Recorder)

This project uses VCR to record and replay HTTP interactions with external APIs, particularly the Google Gemini API. This allows tests to run consistently without making actual API calls during regular test runs.

## Overview

VCR works by:
1. **Recording**: Capturing real HTTP requests and responses during the first test run
2. **Replaying**: Using the recorded interactions for subsequent test runs
3. **Filtering**: Removing sensitive data like API keys from recordings

Our VCR configuration is **CI-aware**, meaning it automatically behaves differently in development vs CI environments:

- **Development**: Automatically records missing cassettes, replays existing ones
- **CI**: Only uses existing cassettes, never makes external API calls

## Quick Start

### Running Tests

```bash
# Run all tests (uses existing cassettes, records missing ones in development)
bin/test

# Run integration tests specifically
bin/test spec/integration/

# Run with debug output
TEST_DEBUG=true bin/test spec/integration/
```

### Recording New Cassettes

1. **Set up your API key** (one-time setup):
   ```bash
   cp spec/.env.example spec/.env
   # Edit spec/.env and add: GEMINI_API_KEY=your_actual_api_key_here
   ```

2. **Write your test** with the `:vcr` tag:
   ```ruby
   it "queries Gemini API", :vcr do
     # Your test code that makes API calls
   end
   ```

3. **Run the test** - VCR automatically records missing cassettes:
   ```bash
   bin/test spec/integration/your_test_file.rb
   ```

4. **Commit the cassette**:
   ```bash
   git add spec/cassettes/
   git commit -m "Add VCR cassette for new test"
   ```

## Configuration

### Automatic CI Detection

VCR is configured to detect CI environments automatically:

```ruby
# In spec/support/vcr.rb
recording_mode = if ENV['CI']
                   :none  # Never record in CI
                 else
                   :once  # Auto-record missing cassettes in development
                 end
```

### Manual Control

You can override the automatic behavior with environment variables:

```bash
# Force re-record all cassettes (overwrites existing)
VCR_RECORD=true bin/test spec/integration/

# Record only missing cassettes
VCR_RECORD=new_episodes bin/test spec/integration/

# Use only existing cassettes (fail if missing)
VCR_RECORD=none bin/test spec/integration/

# Simulate CI environment
CI=true bin/test spec/integration/
```

## Setup Details

### Environment Configuration

VCR is already configured in the project:
- `spec/support/vcr.rb` - Main VCR configuration with CI-aware recording
- `spec/support/env_helper.rb` - Smart API key management
- `spec/spec_helper.rb` - Loads VCR support
- `spec/cassettes/` - Directory where recordings are stored

### API Key Setup (Development Only)

1. **Get a Google AI API key**:
   - Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Create a new API key for testing
   - **Important**: Use a separate key for testing, not your production key

2. **Configure locally**:
   ```bash
   # Copy environment template
   cp spec/.env.example spec/.env
   
   # Edit spec/.env and add your key:
   echo "GEMINI_API_KEY=your_actual_api_key_here" >> spec/.env
   ```

**Note**: The helper picks up both `spec/.env` and repo-root `.env` files. API keys are only needed for recording new cassettes. Normal test runs and CI use pre-recorded cassettes without requiring any API keys.

## Writing Tests

### Basic VCR Test

```ruby
RSpec.describe "API Integration" do
  # Use the environment helper for consistent API key handling
  let(:api_key) { EnvHelper.gemini_api_key }

  it "queries Gemini with a simple prompt", :vcr do
    output, error, status = Open3.capture3(
      { "GEMINI_API_KEY" => api_key },
      exe_path,
      "What is 2+2? Reply with just the number."
    )

    expect(status).to be_success
    expect(output.strip).to match(/4/)
  end
end
```

### Custom Cassette Names

By default, cassettes are named after test descriptions. You can specify custom names:

```ruby
it "custom test", vcr: "my_custom_cassette_name" do
  # test code
end
```

### Custom VCR Options

```ruby
it "test with custom options", vcr_options: { match_requests_on: [:method, :uri] } do
  # test code
end
```

## Recording Scenarios

### Adding New Tests

1. Write test with `:vcr` tag
2. Run test - VCR automatically records missing cassettes
3. Commit cassette file

### Updating API Responses

1. Delete specific cassette file:
   ```bash
   rm spec/cassettes/path/to/specific_cassette.yml
   ```

2. Run test - VCR automatically re-records:
   ```bash
   bin/test spec/integration/your_test.rb
   ```

### Major API Changes

1. Remove all cassettes and re-record:
   ```bash
   rm -rf spec/cassettes/
   VCR_RECORD=true bin/test spec/integration/
   ```

2. Review all changes and commit:
   ```bash
   git diff spec/cassettes/
   git add spec/cassettes/
   git commit -m "Update VCR cassettes for API changes"
   ```

## Security Features

### Automatic Data Filtering

VCR automatically removes sensitive data from cassettes:

```ruby
# API keys in headers (X-Goog-Api-Key)
config.filter_sensitive_data('<GEMINI_API_KEY>') do |interaction|
  interaction.request.headers['X-Goog-Api-Key']&.first
end

# API keys in query parameters (?key=abc123)
config.filter_sensitive_data('<GEMINI_API_KEY>') do |interaction|
  # Extracts and filters API keys from URLs
end

# Authorization headers
config.filter_sensitive_data('<AUTHORIZATION>') do |interaction|
  interaction.request.headers['Authorization']&.first
end
```

### Safe Defaults

- **CI Environment**: Always uses test keys, never makes API calls
- **Development**: Uses test keys unless real key is explicitly provided
- **Git Integration**: Real API keys are gitignored, cassettes are committed with filtered data

## File Structure

```
spec/
├── .env.example          # Template for environment variables
├── .env                  # Your actual config (gitignored)
├── cassettes/            # VCR recordings (committed to repository)
│   └── llm-gemini-query_integration/
│       ├── API_integration/
│       │   ├── with_valid_API_key/
│       │   │   ├── queries_Gemini_with_a_simple_prompt.yml
│       │   │   └── outputs_JSON_format_when_requested.yml
│       │   └── with_invalid_API_key/
│       └── command_execution/
├── integration/
│   └── llm_gemini_query_integration_spec.rb
└── support/
    ├── vcr.rb           # CI-aware VCR configuration
    └── env_helper.rb    # Smart environment management
```

## CI/CD Integration

### GitHub Actions

```yaml
# In .github/workflows/test.yml
- name: Run tests with VCR
  run: bin/test spec/integration/
  env:
    CI: true  # VCR automatically uses cassettes-only mode
    # No GEMINI_API_KEY needed - uses recorded cassettes
```

### What Happens in CI

1. **No API Keys Required**: CI runs entirely from pre-recorded cassettes
2. **Fast Execution**: No external API calls mean faster test runs
3. **Deterministic Results**: No network issues or rate limits
4. **Automatic Detection**: CI platforms set `CI=true` by default

## Troubleshooting

### Common Issues

1. **"No cassette found" errors**:
   ```bash
   # Record the missing cassette
   bin/test spec/path/to/failing_test.rb
   ```

2. **API key required for recording**:
   ```bash
   # Set up your API key in spec/.env
   echo "GEMINI_API_KEY=your_key_here" >> spec/.env
   ```

3. **Request mismatches**:
   - VCR matches on method, URI, headers, and body
   - Small changes in requests may require re-recording
   - Check cassette names match test descriptions

### Debugging VCR

Enable debug logging:

```bash
# Enable VCR debug output
TEST_DEBUG=true bin/test spec/integration/

# View debug log
cat vcr_debug.log
```

Check cassette contents:

```bash
# List all cassettes
find spec/cassettes -name "*.yml" -type f

# View specific cassette
cat spec/cassettes/your_test_cassette.yml

# Check for API key leaks (should show <GEMINI_API_KEY>)
grep -r "GEMINI_API_KEY" spec/cassettes/
```

### Verifying Security

Always check that sensitive data is filtered:

```bash
# These should NOT appear in cassettes:
grep -r "your_actual_api_key" spec/cassettes/  # Should be empty
grep -r "AIza" spec/cassettes/                 # Should be empty (Google API key prefix)

# These SHOULD appear (filtered placeholders):
grep -r "<GEMINI_API_KEY>" spec/cassettes/     # Should show filtered keys
```

## Best Practices

### Development Workflow

1. **Let VCR auto-record** - it handles missing cassettes automatically
2. **Use `VCR_RECORD=true` sparingly** - only when you need to overwrite existing cassettes
3. **Review cassettes before committing** to ensure no sensitive data leaked
4. **Use descriptive test names** - they become cassette filenames
5. **Keep tests focused** - one API interaction per test when possible

### Integration Test Performance

1. **Use ProcessHelpers for subprocess tests** - Properly integrates with VCR for subprocess API calls
2. **Avoid `system()` calls in integration tests** - They don't inherit VCR configuration
3. **Capture stdout/stderr properly** - Use `execute_gem_executable()` to prevent pollution
4. **Make tests deterministic** - Avoid random values that break VCR matching
5. **Check test performance** - VCR tests should be fast (~0.3s), slow tests indicate real API calls

### Subprocess VCR Integration

When writing integration tests that spawn subprocesses (like testing CLI commands):

```ruby
# ❌ Don't use system() calls - they bypass VCR
system("bundle exec exe/your-command", "arg1", "arg2")

# ✅ Use ProcessHelpers for proper VCR integration
include ProcessHelpers

it "runs command with VCR", :vcr do
  env = vcr_subprocess_env("test_name")
  stdout, stderr, status = execute_gem_executable("your-command", ["arg1", "arg2"], env: env)
  
  expect(status).to be_success
  expect(stdout).to include("expected output")
end
```

### Handling Dynamic Content in Tests

When tests contain dynamic content (like timestamps, random IDs, or temporary file paths):

```ruby
# ❌ Don't use random values that change each run
non_existent = "/tmp/does_not_exist_#{rand(10000)}.txt"

# ✅ Use fixed values for deterministic cassettes
non_existent = "/tmp/does_not_exist_test_file.txt"

# For truly dynamic content, use custom VCR matchers:
it "handles dynamic content", vcr_options: { match_requests_on: [:method, :uri, :body_without_dynamic_parts] } do
  # Test code with dynamic content
end
```

### Security Guidelines

1. **Never commit real API keys** to the repository
2. **Use dedicated test API keys** separate from production
3. **Rotate test keys regularly** and use minimal permissions
4. **Always verify filtering worked** before committing cassettes
5. **Set up git hooks** to prevent accidental key commits

### Debugging Slow or Failing Tests

When integration tests are unexpectedly slow or failing:

1. **Check if VCR is working**:
   ```bash
   # Look for cassette creation
   find spec/cassettes -name "*.yml" -mtime -1  # Recent cassettes
   
   # Run specific test and check timing
   bin/test spec/integration/your_test.rb -e "specific test"
   ```

2. **Signs of bypassed VCR**:
   - Tests taking >1 second (should be ~0.3s with cassettes)
   - Network errors in CI
   - API rate limit errors
   - Different results between runs

3. **Common fixes**:
   - Ensure test uses `:vcr` tag
   - Use ProcessHelpers for subprocess calls
   - Check VCR cassette name generation
   - Verify environment variables are set correctly

4. **Performance benchmarking**:
   ```bash
   # Before optimization
   Top 10 slowest examples (38.2 seconds, 57.5% of total time):
     test_name: 12.48 seconds  # ❌ Making real API calls
   
   # After VCR optimization  
   Top 10 slowest examples (4.67 seconds, 58.4% of total time):
     test_name: 0.32 seconds   # ✅ Using VCR cassettes
   ```

### CI/CD Guidelines

1. **No API keys in CI** - rely on pre-recorded cassettes
2. **Include cassettes in repository** - don't generate them in CI
3. **Monitor for missing cassettes** in CI failures
4. **Keep cassettes up to date** with API changes
5. **Watch for stdout pollution** - clean test output indicates proper VCR usage
6. **Validate test performance** - CI should have fast, consistent timing

## Environment Variables Reference

| Variable | Values | Description |
|----------|--------|-------------|
| `CI` | `true`/unset | Automatically set by CI platforms, switches VCR to cassettes-only mode |
| `VCR_RECORD` | `true`, `new_episodes`, `none` | Override default recording behavior |
| `TEST_DEBUG` | `true`/unset | Enable detailed VCR logging and debug output |
| `GEMINI_API_KEY` | Your API key | Required for recording new cassettes (development only) |

## Quick Reference Commands

```bash
# Normal development
bin/test spec/integration/                    # Run tests (auto-records missing)

# Explicit recording control  
VCR_RECORD=true bin/test spec/integration/    # Re-record all cassettes
VCR_RECORD=new_episodes bin/test spec/        # Record only missing
VCR_RECORD=none bin/test spec/integration/    # Cassettes only (fail if missing)

# Debug and troubleshooting
TEST_DEBUG=true bin/test spec/integration/    # Enable debug output
CI=true bin/test spec/integration/            # Simulate CI environment

# Cassette management
find spec/cassettes -name "*.yml" -type f     # List all cassettes
rm -rf spec/cassettes/                        # Remove all cassettes
rm spec/cassettes/path/to/specific.yml        # Remove specific cassette

# Performance debugging
bin/test spec/integration/ | grep "slowest"   # Check test performance
find spec/cassettes -name "*.yml" -mtime -1   # Find recently created cassettes
```

This CI-aware VCR configuration provides a seamless testing experience that automatically adapts to your environment while maintaining security and reliability.