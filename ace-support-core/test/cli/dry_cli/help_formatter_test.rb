# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Core
    module CLI
      module DryCli
        class HelpFormatterTest < Minitest::Test
          # Build a test command class with configurable attributes
          def build_command(desc: nil, arguments: [], options: [], examples: [])
            cmd_class = Class.new(Dry::CLI::Command) do
              include Ace::Core::CLI::DryCli::Base
            end

            cmd_class.class_eval do
              self.desc desc if desc
              examples.each { |ex| example(ex) } if examples.any?
              arguments.each { |a| argument a[:name], **a.except(:name) }
              options.each { |o| option o[:name], **o.except(:name) }
            end

            cmd_class.new
          end

          # ---- Banner.call (full --help) ----

          def test_full_help_has_name_section
            cmd = build_command(desc: "Load context from preset")
            output = Dry::CLI::Banner.call(cmd, "ace-bundle load")

            assert_includes output, "NAME"
            assert_includes output, "ace-bundle load - Load context from preset"
          end

          def test_full_help_has_usage_section
            cmd = build_command(
              desc: "Load context",
              arguments: [{ name: :input, required: false, desc: "Preset name" }]
            )
            output = Dry::CLI::Banner.call(cmd, "ace-bundle load")

            assert_includes output, "USAGE"
            assert_includes output, "ace-bundle load [INPUT]"
          end

          def test_full_help_has_usage_with_options_tag
            cmd = build_command(
              desc: "Load context",
              options: [{ name: :quiet, type: :boolean, desc: "Suppress output" }]
            )
            output = Dry::CLI::Banner.call(cmd, "ace-bundle load")

            assert_includes output, "[OPTIONS]"
          end

          def test_full_help_has_description_section_for_multiline_desc
            cmd = build_command(desc: "Load context from preset\n\nINPUT can be a preset name.")
            output = Dry::CLI::Banner.call(cmd, "ace-bundle load")

            assert_includes output, "DESCRIPTION"
            assert_includes output, "INPUT can be a preset name."
          end

          def test_full_help_omits_description_for_single_line_desc
            cmd = build_command(desc: "Load context from preset")
            output = Dry::CLI::Banner.call(cmd, "ace-bundle load")

            refute_includes output, "DESCRIPTION"
          end

          def test_full_help_has_arguments_section
            cmd = build_command(
              desc: "Load",
              arguments: [{ name: :input, required: false, desc: "Preset name" }]
            )
            output = Dry::CLI::Banner.call(cmd, "ace-bundle load")

            assert_includes output, "ARGUMENTS"
            assert_includes output, "[INPUT]"
            assert_includes output, "Preset name"
          end

          def test_full_help_has_options_section
            cmd = build_command(
              desc: "Load",
              options: [{ name: :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output" }]
            )
            output = Dry::CLI::Banner.call(cmd, "ace-bundle load")

            assert_includes output, "OPTIONS"
            assert_includes output, "--[no-]quiet, -q"
            assert_includes output, "Suppress output"
            assert_includes output, "--help, -h"
          end

          def test_full_help_has_examples_section
            cmd = build_command(
              desc: "Load",
              examples: ["project    # Load project preset"]
            )
            output = Dry::CLI::Banner.call(cmd, "ace-bundle load")

            assert_includes output, "EXAMPLES"
            assert_includes output, "$ ace-bundle load project"
          end

          def test_full_help_omits_examples_when_empty
            cmd = build_command(desc: "Load")
            output = Dry::CLI::Banner.call(cmd, "ace-bundle load")

            refute_includes output, "EXAMPLES"
          end

          def test_full_help_strips_duplicate_command_name_from_examples
            cmd = build_command(
              desc: "Analyze",
              examples: ["ace-docs analyze README.md"]
            )
            output = Dry::CLI::Banner.call(cmd, "ace-docs analyze")

            # Should show "$ ace-docs analyze README.md", not "$ ace-docs analyze ace-docs analyze README.md"
            assert_includes output, "$ ace-docs analyze README.md"
            refute_includes output, "ace-docs analyze ace-docs analyze"
          end

          def test_full_help_name_section_without_description
            cmd = build_command
            output = Dry::CLI::Banner.call(cmd, "ace-test")

            assert_includes output, "NAME"
            assert_includes output, "ace-test"
            refute_includes output, " - "
          end

          def test_full_help_shows_required_argument_without_brackets
            cmd = build_command(
              desc: "Analyze",
              arguments: [{ name: :file, required: true, desc: "File to analyze" }]
            )
            output = Dry::CLI::Banner.call(cmd, "ace-docs analyze")

            # Required arguments in USAGE should be uppercase without brackets
            assert_includes output, "ace-docs analyze FILE"
            # In ARGUMENTS section, should show desc
            assert_includes output, "FILE"
            assert_includes output, "File to analyze"
          end

          def test_full_help_shows_option_defaults
            cmd = build_command(
              desc: "Test",
              options: [{ name: :timeout, type: :string, default: "30", desc: "Timeout in seconds" }]
            )
            output = Dry::CLI::Banner.call(cmd, "my-tool")

            assert_includes output, "Timeout in seconds"
            assert_includes output, '(default: "30")'
          end

          # ---- Banner.first_line ----

          def test_first_line_returns_first_line_of_multiline
            result = Dry::CLI::Banner.first_line("First line\nSecond line")
            assert_equal "First line", result
          end

          def test_first_line_returns_nil_for_nil
            assert_nil Dry::CLI::Banner.first_line(nil)
          end

          def test_first_line_returns_single_line
            result = Dry::CLI::Banner.first_line("Only line")
            assert_equal "Only line", result
          end
        end
      end
    end
  end
end
