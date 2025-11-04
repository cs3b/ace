# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/git/worktree"

require "minitest/autorun"
require "minitest/pride"
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Configure SimpleCov for coverage reporting
if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    add_group "Atoms", "lib/ace/git/worktree/atoms"
    add_group "Molecules", "lib/ace/git/worktree/molecules"
    add_group "Organisms", "lib/ace/git/worktree/organisms"
    add_group "Models", "lib/ace/git/worktree/models"
    add_group "Commands", "lib/ace/git/worktree/commands"
  end
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
    # Mock Ace::Core.get for configuration
    Ace::Core.stub(:get, config_data) do
      yield
    end
  end

  def stub_ace_taskflow_output(task_id, output)
    # Mock ace-taskflow CLI output
    Open3.stub(:capture3, ["#{output}", "", 0]) do
      yield
    end
  end

  def stub_git_command(output = "", error = "", exit_status = 0)
    # Mock git command execution via ace-git-diff
    mock_result = {
      success: exit_status == 0,
      output: output,
      error: error,
      exit_code: exit_status
    }

    Ace::GitDiff::Atoms::CommandExecutor.stub(:execute, mock_result) do
      yield
    end
  end
end

# Include test helper in all test classes
class Minitest::Test
  include TestHelper
end