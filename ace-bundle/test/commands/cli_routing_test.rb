# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

class CliRoutingTest < AceTestCase
  def setup
    @exe_path = File.expand_path("../../exe/ace-bundle", __dir__)
    skip "executable not found" unless File.exist?(@exe_path)
  end

  # --- Version Tests ---

  def test_cli_routes_version_with_long_flag
    stdout, _stderr, status = Open3.capture3(@exe_path, "--version")
    assert status.success?
    assert_match(/ace-bundle \d+\.\d+\.\d+/, stdout)
  end

  # --- Help Tests ---

  def test_cli_routes_help_with_long_flag
    stdout, stderr, status = Open3.capture3(@exe_path, "--help")
    assert status.success?
    # Single-command mode shows dry-cli's built-in help
    assert_match(/Load context|preset|protocol/i, stdout + stderr)
  end

  def test_cli_shows_help_when_no_args
    stdout, stderr, status = Open3.capture3(@exe_path)
    assert status.success?
    assert_match(/Load context|preset|protocol/i, stdout + stderr)
  end

  # --- List Presets Flag Tests ---

  def test_cli_routes_list_presets_flag
    stdout, _stderr, status = Open3.capture3(@exe_path, "--list-presets")
    assert status.success?
    # Should list presets (or show empty message)
    refute_empty stdout.strip
  end

  # --- Direct Invocation Tests (no subcommand needed) ---

  def test_cli_loads_project_preset_directly
    stdout, stderr, _status = Open3.capture3(@exe_path, "project")
    output = stdout + stderr
    # Should attempt to load, not show "unknown command"
    refute_match(/unknown command/i, output)
  end

  # --- Numeric Flag Conversion Tests ---

  def test_cli_converts_max_size_to_integer
    stdout, stderr, _status = Open3.capture3(@exe_path, "project", "--max-size", "1024")
    output = stdout + stderr
    refute_match(/ArgumentError.*String.*Integer/i, output)
    refute_match(/comparison.*failed/i, output)
  end

  def test_cli_converts_timeout_to_integer
    stdout, stderr, _status = Open3.capture3(@exe_path, "project", "--timeout", "60")
    output = stdout + stderr
    refute_match(/ArgumentError.*String.*Integer/i, output)
    refute_match(/comparison.*failed/i, output)
  end
end
