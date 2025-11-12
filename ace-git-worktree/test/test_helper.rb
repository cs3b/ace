# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/git/worktree"
require "ace/git_diff"

require "minitest/autorun"
require "minitest/pride"
require "minitest/reporters"

# Load shared test support for mocking fixtures
require "ace/test_support"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Standardized coverage configuration
if ENV["COVERAGE"]
  require "ace/test_support/coverage"
  Ace::TestSupport::Coverage.start("ace-git-worktree")
end

# Test utilities and helpers
module TestHelper
  def setup_temp_dir
    @temp_dir = Dir.mktmpdir("ace-git-worktree-test")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  def teardown_temp_dir
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir) if @temp_dir
  end

  def stub_ace_core_config(config_data = {})
    # Use shared fixtures from ace-test-support
    Ace::TestSupport::Fixtures::GitMocks.stub_ace_core_config(config_data) do
      yield
    end
  end

  def stub_ace_taskflow_output(task_id, output)
    # Use shared fixtures from ace-test-support
    Ace::TestSupport::Fixtures::GitMocks.stub_ace_taskflow_output(task_id, output) do
      yield
    end
  end

  def stub_git_command(output: "", error: "", exit_status: 0)
    # Use shared fixtures from ace-test-support
    Ace::TestSupport::Fixtures::GitMocks.stub_git_command(output: output, error: error, exit_status: exit_status) do
      yield
    end
  end
end

# Include test helper in all test classes
class Minitest::Test
  include TestHelper
end