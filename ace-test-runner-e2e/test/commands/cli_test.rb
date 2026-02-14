# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class CLITest < Minitest::Test
  CLI = Ace::Test::EndToEndRunner::CLI

  def test_version_command
    out, = capture_io { CLI.start(["version"]) }
    assert_match(/ace-test-e2e \d+\.\d+\.\d+/, out)
  end

  def test_version_flag
    out, = capture_io { CLI.start(["--version"]) }
    assert_match(/ace-test-e2e \d+\.\d+\.\d+/, out)
  end

  def test_help_flag
    out, = capture_io { CLI.start(["--help"]) }
    assert out.include?("Usage:"), "Help should show usage"
    assert out.include?("ace-test-e2e"), "Help should include command name"
  end

  def test_help_command
    out, = capture_io { CLI.start(["help"]) }
    assert out.include?("Usage:")
  end

  def test_known_command_recognizes_registered
    assert CLI.known_command?("run")
    assert CLI.known_command?("suite")
    assert CLI.known_command?("version")
  end

  def test_known_command_rejects_file_paths
    refute CLI.known_command?("./file")
    refute CLI.known_command?("path/to/file")
  end

  def test_known_command_rejects_nil
    refute CLI.known_command?(nil)
  end

  def test_known_command_rejects_flags
    refute CLI.known_command?("--provider")
    refute CLI.known_command?("-q")
  end

  def test_default_routing_prepends_run
    # ace-lint should be treated as package name, not command
    # This tests the routing logic, not actual execution
    refute CLI.known_command?("ace-lint")
  end
end
