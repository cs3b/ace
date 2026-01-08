# frozen_string_literal: true

require_relative "../test_helper"

# Unit tests for dry-cli routing behavior
# Verifies default command routing, command aliases, and KNOWN_COMMANDS
class CliRoutingIntegrationTest < AceTaskflowTestCase
  def test_known_commands_includes_all_registered_commands
    expected_registered = %w[
      task tasks idea ideas
      release releases retro retros
      status doctor migrate config
    ]

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

  def test_known_commands_includes_aliases
    expected_aliases = %w[context migrate-paths]

    expected_aliases.each do |cmd|
      assert Ace::Taskflow::CLI::KNOWN_COMMANDS.include?(cmd),
             "KNOWN_COMMANDS should include alias '#{cmd}'"
    end
  end

  def test_command_aliases_constant_defined
    # COMMAND_ALIASES should contain backward compatibility aliases
    assert_includes Ace::Taskflow::CLI::COMMAND_ALIASES, "context"
    assert_includes Ace::Taskflow::CLI::COMMAND_ALIASES, "migrate-paths"
  end

  def test_known_command_returns_false_for_task_references
    # Any unknown first argument should be treated as a task reference
    assert_equal false, Ace::Taskflow::CLI.known_command?("114")
    assert_equal false, Ace::Taskflow::CLI.known_command?("v.0.9.0+114")
    assert_equal false, Ace::Taskflow::CLI.known_command?("task.114")
    assert_equal false, Ace::Taskflow::CLI.known_command?(nil)
    assert_equal false, Ace::Taskflow::CLI.known_command?("some-random-string")
  end

  def test_known_command_returns_true_for_registered_commands
    %w[task tasks status ideas retros doctor migrate config].each do |cmd|
      assert_equal true, Ace::Taskflow::CLI.known_command?(cmd),
                   "known_command?('#{cmd}') should return true"
    end
  end

  def test_known_command_returns_true_for_aliases
    assert_equal true, Ace::Taskflow::CLI.known_command?("context")
    assert_equal true, Ace::Taskflow::CLI.known_command?("migrate-paths")
  end

  def test_default_command_is_task
    assert_equal "task", Ace::Taskflow::CLI::DEFAULT_COMMAND
  end

  def test_registered_commands_constant_matches_expected
    expected = %w[
      task tasks idea ideas
      release releases retro retros
      status doctor migrate config
    ]

    assert_equal expected.sort, Ace::Taskflow::CLI::REGISTERED_COMMANDS.sort
  end

  def test_shared_options_module_exists
    assert defined?(Ace::Taskflow::CLI::SharedOptions),
           "SharedOptions module should be defined"
  end

  def test_shared_options_numeric_options_constant
    # Verify the NUMERIC_OPTIONS constant exists and contains expected keys
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
    assert_equal "test", result[:name] # Non-numeric should be unchanged
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

    # Should use dashes in error message for CLI consistency
    assert_match(/--recently-done-limit/, error.message)
  end

  def test_empty_args_routes_to_default_command
    # Verify that empty args prepends the default command
    # This is the fix for Thor default_task parity
    assert_equal "task", Ace::Taskflow::CLI::DEFAULT_COMMAND

    # The routing logic should prepend "task" for empty args
    # We can't easily test the full CLI.start without side effects,
    # but we can verify the known_command? logic
    assert_equal false, Ace::Taskflow::CLI.known_command?(nil)
  end
end
