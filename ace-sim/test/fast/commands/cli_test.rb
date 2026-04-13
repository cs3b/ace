# frozen_string_literal: true

require_relative "../../test_helper"

class CliTest < AceSimTestCase
  CLI = Ace::Sim::CLI

  def test_program_name
    assert_equal "ace-sim", CLI::PROGRAM_NAME
  end

  def test_help_output_lists_run
    output = capture_io { CLI.start(["--help"]) }[0]
    assert_match(/run/, output)
  end

  def test_version_output
    output = capture_io { CLI.start(["version"]) }[0]
    assert_match(/ace-sim/, output)
    assert_match(/#{Ace::Sim::VERSION}/o, output)
  end
end
