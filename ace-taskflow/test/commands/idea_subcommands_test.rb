# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/cli/idea_cli"
require "ace/test_support/cli_helpers"

# Tests for flat idea CLI routing (ace-idea)
# Ensures dry-cli properly routes to idea subcommands (create, done, park, unpark, reschedule)
class IdeaSubcommandsTest < AceTaskflowTestCase
  include Ace::TestSupport::CliHelpers

  # --- Idea Create Subcommand Tests ---

  def test_cli_routes_idea_create_command
    # Verify 'ace-idea create' routes to the create subcommand
    result = invoke_cli(Ace::Taskflow::IdeaCLI, ["create", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for create command or indicate proper routing
    refute_match(/unknown command/i, output)
    assert_match(/create|Usage|content/i, output)
  end

  def test_cli_routes_idea_create_with_note_flag
    with_real_test_project do |_dir|
      # Verify --note flag routes correctly to create subcommand
      result = invoke_cli(Ace::Taskflow::IdeaCLI, ["create", "--note", "test content"])
      output = result[:stdout] + result[:stderr]

      # Should not reject the command or flag
      refute_match(/unknown command/i, output)
    end
  end

  def test_cli_routes_idea_create_with_positional_content
    with_real_test_project do |_dir|
      # Verify positional content routes to create subcommand
      result = invoke_cli(Ace::Taskflow::IdeaCLI, ["create", "my idea content"])
      output = result[:stdout] + result[:stderr]

      # Should accept positional content
      refute_match(/unknown command/i, output)
    end
  end

  # --- Idea Done Subcommand Tests ---

  def test_cli_routes_idea_done_command
    # Verify 'ace-idea done' routes to the done subcommand
    result = invoke_cli(Ace::Taskflow::IdeaCLI, ["done", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for done command or indicate proper routing
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_idea_done_with_reference
    with_real_test_project do |_dir|
      # Verify done subcommand accepts idea reference
      result = invoke_cli(Ace::Taskflow::IdeaCLI, ["done", "some-idea"])
      output = result[:stdout] + result[:stderr]

      # Should not reject the reference
      refute_match(/unknown command/i, output)
    end
  end

  # --- Idea Park Subcommand Tests ---

  def test_cli_routes_idea_park_command
    # Verify 'ace-idea park' routes to the park subcommand
    result = invoke_cli(Ace::Taskflow::IdeaCLI, ["park", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for park command or indicate proper routing
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_idea_park_with_reference
    with_real_test_project do |_dir|
      # Verify park subcommand accepts idea reference
      result = invoke_cli(Ace::Taskflow::IdeaCLI, ["park", "some-idea"])
      output = result[:stdout] + result[:stderr]

      # Should not reject the reference
      refute_match(/unknown command/i, output)
    end
  end

  # --- Idea Unpark Subcommand Tests ---

  def test_cli_routes_idea_unpark_command
    # Verify 'ace-idea unpark' routes to the unpark subcommand
    result = invoke_cli(Ace::Taskflow::IdeaCLI, ["unpark", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for unpark command or indicate proper routing
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_idea_unpark_with_reference
    with_real_test_project do |_dir|
      # Verify unpark subcommand accepts idea reference
      result = invoke_cli(Ace::Taskflow::IdeaCLI, ["unpark", "some-idea"])
      output = result[:stdout] + result[:stderr]

      # Should not reject the reference
      refute_match(/unknown command/i, output)
    end
  end

  # --- Idea Reschedule Subcommand Tests ---

  def test_cli_routes_idea_reschedule_command
    # Verify 'ace-idea reschedule' routes to the reschedule subcommand
    result = invoke_cli(Ace::Taskflow::IdeaCLI, ["reschedule", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for reschedule command or indicate proper routing
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_idea_reschedule_with_reference_and_date
    with_real_test_project do |_dir|
      # Verify reschedule subcommand accepts reference and date
      result = invoke_cli(Ace::Taskflow::IdeaCLI, ["reschedule", "some-idea", "tomorrow"])
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
        result = invoke_cli(Ace::Taskflow::IdeaCLI, ["create", "--clipboard"])
        output = result[:stdout] + result[:stderr]

        # Should not reject as unknown command
        refute_match(/unknown command/i, output)
      rescue Ace::Taskflow::Organisms::IdeaWriterError => e
        # Expected error when clipboard is empty - flag was recognized
        # Error message varies by platform (macOS vs Linux)
        assert_match(/No content provided|Clipboard is empty/, e.message)
      end
    end
  end

  def test_idea_create_with_location_flags
    with_real_test_project do |_dir|
      # Verify location flags (--backlog, --current, --release) work with create
      %w[--backlog --current].each do |flag|
        result = invoke_cli(Ace::Taskflow::IdeaCLI, ["create", flag])
        output = result[:stdout] + result[:stderr]
        refute_match(/unknown command/i, output, "Flag #{flag} should not cause unknown command error")
      end
    end
  end

  # --- Idea Base Command Tests ---

  def test_idea_base_command_still_works
    # Verify the base 'ace-idea show' command still works (shows specific idea)
    result = invoke_cli(Ace::Taskflow::IdeaCLI, ["show", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help for show command
    assert_match(/idea|show/i, output)
  end

  def test_idea_command_with_reference
    with_real_test_project do |_dir|
      # Verify 'ace-idea show <reference>' works
      result = invoke_cli(Ace::Taskflow::IdeaCLI, ["show", "some-idea-ref"])
      output = result[:stdout] + result[:stderr]

      # Should show idea or appropriate error, not "unknown command"
      refute_match(/unknown command/i, output)
    end
  end
end
