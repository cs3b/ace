# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/cli"
require "ace/test_support/cli_helpers"

# Tests for nested idea subcommands CLI routing
# Ensures dry-cli properly routes to nested idea subcommands (create, done, park, unpark, reschedule)
class IdeaSubcommandsTest < AceTaskflowTestCase
  include Ace::TestSupport::CliHelpers

  # --- Idea Create Subcommand Tests ---

  def test_cli_routes_idea_create_command
    # Verify 'idea create' routes to the create subcommand
    result = invoke_cli(Ace::Taskflow::CLI, ["idea", "create", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for create command or indicate proper routing
    refute_match(/unknown command/i, output)
    assert_match(/create|Usage|content/i, output)
  end

  def test_cli_routes_idea_create_with_note_flag
    with_real_test_project do |_dir|
      # Verify --note flag routes correctly to create subcommand
      result = invoke_cli(Ace::Taskflow::CLI, ["idea", "create", "--note", "test content"])
      output = result[:stdout] + result[:stderr]

      # Should not reject the command or flag
      refute_match(/unknown command/i, output)
    end
  end

  def test_cli_routes_idea_create_with_positional_content
    with_real_test_project do |_dir|
      # Verify positional content routes to create subcommand
      result = invoke_cli(Ace::Taskflow::CLI, ["idea", "create", "my idea content"])
      output = result[:stdout] + result[:stderr]

      # Should accept positional content
      refute_match(/unknown command/i, output)
    end
  end

  # --- Idea Done Subcommand Tests ---

  def test_cli_routes_idea_done_command
    # Verify 'idea done' routes to the done subcommand
    result = invoke_cli(Ace::Taskflow::CLI, ["idea", "done", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for done command or indicate proper routing
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_idea_done_with_reference
    with_real_test_project do |_dir|
      # Verify done subcommand accepts idea reference
      result = invoke_cli(Ace::Taskflow::CLI, ["idea", "done", "some-idea"])
      output = result[:stdout] + result[:stderr]

      # Should not reject the reference
      refute_match(/unknown command/i, output)
    end
  end

  # --- Idea Park Subcommand Tests ---

  def test_cli_routes_idea_park_command
    # Verify 'idea park' routes to the park subcommand
    result = invoke_cli(Ace::Taskflow::CLI, ["idea", "park", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for park command or indicate proper routing
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_idea_park_with_reference
    with_real_test_project do |_dir|
      # Verify park subcommand accepts idea reference
      result = invoke_cli(Ace::Taskflow::CLI, ["idea", "park", "some-idea"])
      output = result[:stdout] + result[:stderr]

      # Should not reject the reference
      refute_match(/unknown command/i, output)
    end
  end

  # --- Idea Unpark Subcommand Tests ---

  def test_cli_routes_idea_unpark_command
    # Verify 'idea unpark' routes to the unpark subcommand
    result = invoke_cli(Ace::Taskflow::CLI, ["idea", "unpark", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for unpark command or indicate proper routing
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_idea_unpark_with_reference
    with_real_test_project do |_dir|
      # Verify unpark subcommand accepts idea reference
      result = invoke_cli(Ace::Taskflow::CLI, ["idea", "unpark", "some-idea"])
      output = result[:stdout] + result[:stderr]

      # Should not reject the reference
      refute_match(/unknown command/i, output)
    end
  end

  # --- Idea Reschedule Subcommand Tests ---

  def test_cli_routes_idea_reschedule_command
    # Verify 'idea reschedule' routes to the reschedule subcommand
    result = invoke_cli(Ace::Taskflow::CLI, ["idea", "reschedule", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for reschedule command or indicate proper routing
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_idea_reschedule_with_reference_and_date
    with_real_test_project do |_dir|
      # Verify reschedule subcommand accepts reference and date
      result = invoke_cli(Ace::Taskflow::CLI, ["idea", "reschedule", "some-idea", "tomorrow"])
      output = result[:stdout] + result[:stderr]

      # Should not reject the arguments
      refute_match(/unknown command/i, output)
    end
  end

  # --- Idea Subcommand Flag Handling Tests ---

  def test_idea_create_with_clipboard_flag
    with_real_test_project do |_dir|
      # Verify --clipboard flag is handled correctly by create subcommand
      # The command may raise IdeaWriterError if clipboard is empty - that's expected
      # The important thing is that the flag is recognized and parsed
      begin
        result = invoke_cli(Ace::Taskflow::CLI, ["idea", "create", "--clipboard"])
        output = result[:stdout] + result[:stderr]

        # Should not reject as unknown command
        refute_match(/unknown command/i, output)
      rescue Ace::Taskflow::Organisms::IdeaWriterError => e
        # Expected error when clipboard is empty - flag was recognized
        assert_match(/No content provided/, e.message)
      end
    end
  end

  def test_idea_create_with_location_flags
    with_real_test_project do |_dir|
      # Verify location flags (--backlog, --current, --release) work with create
      %w[--backlog --current].each do |flag|
        result = invoke_cli(Ace::Taskflow::CLI, ["idea", "create", flag])
        output = result[:stdout] + result[:stderr]
        refute_match(/unknown command/i, output, "Flag #{flag} should not cause unknown command error")
      end
    end
  end

  # --- Idea Base Command Tests ---

  def test_idea_base_command_still_works
    # Verify the base 'idea' command still works (shows next idea or specific idea)
    result = invoke_cli(Ace::Taskflow::CLI, ["idea", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for base idea command
    assert_match(/idea|show/i, output)
  end

  def test_idea_command_with_reference
    with_real_test_project do |_dir|
      # Verify 'idea <reference>' works (not routed to subcommands)
      result = invoke_cli(Ace::Taskflow::CLI, ["idea", "some-idea-ref"])
      output = result[:stdout] + result[:stderr]

      # Should show idea or appropriate error, not "unknown command"
      refute_match(/unknown command/i, output)
    end
  end
end
