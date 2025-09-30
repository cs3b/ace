# frozen_string_literal: true

require "ace/taskflow"
require "ace/test_support"
require "tmpdir"
require "fileutils"
require_relative "support/test_factory"

# AceTestCase is provided by ace-test-support
# It includes all the helper methods we need

# Extend AceTestCase with common taskflow test helpers
class AceTaskflowTestCase < AceTestCase
  include TestFactory

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def with_test_project(&block)
    TestFactory.with_test_directory(&block)
  end
end