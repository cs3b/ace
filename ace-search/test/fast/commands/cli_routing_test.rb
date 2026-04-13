# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

class CliRoutingTest < AceSearchTestCase
  def setup
    @exe_path = File.expand_path("../../../exe/ace-search", __dir__)
    skip "executable not found" unless File.exist?(@exe_path)
  end

  # --- Version Command Tests ---

  def test_cli_routes_version_with_long_flag
    stdout, _stderr, status = Open3.capture3(@exe_path, "--version")
    assert status.success?
    assert_match(/ace-search \d+\.\d+\.\d+/, stdout)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_with_long_flag
    stdout, stderr, status = Open3.capture3(@exe_path, "--help")
    assert status.success?
    assert_match(%r{
USAGE
}i, stdout + stderr)
  end

  # --- Search Command Tests ---

  def test_cli_runs_search_without_subcommand
    skip_unless_rg_available

    stdout, _stderr, status = Open3.capture3(
      @exe_path, "test", "--max-results", "1",
      chdir: File.expand_path("../../..", __dir__)
    )
    assert status.success?
    # Should attempt a search
    assert_match(/Found \d+ results?|mode:/i, stdout)
  end

  def test_cli_shows_help_when_no_args
    stdout, stderr, status = Open3.capture3(@exe_path)
    assert status.success?
    assert_match(%r{
USAGE
}i, stdout + stderr)
  end
end
