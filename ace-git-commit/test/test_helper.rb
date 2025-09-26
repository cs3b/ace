# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require "minitest/reporters"

# Configure minitest reporters
Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new(color: true)
]

# Require the gem being tested
require "ace/git_commit"

# Include test support if available
begin
  require "ace/test_support"
  require "ace/test_support/base_test_case"
  require "ace/test_support/test_environment"
rescue LoadError
  # Test support not available, use basic Minitest::Test
end

# Base test class
class TestCase < (defined?(Ace::TestSupport::BaseTestCase) ? Ace::TestSupport::BaseTestCase : Minitest::Test)
  # Add any common test setup here
end

# Test fixtures path
TEST_FIXTURES = File.expand_path("fixtures", __dir__)