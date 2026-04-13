# frozen_string_literal: true

require_relative "../../test_helper"

class HelpUsageTest < AceSupportCliTestCase
  CommandMeta = Struct.new(:description, :hidden)

  module GroupedRegistry
    PROGRAM_NAME = "ace-tool"
    COMMAND_GROUPS = {
      "Core" => ["lint", "test"]
    }.freeze
    HELP_EXAMPLES = [
      ["Lint project", "ace-tool lint ."]
    ].freeze

    def self.commands
      {
        "lint" => CommandMeta.new("Run linter\nwith extra details", false),
        "test" => CommandMeta.new("Run tests", false),
        "doctor" => CommandMeta.new("Run diagnostics", false),
        "hidden" => CommandMeta.new("Internal", true)
      }
    end
  end

  module RegisteredCommandRegistry
    PROGRAM_NAME = "ace-review-feedback"
    REGISTERED_COMMANDS = [
      ["list", "List feedback items"],
      ["show", "Show feedback item"]
    ].freeze
    HELP_EXAMPLES = [
      "ace-review-feedback list",
      "ace-review-feedback show 123"
    ].freeze
  end

  def test_renders_grouped_usage_with_examples
    output = Ace::Support::Cli::Usage.new(GroupedRegistry).render

    assert_includes output, "Usage: ace-tool"
    assert_includes output, "COMMANDS"
    assert_includes output, "  Core"
    assert_includes output, "lint"
    assert_includes output, "test"
    assert_includes output, "doctor"
    assert_includes output, "EXAMPLES\n  $ ace-tool lint .  # Lint project"
    refute_includes output, "hidden"
    refute_includes output, "with extra details"
  end

  def test_renders_concise_usage_with_footer
    output = Ace::Support::Cli::Usage.new(GroupedRegistry).render_concise

    assert_includes output, "Commands:"
    assert_includes output, "Run 'ace-tool --help' for more info."
  end

  def test_renders_registered_commands_and_string_examples
    output = Ace::Support::Cli::Usage.new(RegisteredCommandRegistry).render

    assert_includes output, "Usage: ace-review-feedback"
    assert_includes output, "list"
    assert_includes output, "show"
    assert_includes output, "EXAMPLES"
    assert_includes output, "ace-review-feedback list"
  end
end
