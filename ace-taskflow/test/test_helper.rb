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

  # Make TestFactory module methods available as instance methods
  def with_test_project(&block)
    TestFactory.with_test_directory(&block)
  end

  def with_clean_project(&block)
    TestFactory.with_clean_project(&block)
  end

  # Composite helper: Combines with_real_config + with_test_project
  # Reduces nesting from 3 levels to 1 for tests that need real filesystem config
  #
  # @yield [dir] Yields the test project directory path
  #
  # @example Usage (reduces nesting)
  #   # Before: 3 levels of nesting
  #   with_real_config do
  #     with_test_project do |dir|
  #       Dir.chdir(dir) { }
  #     end
  #   end
  #
  #   # After: 1 level of nesting
  #   with_real_test_project do |dir|
  #     Dir.chdir(dir) { }
  #   end
  def with_real_test_project(&block)
    with_real_config do
      with_test_project do |dir|
        yield dir
      end
    end
  end
end
