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
    begin
      yield
    rescue SystemExit => e
      # Capture exit calls but don't propagate them
      # This allows tests to continue even when commands call exit
    end
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def capture_stdout_with_exit
    original_stdout = $stdout
    exit_code = nil
    $stdout = StringIO.new
    begin
      yield
    rescue SystemExit => e
      exit_code = e.status
    end
    [$stdout.string, exit_code]
  ensure
    $stdout = original_stdout
  end

  def with_test_project(&block)
    TestFactory.with_test_directory(&block)
  end

  def with_clean_project(&block)
    TestFactory.with_clean_project(&block)
  end
end