---
id: v.0.9.0+task.003
status: pending
priority: high
estimate: 4h
dependencies: [v.0.9.0+task.001, v.0.9.0+task.002]
---

# Set Up Minitest for ace-core

## Objective

Establish comprehensive Minitest infrastructure for ace-core that can be reused by all other gems. This provides the foundation for test-driven development and ensures config cascade functionality works correctly.

## Scope of Work

- Create test helper with shared setup
- Write tests for config cascade resolution
- Test .env file handling
- Test YAML deep-merge functionality
- Create test fixtures for config files
- Set up rake test task

### Deliverables

#### Create

- ace-core/test/test_helper.rb
- ace-core/test/config_resolver_test.rb
- ace-core/test/yaml_loader_test.rb
- ace-core/test/env_handler_test.rb
- ace-core/test/fixtures/.ace/core/config/core.yml
- ace-core/test/fixtures/.env
- ace-core/test/fixtures/config/core.yml
- Updates to ace-core/Rakefile

## Implementation Plan

### Planning Steps

* [ ] Design test directory structure
* [ ] Plan fixture organization
* [ ] Determine test coverage goals
* [ ] Review minitest best practices

### Execution Steps

- [ ] Create test_helper.rb with common setup
  ```ruby
  require 'minitest/autorun'
  require 'minitest/reporters'
  require 'ace/core'

  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

  class AceTestCase < Minitest::Test
    def fixture_path(path)
      File.expand_path("fixtures/#{path}", __dir__)
    end
  end
  ```

- [ ] Create config_resolver_test.rb
  ```ruby
  class ConfigResolverTest < AceTestCase
    def test_cascade_precedence
      # Test: local > home > gem defaults
    end

    def test_deep_merge_strategy
      # Test: nested hash merging
    end
  end
  ```
  > TEST: Run config resolver tests
  > Type: Unit Test
  > Assert: All precedence rules work correctly
  > Command: cd ace-core && rake test TEST=test/config_resolver_test.rb

- [ ] Create yaml_loader_test.rb
  ```ruby
  class YamlLoaderTest < AceTestCase
    def test_loads_valid_yaml
      # Test: YAML parsing succeeds
    end

    def test_handles_missing_file
      # Test: Graceful handling of missing files
    end
  end
  ```
  > TEST: Run YAML loader tests
  > Type: Unit Test
  > Assert: YAML operations work correctly
  > Command: cd ace-core && rake test TEST=test/yaml_loader_test.rb

- [ ] Create env_handler_test.rb
  ```ruby
  class EnvHandlerTest < AceTestCase
    def test_loads_env_file
      # Test: .env file parsing
    end

    def test_env_override_precedence
      # Test: .env overrides system env
    end
  end
  ```
  > TEST: Run env handler tests
  > Type: Unit Test
  > Assert: Environment handling works
  > Command: cd ace-core && rake test TEST=test/env_handler_test.rb

- [ ] Create test fixtures
  ```bash
  mkdir -p test/fixtures/.ace/core/config
  mkdir -p test/fixtures/config
  ```

- [ ] Add fixture config files
  ```yaml
  # test/fixtures/.ace/core/config/core.yml
  ace:
    test_mode: true
    override: "local"
  ```

- [ ] Set up Rake test task
  ```ruby
  # Rakefile
  require 'rake/testtask'

  Rake::TestTask.new do |t|
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose = true
  end

  task default: :test
  ```

- [ ] Run full test suite
  > TEST: All tests pass
  > Type: Test Suite
  > Assert: 100% pass rate
  > Command: cd ace-core && rake test

## Acceptance Criteria

- [ ] Test helper provides reusable utilities
- [ ] Config cascade tests cover all precedence rules
- [ ] YAML merge tests verify deep merge behavior
- [ ] Env handler tests confirm .env loading
- [ ] Fixtures organized and maintainable
- [ ] Rake test task runs all tests
- [ ] Tests can be run individually or as suite
- [ ] Minitest reporters provide clear output

## Out of Scope

- ❌ Code coverage reporting (add later)
- ❌ Performance benchmarks
- ❌ Integration with CI/CD
- ❌ Mutation testing