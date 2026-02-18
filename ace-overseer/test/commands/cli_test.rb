# frozen_string_literal: true

require_relative "../test_helper"

class CliTest < AceOverseerTestCase
  def test_help_lists_registered_commands
    output = capture_io do
      Ace::Overseer::CLI.start(["--help"])
    end

    assert_includes output.first, "work-on"
    assert_includes output.first, "status"
    assert_includes output.first, "prune"
  end

  def test_version_command_prints_version
    output = capture_io do
      Ace::Overseer::CLI.start(["version"])
    end

    assert_includes output.first, "ace-overseer"
    assert_includes output.first, Ace::Overseer::VERSION
  end
end
