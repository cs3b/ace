# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require_relative "support/test_factory"
require_relative "support/llm_mock_helper"
require_relative "support/shell_mock_helper"
require_relative "support/tree_assertions_helper"
require_relative "support/mock_repo_context"

# Base test case for ace-taskflow tests
class AceTaskflowTestCase < Ace::TestSupport::BaseTestCase
  include LlmMockHelper
  include TreeAssertionsHelper
  # ConfigHelpers provides with_real_config and related config testing utilities
  # Loads real gem defaults from .ace-defaults/ and merges with test configuration
  include Ace::TestSupport::ConfigHelpers

  # Reset cached configuration and data before each test to ensure test isolation
  # This is important since ADR-022 caches gem defaults and configuration for performance
  # Also clears TaskLoader and ReleaseResolver caches to prevent stale data between tests
  def setup
    super
    require "ace/taskflow"
    require "ace/taskflow/molecules/config_loader"
    require "ace/taskflow/molecules/task_loader"
    require "ace/taskflow/molecules/release_resolver"
    Ace::Taskflow::Molecules::ConfigLoader.reset_gem_defaults!
    Ace::Taskflow.reset_configuration!
    # Clear per-command caches to ensure test isolation
    Ace::Taskflow::Molecules::TaskLoader.clear_cache!
    Ace::Taskflow::Molecules::ReleaseResolver.clear_cache!
  end

  # Creates a test project directory with sample task fixtures.
  # Use this for tests that need a realistic project structure with tasks.
  #
  # @yield [dir] Yields the test project directory path
  #
  # @example Basic usage
  #   with_test_project do |dir|
  #     assert File.directory?(File.join(dir, ".ace-taskflow"))
  #   end
  def with_test_project(&block)
    TestFactory.with_test_directory(&block)
  end

  # Creates a clean project directory without any task fixtures.
  # Use this for tests that need an empty project structure.
  #
  # @yield [dir] Yields the clean project directory path
  #
  # @example Basic usage
  #   with_clean_project do |dir|
  #     refute File.exist?(File.join(dir, ".ace-taskflow"))
  #   end
  def with_clean_project(&block)
    TestFactory.with_clean_project(&block)
  end

  # Composite helper: Combines with_real_config + with_test_project + Dir.chdir
  # Reduces nesting from 3 levels to 1 for tests that need real filesystem config
  # and test project fixtures, automatically changing to the project directory.
  #
  # @yield [dir] Yields the test project directory path (already chdir'd into)
  #
  # @example Usage (reduces nesting)
  #   # Before: 3 levels of nesting
  #   with_real_config do
  #     with_test_project do |dir|
  #       Dir.chdir(dir) { }
  #     end
  #   end
  #
  #   # After: 0 levels of nesting
  #   with_real_test_project do |dir|
  #     # Already chdir'd into dir, ready to test
  #   end
  def with_real_test_project(&block)
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) { yield dir }
      end
    end
  end

  # Composite helper: Combines with_real_config + Dir.mktmpdir + Dir.chdir
  # Use this for tests that need real config and a temporary directory, but
  # not the full test project fixtures.
  #
  # @yield [dir] Yields the temporary directory path (already chdir'd into)
  #
  # @example Usage
  #   with_real_tmpdir do |dir|
  #     # Create custom test setup without project fixtures
  #     File.write("custom.yml", "content")
  #   end
  def with_real_tmpdir(&block)
    with_real_config do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { yield dir }
      end
    end
  end
end
