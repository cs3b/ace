# ace-test-support

Shared test utilities for all ace-* gems.

## Purpose

This development-only gem provides:
- Base test case classes with common assertions
- Test helper methods for temporary files and directories
- Configuration testing utilities with cascade support
- Isolated test environment management
- Minitest reporters configuration

## Installation

This gem is automatically included in the test group of ace-* gems:

```ruby
# In ace-*/ace-*.gemspec
spec.add_development_dependency 'ace-test-support', '~> 0.9.0'
```

## Usage

### In Your Test Helper

```ruby
# test/test_helper.rb
require 'ace/test_support'

# Your gem-specific requires
require 'ace/context'
```

### Base Test Case

```ruby
class MyTest < AceTestCase
  def test_something
    # Access to all test helpers
    with_temp_dir do |dir|
      # Test in isolated directory
    end
  end
end
```

### Config Testing

```ruby
class ConfigTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def test_config_cascade
    with_cascade_configs("context", {
      project: { "ace" => { "context" => { "setting" => "project" } } },
      home: { "ace" => { "context" => { "setting" => "home" } } }
    }) do
      # Test config resolution
    end
  end
end
```

### Integration Testing

```ruby
class IntegrationTest < AceTestCase
  def setup
    @env = Ace::TestSupport::TestEnvironment.new("context")
    @env.setup
  end

  def teardown
    @env.teardown
  end

  def test_full_integration
    @env.write_config(:project, "config.yml", sample_config)
    # Test with isolated environment
  end
end
```

## Test Utilities

### TestHelper Module
- `with_temp_dir` - Execute in temporary directory
- `with_temp_file` - Create temporary file
- `create_config_file` - Create config file with directory creation
- `assert_file_exists` - Assert file exists
- `assert_file_content` - Assert file content matches
- `assert_directory_exists` - Assert directory exists
- `capture_subprocess_io` - Capture stdout/stderr

### ConfigHelpers Module
- `with_config` - Temporary config file
- `with_env` - Temporary environment variables
- `with_cascade_configs` - Multi-level config setup
- `sample_config` - Generate sample configurations
- `assert_config_structure` - Verify config structure

### TestEnvironment Class
- Complete isolation with temp directories
- Separate home, project, and gem directories
- Environment variable management
- Config directory creation helpers

## Development

This gem is part of the ace-meta project and shares the root Gemfile dependencies.