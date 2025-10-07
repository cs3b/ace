# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require_relative "support/test_factory"

# Base test case for ace-taskflow tests
class AceTaskflowTestCase < Ace::TestSupport::BaseTestCase
  # Make TestFactory module methods available as instance methods
  def with_test_project(&block)
    TestFactory.with_test_directory(&block)
  end

  def with_clean_project(&block)
    TestFactory.with_clean_project(&block)
  end
end
