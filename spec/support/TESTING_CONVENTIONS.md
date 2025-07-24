# Testing Conventions and Patterns

This document outlines the established testing conventions for the comprehensive unit test implementation covering 107+ untested files in the dev-tools Ruby gem.

## Overview

Our testing strategy follows the ATOM architecture pattern with comprehensive coverage, proper isolation, and consistent patterns across all layers.

## Test Organization

### Directory Structure

```
spec/
├── coding_agent_tools/
│   ├── atoms/               # Pure unit tests, no external dependencies
│   │   ├── code_quality/    # Code validation components
│   │   ├── git/            # Git operation atoms
│   │   └── task_management/ # Task handling atoms
│   ├── molecules/          # Composed behavior tests
│   ├── organisms/          # Business logic integration tests
│   └── cli/               # CLI command tests
├── integration/           # End-to-end tests
├── unit/                 # Legacy unit tests (being migrated)
└── support/              # Test helpers and utilities
```

### Naming Conventions

- Test files: `{component_name}_spec.rb`
- Mirror the `lib/` directory structure exactly in `spec/`
- Use descriptive test contexts and examples
- Group related tests with `describe`, `context`, and `it`

## ATOM Testing Strategy

### Atoms Layer
- **Pure unit tests** with no external dependencies
- Use doubles/stubs for all I/O operations
- Test individual methods in isolation
- Comprehensive edge cases and error conditions
- Example: `SecurityValidator`, `ConfigurationLoader`

### Molecules Layer
- Test **composed behavior** and orchestration logic
- Mock underlying atoms as needed
- Focus on business logic flow
- Test error propagation between components

### Organisms Layer
- **Integration-style tests** with real atoms/molecules
- Mock only external services (APIs, file system, etc.)
- Test complete workflow coordination
- Validate system-level behavior

### CLI Commands
- Use existing `CliHelpers` for direct command invocation
- Mock underlying service layers
- Test argument parsing, error handling, output formatting
- Include help text and usage validation

## Test Helpers and Utilities

### MockHelpers (`spec/support/mock_helpers.rb`)

Provides consistent mocking patterns for external dependencies:

```ruby
# Git operations
GitMockData.status_clean
GitMockData.command_error

# File system operations
mock_file_exists("/path/to/file", true)
mock_directory_listing("/path", ["file1.rb", "file2.rb"])

# System commands
mock_system_command("git status", success: true, output: "clean")
mock_git_command("status", GitMockData.status_clean)

# LLM API responses
LLMResponseMocks.google_success_response
LLMResponseMocks.api_error_response(401)

# Environment variables
with_mocked_env("API_KEY" => "test_key") do
  # test code
end
```

### TestFactories (`spec/support/test_factories.rb`)

Factory methods for creating complex test data:

```ruby
# Task management
TaskFactory.valid_task_metadata
TaskFactory.completed_task

# File structures
FileTreeFactory.typical_ruby_project
FileTreeFactory.task_directory_structure

# Git states
GitStateFactory.clean_repository
GitStateFactory.dirty_repository

# CLI outputs
CLIOutputFactory.help_output("command-name")
CLIOutputFactory.json_output(data)

# HTTP responses
HTTPResponseFactory.success_response(body, 200)
HTTPResponseFactory.error_response("Not found", 404)
```

## Common Testing Patterns

### Basic Test Structure

```ruby
require "spec_helper"
require "coding_agent_tools/atoms/example/component"

RSpec.describe CodingAgentTools::Atoms::Example::Component do
  subject { described_class.new(options) }
  let(:options) { {} }

  describe "#method_name" do
    context "with valid input" do
      it "returns expected result" do
        result = subject.method_name
        expect(result).to eq(expected_value)
      end
    end

    context "with invalid input" do
      it "raises appropriate error" do
        expect { subject.method_name }.to raise_error(CustomError)
      end
    end
  end
end
```

### File System Testing

