# frozen_string_literal: true

require "stringio"
require_relative "../../../test_helper"

class HelpCommandFactoryTest < AceSupportCliTestCase
  def test_build_returns_callable_command
    command = Ace::Support::Cli::HelpCommand.build(
      program_name: "ace-tool",
      version: "1.0.0",
      commands: {"lint" => "Run linter", "test" => "Run tests"},
      examples: ["ace-tool lint ."]
    )

    # build returns a configured instance (AOT-safe: no Class.new)
    stdout = capture_stdout { assert_equal 0, command.call }
    assert_includes stdout, "ace-tool 1.0.0"
    assert_includes stdout, "Commands:"
    assert_includes stdout, "  lint"
    assert_includes stdout, "Examples:\n  ace-tool lint ."
    assert_includes stdout, "--version       # Print version"
  end

  def test_build_accepts_args_argument
    command = Ace::Support::Cli::HelpCommand.build(
      program_name: "ace-tool",
      version: "1.0.0",
      commands: [["status", "Show status"]]
    )

    assert command.class.arguments.any? { |a| a.name == :args }
  end

  private

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
