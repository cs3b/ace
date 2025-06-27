# Testing Guide for coding-agent-tools

This document explains how to run and record tests for the coding-agent-tools project, particularly the integration tests that use VCR (Video Cassette Recorder) to record and replay HTTP interactions with external APIs.

## Test Structure

- `spec/unit/` - Unit tests for individual components
- `spec/integration/` - Integration tests that test the full command-line tools
- `spec/support/` - Shared test helpers and configuration
- `spec/cassettes/` - VCR cassettes (recorded HTTP interactions)

### LMS Integration Tests

LMS (Language Model Studio) integration tests use VCR for both API calls and availability checks:

- **Availability checks**: VCR-wrapped probes to `http://localhost:1234/v1/models`
- **API interactions**: Full LMS API calls recorded in cassettes
- **CI-safe**: All HTTP interactions are mocked, preventing CI fragility

## Environment Setup

### 1. Copy Environment Configuration

```bash
# Copy the example files and customize them
cp .env.example .env
cp spec/.env.example spec/.env
```

### 2. Configure API Keys (Development Only)

Edit `spec/.env` and add your actual API keys for recording new cassettes:

```bash
# Required for recording new cassettes in development
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

Get your Gemini API key from: <https://makersuite.google.com/app/apikey>

**Note:** API keys are only needed for recording. Normal test runs and CI use pre-recorded cassettes.

## Running Tests

### Default Mode (Smart Recording)

VCR is configured to be CI-aware and automatically handle recording:

```bash
# Run all tests
bundle exec rspec

# Run only integration tests
bundle exec rspec spec/integration/

# Run specific test file
bundle exec rspec spec/integration/llm_gemini_query_integration_spec.rb

# Run with debug output
TEST_DEBUG=true bundle exec rspec
```

**In Development:** VCR automatically records missing cassettes when you have an API key configured.
**In CI:** VCR only uses existing cassettes and never makes external API calls.

### Manual Recording Control

When you need explicit control over recording behavior:

```bash
# Force re-record all cassettes (overwrites existing)
VCR_RECORD=true bundle exec rspec spec/integration/

# Record only missing cassettes
VCR_RECORD=new_episodes bundle exec rspec spec/integration/

# Use only existing cassettes (fail if missing)
VCR_RECORD=none bundle exec rspec spec/integration/

# Simulate CI environment
CI=true bundle exec rspec spec/integration/
```

### Recording Modes

- Default (no VCR_RECORD set):
  - **Development:** Record missing cassettes automatically
  - **CI:** Use existing cassettes only, never record
- `VCR_RECORD=new_episodes` - Record new interactions, replay existing ones
- `VCR_RECORD=true` - Re-record all interactions (overwrites existing cassettes)
- `VCR_RECORD=none` - Never make HTTP calls, fail if cassette missing

## Working with VCR Cassettes

### Cassette Location

Cassettes are stored in `spec/cassettes/` with names based on the test descriptions:

```
spec/cassettes/
├── llm-gemini-query_integration/
│   ├── API_integration_with_valid_API_key_queries_Gemini_with_a_simple_prompt.yml
│   ├── API_integration_with_valid_API_key_outputs_JSON_format_when_requested.yml
│   └── ...
├── llm_lmstudio_query_integration/
│   ├── queries_lm_studio_with_simple_prompt.yml
│   ├── outputs_json_format.yml
│   └── ...
└── lm_studio_availability_check.yml
```

### LMS-Specific Cassettes

- `lm_studio_availability_check.yml` - Records availability probe responses
- `llm_lmstudio_query_integration/` - Contains all LMS API interaction recordings

### Cassette Content

Cassettes contain:

- HTTP request details (method, URL, headers, body)
- HTTP response details (status, headers, body)
- Sensitive data is automatically filtered (API keys, etc.)

### Managing Cassettes

```bash
# Delete all cassettes to force re-recording
rm -rf spec/cassettes/

# Delete specific cassette
rm spec/cassettes/path/to/specific_cassette.yml

# View cassette content
cat spec/cassettes/path/to/cassette.yml
```

## Test Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GEMINI_API_KEY` | - | Google Gemini API key (required for recording) |
| `VCR_RECORD` | `false` | VCR recording mode |
| `TEST_DEBUG` | `false` | Enable debug output |
| `TEST_TIMEOUT` | `30` | Test timeout in seconds |

### Debug Mode

Enable detailed output during test runs:

```bash
TEST_DEBUG=true bundle exec rspec

# Or set in spec/.env:
# TEST_DEBUG=true
```

Debug mode shows:

- VCR recording/playback mode
- API key status
- Detailed VCR interactions (logged to `vcr_debug.log`)

## Common Workflows

### Adding New Integration Tests

1. Write your test with the `:vcr` tag:

   ```ruby
   it "does something with the API", :vcr do
     # Test code that makes HTTP requests
   end
   ```

2. Run the test (VCR automatically records missing cassettes):

   ```bash
   bundle exec rspec spec/path/to/your_test.rb
   ```

3. Verify the cassette was created and commit it

### Updating Existing Tests

1. Delete the relevant cassette file:

   ```bash
   rm spec/cassettes/path/to/cassette.yml
   ```

2. Run the test (VCR automatically re-records):

   ```bash
   bundle exec rspec spec/path/to/test.rb
   ```

### Testing API Changes

1. Remove existing cassettes and re-record:

   ```bash
   rm -rf spec/cassettes/
   VCR_RECORD=true bundle exec rspec spec/integration/
   ```

2. Review the updated cassettes
3. Commit the changes

## Troubleshooting

### "Recording requires real GEMINI_API_KEY"

This error occurs when explicitly recording (`VCR_RECORD=true`) without a valid API key.

**Solution:** Set a real API key in `spec/.env`:

```bash
GEMINI_API_KEY=your_actual_api_key_here
```

### Tests fail with "No cassette found"

This happens when in CI mode or when `VCR_RECORD=none` and a cassette is missing.

**Solution:** Record the missing cassette in development:

```bash
bundle exec rspec path/to/failing/test.rb
```

### API key appears in cassettes

VCR should automatically filter sensitive data, but if you see API keys in cassettes:

1. Check the VCR configuration in `spec/support/vcr.rb`
2. Delete the cassette and re-record
3. Verify the `filter_sensitive_data` configuration

### Rate limiting errors

If you hit API rate limits while recording:

1. Wait for the rate limit to reset
2. Run individual test files instead of the entire suite
3. Use existing cassettes when possible (avoid `VCR_RECORD=true`)

## Best Practices

### For Test Authors

1. **Use descriptive test names** - they become cassette filenames
2. **Keep tests focused** - one API interaction per test when possible
3. **Use custom cassette names** for shared scenarios:

   ```ruby
   it "does something", vcr: "custom_cassette_name" do
   ```

### For Cassette Management

1. **Commit cassettes** - they're part of the test suite
2. **Review cassette changes** - ensure no sensitive data is exposed
3. **Keep cassettes up to date** - re-record when APIs change
4. **Delete unused cassettes** - clean up when removing tests

### For CI/CD

1. **Set CI=true** - VCR automatically uses cassettes-only mode
2. **Include cassettes in your repository** - don't generate them in CI
3. **No API keys needed** - CI runs entirely from pre-recorded cassettes

## Security Notes

- API keys are automatically filtered from cassettes
- Never commit real API keys to the repository
- Use the test-specific `.env` file for sensitive configuration
- Review cassettes before committing to ensure no sensitive data is present
