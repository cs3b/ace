# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/cli/task_cli"
require "ace/taskflow/cli/idea_cli"
require "ace/taskflow/cli/release_cli"
require "ace/taskflow/cli/retro_cli"

# Unit tests for dry-cli routing behavior
# Verifies command registration and help examples
class CliRoutingIntegrationTest < AceTaskflowTestCase
  # === ace-taskflow (utility commands only) ===

  def test_registered_commands_constant_matches_expected
    expected = [
      %w[status "Show taskflow status"],
      %w[doctor "Run health checks"],
      %w[config "Show configuration"],
      %w[review-next-phase "Run next-phase simulation and persist cache artifacts"]
    ]
    expected_commands = expected.map(&:first)

    actual_commands = Ace::Taskflow::CLI::REGISTERED_COMMANDS.map(&:first)
    assert_equal expected_commands.sort, actual_commands.sort
  end

  def test_help_examples_constant_exists
    examples = Ace::Taskflow::CLI::HELP_EXAMPLES
    assert_instance_of Array, examples
    assert examples.any? { |ex| ex.include?("status") }
  end

  # === ace-task (task management) ===

  def test_task_cli_registered_commands
    expected = %w[list show create start done undone defer undefer move update add-dependency remove-dependency]
    actual_commands = Ace::Taskflow::TaskCLI::REGISTERED_COMMANDS.map(&:first)
    assert_equal expected.sort, actual_commands.sort
  end

  def test_task_cli_help_examples
    examples = Ace::Taskflow::TaskCLI::HELP_EXAMPLES
    assert_instance_of Array, examples
    assert examples.any? { |ex| ex.include?("list") }
    assert examples.any? { |ex| ex.include?("done") }
  end

  # === ace-idea (idea management) ===

  def test_idea_cli_registered_commands
    expected = %w[list show create done park unpark reschedule]
    actual_commands = Ace::Taskflow::IdeaCLI::REGISTERED_COMMANDS.map(&:first)
    assert_equal expected.sort, actual_commands.sort
  end

  def test_idea_cli_help_examples
    examples = Ace::Taskflow::IdeaCLI::HELP_EXAMPLES
    assert_instance_of Array, examples
    assert examples.any? { |ex| ex.include?("list") }
    assert examples.any? { |ex| ex.include?("park") }
  end

  # === ace-release (release management) ===
  # Note: ReleaseCLI uses old pattern (array of strings) until migrated

  def test_release_cli_registered_commands
    expected = %w[list show]
    # Handle both old pattern (strings) and new pattern (arrays)
    registered = Ace::Taskflow::ReleaseCLI::REGISTERED_COMMANDS
    actual_commands = registered.first.is_a?(Array) ? registered.map(&:first) : registered
    assert_equal expected.sort, actual_commands.sort
  end

  def test_release_cli_help_examples
    examples = Ace::Taskflow::ReleaseCLI::HELP_EXAMPLES
    assert_instance_of Array, examples
  end

  # === ace-retro (retrospective management) ===
  # Note: RetroCLI uses old pattern (array of strings) until migrated

  def test_retro_cli_registered_commands
    expected = %w[list create]
    # Handle both old pattern (strings) and new pattern (arrays)
    registered = Ace::Taskflow::RetroCLI::REGISTERED_COMMANDS
    actual_commands = registered.first.is_a?(Array) ? registered.map(&:first) : registered
    assert_equal expected.sort, actual_commands.sort
  end

  def test_retro_cli_help_examples
    examples = Ace::Taskflow::RetroCLI::HELP_EXAMPLES
    assert_instance_of Array, examples
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
end
