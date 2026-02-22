# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

class CliRoutingTest < AceTestCase
  def setup
    @exe_path = File.expand_path("../../exe/ace-bundle", __dir__)
    skip "executable not found" unless File.exist?(@exe_path)
  end

  # --- Version Command Tests ---

  def test_cli_routes_version_command
    stdout, _stderr, status = Open3.capture3(@exe_path, "version")
    assert status.success?
    assert_match(/ace-bundle \d+\.\d+\.\d+/, stdout)
  end

  def test_cli_routes_version_with_long_flag
    stdout, _stderr, status = Open3.capture3(@exe_path, "--version")
    assert status.success?
    assert_match(/ace-bundle \d+\.\d+\.\d+/, stdout)
  end

  # --- Help Command Tests ---

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

  # --- List Command Tests ---

  def test_cli_routes_list_command
    _stdout, _stderr, status = Open3.capture3(@exe_path, "list")
    assert status.success?
  end

  # --- No Implicit Routing Tests ---

  def test_cli_does_not_use_load_as_default_task
    stdout, stderr, status = Open3.capture3(@exe_path, "project")
    refute status.success?
    assert_match(/COMMANDS|Commands:|unknown command/i, stdout + stderr)
  end

  def test_cli_shows_help_when_no_args
    stdout, stderr, status = Open3.capture3(@exe_path)
    assert status.success?
    assert_match(/Commands:/i, stdout + stderr)
  end

  # --- Numeric Flag Conversion Tests ---

  def test_cli_converts_max_size_to_integer
    stdout, stderr, _status = Open3.capture3(@exe_path, "load", "project", "--max-size", "1024")
    output = stdout + stderr
    refute_match(/ArgumentError.*String.*Integer/i, output)
    refute_match(/comparison.*failed/i, output)
  end

  def test_cli_converts_timeout_to_integer
    stdout, stderr, _status = Open3.capture3(@exe_path, "load", "project", "--timeout", "60")
    output = stdout + stderr
    refute_match(/ArgumentError.*String.*Integer/i, output)
    refute_match(/comparison.*failed/i, output)
  end
end
