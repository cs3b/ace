# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/cli/task_cli"
require "ace/taskflow/cli/idea_cli"
require "ace/taskflow/cli/release_cli"
require "ace/taskflow/cli/retro_cli"

# Unit tests for dry-cli routing behavior
# Verifies default command routing, command aliases, and KNOWN_COMMANDS
class CliRoutingIntegrationTest < AceTaskflowTestCase
  # === ace-taskflow (utility commands only) ===

  def test_known_commands_includes_all_registered_commands
    expected_registered = %w[status doctor config]

    expected_registered.each do |cmd|
      assert Ace::Taskflow::CLI::KNOWN_COMMANDS.include?(cmd),
             "KNOWN_COMMANDS should include '#{cmd}'"
    end
  end

  def test_known_commands_includes_builtin_commands
    expected_builtins = %w[version help --help -h --version]

    expected_builtins.each do |cmd|
      assert Ace::Taskflow::CLI::KNOWN_COMMANDS.include?(cmd),
             "KNOWN_COMMANDS should include builtin '#{cmd}'"
    end
  end

  def test_known_command_returns_false_for_unknown_commands
    assert_equal false, Ace::Taskflow::CLI.known_command?("114")
    assert_equal false, Ace::Taskflow::CLI.known_command?(nil)
    assert_equal false, Ace::Taskflow::CLI.known_command?("some-random-string")
  end

  def test_known_command_returns_true_for_registered_commands
    %w[status doctor config].each do |cmd|
      assert_equal true, Ace::Taskflow::CLI.known_command?(cmd),
                   "known_command?('#{cmd}') should return true"
    end
  end

  def test_default_command_is_status
    assert_equal "status", Ace::Taskflow::CLI::DEFAULT_COMMAND
  end

  def test_registered_commands_constant_matches_expected
    expected = %w[status doctor config]
    assert_equal expected.sort, Ace::Taskflow::CLI::REGISTERED_COMMANDS.sort
  end

  # === ace-task (task management) ===

  def test_task_cli_known_commands
    expected = %w[list show create start done undone defer undefer move update add-dependency remove-dependency]
    expected.each do |cmd|
      assert Ace::Taskflow::TaskCLI::KNOWN_COMMANDS.include?(cmd),
             "TaskCLI KNOWN_COMMANDS should include '#{cmd}'"
    end
  end

  def test_task_cli_default_command
    assert_equal "list", Ace::Taskflow::TaskCLI::DEFAULT_COMMAND
  end

  # === ace-idea (idea management) ===

  def test_idea_cli_known_commands
    expected = %w[list create done park unpark reschedule]
    expected.each do |cmd|
      assert Ace::Taskflow::IdeaCLI::KNOWN_COMMANDS.include?(cmd),
             "IdeaCLI KNOWN_COMMANDS should include '#{cmd}'"
    end
  end

  def test_idea_cli_default_command
    assert_equal "list", Ace::Taskflow::IdeaCLI::DEFAULT_COMMAND
  end

  # === ace-release (release management) ===

  def test_release_cli_known_commands
    expected = %w[list show]
    expected.each do |cmd|
      assert Ace::Taskflow::ReleaseCLI::KNOWN_COMMANDS.include?(cmd),
             "ReleaseCLI KNOWN_COMMANDS should include '#{cmd}'"
    end
  end

  def test_release_cli_default_command
    assert_equal "list", Ace::Taskflow::ReleaseCLI::DEFAULT_COMMAND
  end

  # === ace-retro (retrospective management) ===

  def test_retro_cli_known_commands
    expected = %w[list create]
    expected.each do |cmd|
      assert Ace::Taskflow::RetroCLI::KNOWN_COMMANDS.include?(cmd),
             "RetroCLI KNOWN_COMMANDS should include '#{cmd}'"
    end
  end

  def test_retro_cli_default_command
    assert_equal "list", Ace::Taskflow::RetroCLI::DEFAULT_COMMAND
  end

  # === SharedOptions (used by command classes) ===

  def test_shared_options_module_exists
    assert defined?(Ace::Taskflow::CLI::SharedOptions),
           "SharedOptions module should be defined"
  end

  def test_shared_options_numeric_options_constant
    numeric_opts = Ace::Taskflow::CLI::SharedOptions::NUMERIC_OPTIONS
    assert_includes numeric_opts, :limit
    assert_includes numeric_opts, :days
    assert_includes numeric_opts, :recently_done_limit
    assert_includes numeric_opts, :up_next_limit
  end

  def test_convert_numeric_options_converts_strings_to_integers
    options = { limit: "10", recently_done_limit: "5", name: "test" }
    result = Ace::Taskflow::CLI::SharedOptions.convert_numeric_options(
      options,
      :limit,
      :recently_done_limit
    )

    assert_equal 10, result[:limit]
    assert_equal 5, result[:recently_done_limit]
    assert_equal "test", result[:name]
  end

  def test_convert_numeric_options_handles_nil_values
    options = { limit: nil, name: "test" }
    result = Ace::Taskflow::CLI::SharedOptions.convert_numeric_options(options, :limit)

    assert_nil result[:limit]
    assert_equal "test", result[:name]
  end

  def test_convert_numeric_options_raises_on_invalid_input
    options = { limit: "not-a-number" }

    error = assert_raises(ArgumentError) do
      Ace::Taskflow::CLI::SharedOptions.convert_numeric_options(options, :limit)
    end

    assert_match(/Invalid value for --limit/, error.message)
    assert_match(/'not-a-number'/, error.message)
  end

  def test_convert_numeric_options_formats_underscored_keys_with_dashes
    options = { recently_done_limit: "abc" }

    error = assert_raises(ArgumentError) do
      Ace::Taskflow::CLI::SharedOptions.convert_numeric_options(options, :recently_done_limit)
    end

    assert_match(/--recently-done-limit/, error.message)
  end

  def test_empty_args_routes_to_default_command
    assert_equal "status", Ace::Taskflow::CLI::DEFAULT_COMMAND
    assert_equal false, Ace::Taskflow::CLI.known_command?(nil)
  end
end
