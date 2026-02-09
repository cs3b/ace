# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class RunSuiteTest < Minitest::Test
  RunSuite = Ace::Test::EndToEndRunner::CLI::Commands::RunSuite
  SuiteOrchestrator = Ace::Test::EndToEndRunner::Organisms::SuiteOrchestrator

  def setup
    @output = StringIO.new
  end

  def test_run_suite_default_options
    command = RunSuite.new

    # Just verify the command can be created
    assert_instance_of RunSuite, command
  end

  def test_run_suite_is_dry_cli_command
    command = RunSuite.new

    assert_kind_of Dry::CLI::Command, command
  end

  def test_run_suite_has_call_method
    command = RunSuite.new

    assert_respond_to command, :call
  end

  def test_convert_types_converts_string_to_integer
    command = RunSuite.new

    # Use the protected convert_types method via the Base module
    result = command.send(:convert_types, { parallel: "4", timeout: "120" }, parallel: :integer, timeout: :integer)

    assert_equal 4, result[:parallel]
    assert_equal 120, result[:timeout]
  end

  def test_convert_types_leaves_non_converted_options_alone
    command = RunSuite.new

    result = command.send(:convert_types, { parallel: "4", other: "string" }, parallel: :integer)

    assert_equal 4, result[:parallel]
    assert_equal "string", result[:other]
  end

  def test_quiet_method_recognizes_quiet_flag
    command = RunSuite.new

    assert command.send(:quiet?, quiet: true)
    refute command.send(:quiet?, quiet: false)
    refute command.send(:quiet?, {})
  end

  def test_call_accepts_packages_argument
    command = RunSuite.new

    # Verify the call method accepts packages as a keyword argument
    method = command.method(:call)
    param_names = method.parameters.map(&:last)
    assert_includes param_names, :packages
  end

  def test_suite_registered_in_cli
    cli = Ace::Test::EndToEndRunner::CLI

    # Check that 'suite' command is registered
    assert Ace::Test::EndToEndRunner::CLI::REGISTERED_COMMANDS.include?("suite")
  end
end
