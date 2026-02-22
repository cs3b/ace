# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

class GitCommitCliRoutingTest < TestCase
  def setup
    @exe_path = File.expand_path("../../exe/ace-git-commit", __dir__)
    skip "executable not found" unless File.exist?(@exe_path)
  end

  # --- Version Command Tests ---

  def test_cli_routes_version_with_long_flag
    stdout, _stderr, status = Open3.capture3(@exe_path, "--version")
    assert status.success?
    assert_match(/ace-git-commit \d+\.\d+\.\d+/, stdout)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_with_long_flag
    stdout, stderr, status = Open3.capture3(@exe_path, "--help")
    assert status.success?
    assert_match(/USAGE|Usage:/, stdout + stderr)
  end

  def test_cli_runs_commit_when_no_args
    stdout, stderr, _status = Open3.capture3(@exe_path)
    output = stdout + stderr
    refute_match(/unknown command/i, output)
    refute_match(/was called with arguments/i, output)
  end

  # --- Commit Command Tests ---

  def test_cli_runs_commit_without_subcommand_for_dry_run
    stdout, stderr, _status = Open3.capture3(@exe_path, "--dry-run")
    output = stdout + stderr
    refute_match(/unknown command/i, output)
    refute_match(/was called with arguments/i, output)
  end

  def test_cli_runs_commit_without_subcommand_for_staged_dry_run
    stdout, stderr, _status = Open3.capture3(@exe_path, "--staged", "--dry-run")
    output = stdout + stderr
    refute_match(/unknown command/i, output)
    refute_match(/was called with arguments/i, output)
  end

  def test_cli_runs_commit_without_subcommand_for_message_dry_run
    stdout, stderr, _status = Open3.capture3(@exe_path, "-m", "test message", "--dry-run")
    output = stdout + stderr
    refute_match(/unknown command/i, output)
    refute_match(/was called with arguments/i, output)
  end
end
