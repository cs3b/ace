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

  # Helper to create successful process status
  def successful_status
    status = Object.new
    status.define_singleton_method(:success?) { true }
    status.define_singleton_method(:exitstatus) { 0 }
    status
  end

  # Helper to create failed process status
  def failed_status(exit_code = 1)
    status = Object.new
    status.define_singleton_method(:success?) { false }
    status.define_singleton_method(:exitstatus) { exit_code }
    status
  end

  # Helper to mock Open3.capture2 with success
  def mock_capture2_success(output = "")
    [output, successful_status]
  end

  # Helper to mock Open3.capture2 with failure
  def mock_capture2_failure(output = "", exit_code = 1)
    [output, failed_status(exit_code)]
  end

  # Helper to mock Open3.capture3 with success
  def mock_capture3_success(stdout = "", stderr = "")
    [stdout, stderr, successful_status]
  end

  # Helper to mock Open3.capture3 with failure
  def mock_capture3_failure(stdout = "", stderr = "", exit_code = 1)
    [stdout, stderr, failed_status(exit_code)]
  end
end

# Test fixtures path
TEST_FIXTURES = File.expand_path("fixtures", __dir__)