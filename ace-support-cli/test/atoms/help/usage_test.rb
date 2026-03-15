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

  def test_renders_grouped_usage_with_examples
    output = Ace::Support::Cli::Usage.new(GroupedRegistry).render

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
end
