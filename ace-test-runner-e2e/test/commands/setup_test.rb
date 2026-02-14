# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class SetupTest < Minitest::Test
  Setup = Ace::Test::EndToEndRunner::CLI::Commands::Setup

  def test_setup_is_dry_cli_command
    command = Setup.new
    assert_kind_of Dry::CLI::Command, command
  end

  def test_setup_has_call_method
    command = Setup.new
    assert_respond_to command, :call
  end

  def test_setup_accepts_package_and_scenario_id
    command = Setup.new
    method = command.method(:call)
    param_names = method.parameters.map(&:last)
    assert_includes param_names, :package
    assert_includes param_names, :scenario_id
  end

  def test_setup_registered_in_cli
    assert Ace::Test::EndToEndRunner::CLI::REGISTERED_COMMANDS.include?("setup")
  end

  def test_known_command_recognizes_setup
    assert Ace::Test::EndToEndRunner::CLI.known_command?("setup")
  end

  def test_call_accepts_options_via_keyrest
    command = Setup.new
    method = command.method(:call)
    param_types = method.parameters.map(&:first)
    assert_includes param_types, :keyrest, "call should accept **options"
  end
end