```ruby
let(:temp_dir) { Dir.mktmpdir }
let(:config_file) { File.join(temp_dir, "config.yml") }

before do
  File.write(config_file, YAML.dump(config_data))
end

after do
  FileUtils.rm_rf(temp_dir)
end
```

### External Command Testing

```ruby
before do
  mock_system_command("git status", 
    success: true, 
    output: "On branch main\nnothing to commit"
  )
end

it "executes git command with correct parameters" do
  expect(Open3).to receive(:capture3).with("git status --porcelain")
  subject.check_status
end
```

### HTTP/API Testing

```ruby
context "when API call succeeds", :vcr do
  let(:cassette_name) { "component/api_success" }
  
  it "processes response correctly" do
    env = vcr_subprocess_env(cassette_name, "API_KEY" => api_key)
    result = subject.call_api
    expect(result[:success]).to be true
  end
end
```

### Configuration Testing

```ruby
let(:config) { ConfigFactory.default_config }

before do
  allow(subject).to receive(:load_config).and_return(config)
end

it "uses configuration values correctly" do
  expect(subject.provider).to eq(config["default_provider"])
end
```

## Error Handling Patterns

### Testing Exceptions

```ruby
context "when external service is unavailable" do
  before do
    allow(subject).to receive(:call_service).and_raise(ServiceUnavailable)
  end

  it "handles service errors gracefully" do
    expect { subject.process }.to raise_error(ServiceUnavailable)
  end
end
```

### Testing Error Recovery

```ruby
context "when operation fails initially but succeeds on retry" do
  before do
    allow(subject).to receive(:operation)
      .and_raise(TemporaryError).once
      .and_return(success_result)
  end

  it "retries and succeeds" do
    result = subject.process_with_retry
    expect(result).to eq(success_result)
  end
end
```

## Coverage Requirements

- **Minimum 95% line coverage** for all new test files
- **Comprehensive edge cases** including boundary conditions
- **Error conditions** must be thoroughly tested
- **Security validations** for input sanitization and path traversal
- **Performance considerations** for large data sets

## Test Data Management

### Realistic Test Data
- Use actual command outputs and API responses as templates
- Include both success and failure scenarios
- Test with various data sizes (empty, normal, large)
- Handle special characters and edge cases

### Security Testing
- Test path traversal attempts
- Validate input sanitization
- Test with malicious payloads
- Verify secure defaults

## Performance Testing Guidelines

- Test execution time should be reasonable (< 30 seconds for full suite)
- Use mocking to avoid slow external calls
- Test with large datasets where applicable
- Measure and optimize slow tests

## Integration with Existing Infrastructure

### VCR Cassettes
- Use existing VCR setup for HTTP interactions
- Create provider-specific cassettes for LLM APIs
- Include both success and error scenarios
- Name cassettes descriptively: `component/provider/scenario`

### CI/CD Integration
- All tests must pass in CI environment
- No interactive prompts (ensured by `CI=true`)
- Proper cleanup of temporary files
- Deterministic test results

## Migration Strategy

1. **Prioritize by Risk**: Start with security-critical components
2. **Follow ATOM Layers**: Complete atoms before molecules/organisms  
3. **Maintain Backward Compatibility**: Don't break existing tests
4. **Incremental Coverage**: Aim for steady coverage improvements
5. **Team Reviews**: Ensure consistency across contributors

## Examples and References

- **Security Validator Test**: `spec/coding_agent_tools/atoms/code_quality/security_validator_spec.rb`
- **Configuration Loader Test**: `spec/coding_agent_tools/atoms/code_quality/configuration_loader_spec.rb`
- **Integration Test Pattern**: `spec/integration/llm_query_integration_spec.rb`
- **CLI Test Pattern**: Existing CLI command tests in `spec/integration/`

These examples demonstrate comprehensive coverage with proper mocking, edge cases, and error handling patterns that should be replicated across all new test files.