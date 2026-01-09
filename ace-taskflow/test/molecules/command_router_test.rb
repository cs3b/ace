# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/molecules/command_router"

class CommandRouterTest < AceTaskflowTestCase
  KNOWN_COMMANDS = Set.new(%w[task tasks status help --help]).freeze
  TASK_SUBCOMMANDS = %w[create show start done].freeze

  # apply_default_command tests

  def test_apply_default_command_prepends_default_for_empty_args
    result = Ace::Taskflow::Molecules::CommandRouter.apply_default_command(
      [],
      default: "task",
      known_commands: KNOWN_COMMANDS
    )

    assert_equal ["task"], result
  end

  def test_apply_default_command_prepends_default_for_unknown_command
    result = Ace::Taskflow::Molecules::CommandRouter.apply_default_command(
      ["150"],
      default: "task",
      known_commands: KNOWN_COMMANDS
    )

    assert_equal ["task", "150"], result
  end

  def test_apply_default_command_passes_through_known_command
    result = Ace::Taskflow::Molecules::CommandRouter.apply_default_command(
      ["status"],
      default: "task",
      known_commands: KNOWN_COMMANDS
    )

    assert_equal ["status"], result
  end

  def test_apply_default_command_passes_through_builtin_command
    result = Ace::Taskflow::Molecules::CommandRouter.apply_default_command(
      ["--help"],
      default: "task",
      known_commands: KNOWN_COMMANDS
    )

    assert_equal ["--help"], result
  end

  # route_task_subcommand tests

  def test_route_task_subcommand_passes_through_non_task_command
    result = Ace::Taskflow::Molecules::CommandRouter.route_task_subcommand(
      ["status"],
      task_subcommands: TASK_SUBCOMMANDS
    )

    assert_equal ["status"], result
  end

  def test_route_task_subcommand_passes_through_task_with_no_subcommand
    result = Ace::Taskflow::Molecules::CommandRouter.route_task_subcommand(
      ["task"],
      task_subcommands: TASK_SUBCOMMANDS
    )

    assert_equal ["task"], result
  end

  def test_route_task_subcommand_passes_through_known_subcommand
    result = Ace::Taskflow::Molecules::CommandRouter.route_task_subcommand(
      ["task", "create", "--title", "Test"],
      task_subcommands: TASK_SUBCOMMANDS
    )

    assert_equal ["task", "create", "--title", "Test"], result
  end

  def test_route_task_subcommand_passes_through_task_reference
    result = Ace::Taskflow::Molecules::CommandRouter.route_task_subcommand(
      ["task", "114"],
      task_subcommands: TASK_SUBCOMMANDS
    )

    assert_equal ["task", "114"], result
  end

  def test_route_task_subcommand_passes_through_complex_task_reference
    result = Ace::Taskflow::Molecules::CommandRouter.route_task_subcommand(
      ["task", "v.0.9.0+114"],
      task_subcommands: TASK_SUBCOMMANDS
    )

    assert_equal ["task", "v.0.9.0+114"], result
  end

  # route (combined) tests

  def test_route_applies_default_and_subcommand_routing
    result = Ace::Taskflow::Molecules::CommandRouter.route(
      ["150"],
      default: "task",
      known_commands: KNOWN_COMMANDS,
      task_subcommands: TASK_SUBCOMMANDS
    )

    assert_equal ["task", "150"], result
  end

  def test_route_handles_task_subcommand_from_empty_args
    result = Ace::Taskflow::Molecules::CommandRouter.route(
      [],
      default: "task",
      known_commands: KNOWN_COMMANDS,
      task_subcommands: TASK_SUBCOMMANDS
    )

    assert_equal ["task"], result
  end

  def test_route_preserves_task_create_subcommand
    result = Ace::Taskflow::Molecules::CommandRouter.route(
      ["task", "create", "--title", "New task"],
      default: "task",
      known_commands: KNOWN_COMMANDS,
      task_subcommands: TASK_SUBCOMMANDS
    )

    assert_equal ["task", "create", "--title", "New task"], result
  end
end
