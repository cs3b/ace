# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/cli/retro_cli"
require "ace/test_support/cli_helpers"

# Tests for the dedicated CreateRetro command (ace-retro create)
# Ensures dry-cli properly routes title as a positional argument
class CreateRetroCommandTest < AceTaskflowTestCase
  include Ace::TestSupport::CliHelpers

  def test_create_retro_with_title
    with_real_test_project do |_dir|
      result = invoke_cli(Ace::Taskflow::RetroCLI, ["create", "my-test-retro"])
      output = result[:stdout] + result[:stderr]

      assert_match(/Reflection note created/, output)
      assert_match(/my-test-retro/, output)
      assert_match(/Path:/, output)
    end
  end

  def test_create_retro_requires_title
    with_real_test_project do |_dir|
      result = invoke_cli(Ace::Taskflow::RetroCLI, ["create"])
      output = result[:stdout] + result[:stderr]

      # dry-cli should report missing required argument or command should error
      refute_equal 0, result[:result]
    end
  end

  def test_create_retro_with_release_option
    with_real_test_project do |_dir|
      result = invoke_cli(Ace::Taskflow::RetroCLI, ["create", "release-retro", "--release", "v.0.9.0"])
      output = result[:stdout] + result[:stderr]

      assert_match(/Reflection note created/, output)
      assert_match(/release-retro/, output)
    end
  end

  def test_create_retro_with_backlog_option
    with_real_test_project do |_dir|
      result = invoke_cli(Ace::Taskflow::RetroCLI, ["create", "backlog-retro", "--backlog"])
      output = result[:stdout] + result[:stderr]

      assert_match(/Reflection note created/, output)
      assert_match(/backlog-retro/, output)
    end
  end

  def test_create_retro_with_task_option
    with_real_test_project do |_dir|
      result = invoke_cli(Ace::Taskflow::RetroCLI, ["create", "task-retro", "--task", "278"])
      output = result[:stdout] + result[:stderr]

      # --task flag should be accepted without error
      refute_match(/unknown/i, output)
    end
  end

  def test_create_retro_help
    result = invoke_cli(Ace::Taskflow::RetroCLI, ["create", "--help"])
    output = result[:stdout] + result[:stderr]

    assert_match(/Create a new retrospective reflection note/i, output)
  end
end
