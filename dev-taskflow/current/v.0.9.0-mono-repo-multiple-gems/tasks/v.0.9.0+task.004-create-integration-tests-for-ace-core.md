---
id: v.0.9.0+task.004
status: pending
priority: high
estimate: 3h
dependencies: [v.0.9.0+task.003]
---

# Create Integration Tests for ace-core

## Objective

Build integration tests that verify ace-core's config cascade system works end-to-end with multiple config sources. Create reusable test utilities that other gems can leverage for their own integration testing.

## Scope of Work

- Test config loading from multiple sources
- Verify precedence rules (project → home → gem defaults)
- Test error handling scenarios
- Create reusable test utilities for other gems
- Document integration testing patterns

### Deliverables

#### Create

- ace-core/test/integration/config_cascade_test.rb
- ace-core/test/integration/multi_source_test.rb
- ace-core/test/support/test_environment.rb
- ace-core/test/support/config_helpers.rb
- ace-core/test/integration/fixtures/ (directory structure)

## Implementation Plan

### Planning Steps

* [ ] Design integration test scenarios
* [ ] Plan test environment isolation
* [ ] Identify reusable patterns for other gems
* [ ] Review integration testing best practices

### Execution Steps

- [ ] Create test environment helper
  ```ruby
  # test/support/test_environment.rb
  class TestEnvironment
    attr_reader :temp_dir, :home_dir

    def setup
      @temp_dir = Dir.mktmpdir('ace-test')
      @home_dir = File.join(@temp_dir, 'home')
      Dir.mkdir(@home_dir)
      ENV['HOME'] = @home_dir
    end

    def teardown
      FileUtils.rm_rf(@temp_dir) if @temp_dir
    end
  end
  ```

- [ ] Create config helpers
  ```ruby
  # test/support/config_helpers.rb
  module ConfigHelpers
    def with_config(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content.to_yaml)
      yield
    ensure
      FileUtils.rm_f(path)
    end

    def with_env(vars)
      old = vars.keys.map { |k| [k, ENV[k]] }.to_h
      vars.each { |k, v| ENV[k] = v }
      yield
    ensure
      old.each { |k, v| ENV[k] = v }
    end
  end
  ```

- [ ] Create config cascade integration test
  ```ruby
  # test/integration/config_cascade_test.rb
  class ConfigCascadeTest < AceTestCase
    include ConfigHelpers

    def setup
      @env = TestEnvironment.new
      @env.setup
    end

    def teardown
      @env.teardown
    end

    def test_full_cascade_resolution
      # Create configs at all levels
      # Verify correct precedence
    end
  end
  ```
  > TEST: Config cascade integration
  > Type: Integration Test
  > Assert: All config sources resolve correctly
  > Command: cd ace-core && rake test TEST=test/integration/config_cascade_test.rb

- [ ] Create multi-source integration test
  ```ruby
  # test/integration/multi_source_test.rb
  class MultiSourceTest < AceTestCase
    def test_combines_env_and_config
      # Test .env + YAML working together
    end

    def test_handles_partial_configs
      # Test when some config sources missing
    end
  end
  ```
  > TEST: Multi-source config loading
  > Type: Integration Test
  > Assert: Different config sources combine correctly
  > Command: cd ace-core && rake test TEST=test/integration/multi_source_test.rb

- [ ] Set up integration test fixtures
  ```bash
  mkdir -p test/integration/fixtures/{project,home,defaults}
  ```

- [ ] Create sample configs at each level
  ```yaml
  # test/integration/fixtures/defaults/core.yml
  ace:
    level: "default"
    shared: "from_default"
  ```

- [ ] Test error handling scenarios
  ```ruby
  def test_handles_malformed_yaml
    # Verify graceful error handling
  end

  def test_handles_missing_directories
    # Verify fallback behavior
  end
  ```

- [ ] Document integration patterns in README
  ```markdown
  ## Integration Testing

  ace-core provides test utilities for integration testing:
  - TestEnvironment: Isolated test environment
  - ConfigHelpers: Config file management
  - Fixture helpers: Sample config generation
  ```

- [ ] Run full integration suite
  > TEST: All integration tests pass
  > Type: Test Suite
  > Assert: End-to-end scenarios work
  > Command: cd ace-core && rake test TEST=test/integration/*_test.rb

## Acceptance Criteria

- [ ] Integration tests cover full cascade resolution
- [ ] Multi-source scenarios tested
- [ ] Error conditions handled gracefully
- [ ] Test utilities are reusable by other gems
- [ ] Test environment properly isolated
- [ ] Documentation explains testing patterns
- [ ] All integration tests pass

## Out of Scope

- ❌ Performance testing
- ❌ Stress testing with large configs
- ❌ Network-based config sources
- ❌ Concurrent access testing