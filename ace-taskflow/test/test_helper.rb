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

  # Reset cached configuration before each test to ensure test isolation
  # This is important since ADR-022 caches gem defaults and configuration for performance
  def setup
    super
    require "ace/taskflow"
    require "ace/taskflow/molecules/config_loader"
    Ace::Taskflow::Molecules::ConfigLoader.reset_gem_defaults!
    Ace::Taskflow.reset_configuration!
  end

  # Make TestFactory module methods available as instance methods
  def with_test_project(&block)
    TestFactory.with_test_directory(&block)
  end

  def with_clean_project(&block)
    TestFactory.with_clean_project(&block)
  end
end
