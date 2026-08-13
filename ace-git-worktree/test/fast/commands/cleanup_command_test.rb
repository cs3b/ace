# frozen_string_literal: true

require "test_helper"
require "ace/git/worktree/commands/cleanup_command"

class CleanupCommandTest < Minitest::Test
  def setup
    super
    @cmd = Ace::Git::Worktree::Commands::CleanupCommand.new
  end

  def test_help_option_returns_zero
    result = @cmd.run(["--help"])
    assert_equal 0, result
  end

  def test_missing_target_returns_error
    result = @cmd.run([])
    assert_equal 1, result
  end

  def test_invalid_format_returns_error
    result = @cmd.run(["--target", "main", "--format", "invalid"])
    assert_equal 1, result
  end

  def test_successful_run_returns_zero
    mock_reporter = Minitest::Mock.new
    mock_reporter.expect :report, {
      success: true,
      target: {ref: "main", sha: "abc1234"},
      remote: {name: "origin", sha: "def5678"},
      refresh: {status: "offline"},
      worktrees: [],
      local_refs: [],
      remote_refs: [],
      actions: [],
      plan_digest: "digest"
    }

    Ace::Git::Worktree::Molecules::CleanupReporter.stub :new, mock_reporter do
      result = @cmd.run(["--target", "main", "--offline"])
      assert_equal 0, result
    end
    mock_reporter.verify
  end

  def test_failed_report_returns_error
    mock_reporter = Minitest::Mock.new
    mock_reporter.expect :report, {success: false, error: "Something went wrong"}

    Ace::Git::Worktree::Molecules::CleanupReporter.stub :new, mock_reporter do
      result = @cmd.run(["--target", "main"])
      assert_equal 1, result
    end
    mock_reporter.verify
  end
end
