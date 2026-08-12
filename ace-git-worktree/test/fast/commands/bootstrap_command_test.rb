# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/git/worktree/commands/bootstrap_command"

class BootstrapCommandTest < Minitest::Test
  def setup
    setup_temp_dir
    @mock_manager = Minitest::Mock.new
    @command = Ace::Git::Worktree::Commands::BootstrapCommand.new(manager: @mock_manager)
  end

  def teardown
    teardown_temp_dir
  end

  def test_help_flag_returns_zero
    res = @command.run(["--help"])
    assert_equal 0, res
  end

  def test_missing_identifier_returns_zero_showing_help
    res = @command.run([])
    assert_equal 0, res
  end

  def test_unknown_identifier_returns_error
    @mock_manager.expect(:list, {worktrees: []})
    res = @command.run(["nonexistent"])
    assert_equal 1, res
    @mock_manager.verify
  end

  def test_reruns_phases_for_existing_worktree
    wt_info = {path: @temp_dir, branch: "test-branch", task_id: "081"}
    @mock_manager.expect(:list, {worktrees: [wt_info]})

    out, _ = capture_io do
      res = @command.run(["081", "--json"])
      assert_equal 0, res
    end

    parsed = JSON.parse(out)
    assert_equal "081", parsed["identifier"]
    assert_equal "ready", parsed["readiness"]
    assert_equal 2, parsed["phases"].length
    @mock_manager.verify
  end
end
