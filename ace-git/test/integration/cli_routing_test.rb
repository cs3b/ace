# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

class CliRoutingTest < AceGitTestCase
  def setup
    super
    @exe_path = File.expand_path("../../exe/ace-git", __dir__)
    skip "executable not found" unless File.exist?(@exe_path)
  end

  def test_cli_routes_version_command
    stdout, _stderr, status = Open3.capture3(@exe_path, "version")
    assert status.success?
    assert_match(/ace-git \d+\.\d+\.\d+/, stdout)
  end

  def test_cli_routes_version_with_long_flag
    stdout, _stderr, status = Open3.capture3(@exe_path, "--version")
    assert status.success?
    assert_match(/ace-git \d+\.\d+\.\d+/, stdout)
  end

  def test_cli_routes_help_command
    stdout, stderr, status = Open3.capture3(@exe_path, "help")
    assert status.success?
    assert_match(/Commands:/i, stdout + stderr)
  end

  def test_cli_routes_help_with_long_flag
    stdout, stderr, status = Open3.capture3(@exe_path, "--help")
    assert status.success?
    assert_match(/Commands:/i, stdout + stderr)
  end

  def test_cli_routes_help_with_short_flag
    stdout, stderr, status = Open3.capture3(@exe_path, "-h")
    assert status.success?
    assert_match(/Commands:/i, stdout + stderr)
  end

  def test_cli_shows_help_when_no_args
    stdout, stderr, status = Open3.capture3(@exe_path)
    assert status.success?
    assert_match(/Commands:/i, stdout + stderr)
  end

  def test_cli_routes_explicit_diff_range
    _stdout, _stderr, status = Open3.capture3(@exe_path, "diff", "HEAD~1..HEAD")
    assert status.success?
  end

  def test_cli_routes_range_shorthand_to_diff
    _stdout, _stderr, status = Open3.capture3(@exe_path, "HEAD~1..HEAD")
    assert status.success?
  end

  def test_cli_routes_head_shorthand_to_diff
    _stdout, _stderr, status = Open3.capture3(@exe_path, "HEAD")
    assert status.success?
  end

  def test_cli_unknown_command_returns_error
    stdout, stderr, status = Open3.capture3(@exe_path, "log")
    refute status.success?
    assert_match(/COMMANDS|Commands:|unknown command/i, stdout + stderr)
  end
end
