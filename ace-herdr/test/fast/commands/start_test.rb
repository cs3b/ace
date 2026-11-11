# frozen_string_literal: true
require_relative "../../test_helper"

class StartCommandTest < Minitest::Test
  def test_start_uses_configured_native_executable_without_shell_or_environment_script
    calls = []
    command = Ace::Herdr::CLI::Commands::Start.new(
      launcher: ->(env, binary) { calls << [env, binary] }, configuration: {"binary" => "/opt/ace/bin/herdr", "socket" => "/tmp/test-herdr.sock"})
    command.call
    assert_equal [[{"HERDR_SOCKET_PATH" => "/tmp/test-herdr.sock"}, "/opt/ace/bin/herdr"]], calls
  end

  def test_missing_native_executable_is_an_error
    command = Ace::Herdr::CLI::Commands::Start.new(
      launcher: ->(*) { raise Errno::ENOENT }, configuration: {})
    assert_raises(Ace::Support::Cli::Error) { command.call }
  end
  def test_invalid_configuration_is_a_cli_error_before_launch
    command = Ace::Herdr::CLI::Commands::Start.new(
      launcher: ->(*) { flunk "must not launch" }, configuration: {"toolchain" => "invalid"})
    error = assert_raises(Ace::Support::Cli::Error) { command.call }
    assert_includes error.message, "toolchain must be auto or installed"
  end

end
