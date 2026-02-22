# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Core
    module CLI
      module DryCli
        class HelpConciseTest < Minitest::Test
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

          # ---- HelpConcise.call (concise -h) ----

          def test_concise_help_has_header_line
            cmd = build_command(desc: "Load context from preset")
            output = HelpConcise.call(cmd, "ace-bundle load")

            assert_includes output, "ace-bundle load - Load context from preset"
          end

          def test_concise_help_has_usage_line
            cmd = build_command(
              desc: "Load context",
              arguments: [{ name: :input, required: false, desc: "Preset" }],
              options: [{ name: :quiet, type: :boolean }]
            )
            output = HelpConcise.call(cmd, "ace-bundle load")

            assert_includes output, "Usage: ace-bundle load [INPUT] [OPTIONS]"
          end

          def test_concise_help_has_options_without_descriptions
            cmd = build_command(
              desc: "Load",
              options: [
                { name: :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output" },
                { name: :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output" }
              ]
            )
            output = HelpConcise.call(cmd, "ace-bundle load")

            assert_includes output, "Options:"
            assert_includes output, "--[no-]quiet, -q"
            assert_includes output, "--[no-]verbose, -v"
            # Concise format should NOT include option descriptions
            refute_includes output, "Suppress output"
            refute_includes output, "Show verbose output"
          end

          def test_concise_help_includes_help_option
            cmd = build_command(desc: "Load")
            output = HelpConcise.call(cmd, "ace-bundle load")

            assert_includes output, "--help, -h"
          end

          def test_concise_help_limits_to_3_examples
            cmd = build_command(
              desc: "Load",
              examples: [
                "one",
                "two",
                "three",
                "four",
                "five"
              ]
            )
            output = HelpConcise.call(cmd, "my-tool")

            assert_includes output, "Examples:"
            assert_includes output, "$ my-tool one"
            assert_includes output, "$ my-tool two"
            assert_includes output, "$ my-tool three"
            refute_includes output, "$ my-tool four"
            refute_includes output, "$ my-tool five"
          end

          def test_concise_help_omits_examples_when_empty
            cmd = build_command(desc: "Load")
            output = HelpConcise.call(cmd, "ace-bundle load")

            refute_includes output, "Examples:"
          end

          def test_concise_help_has_footer
            cmd = build_command(desc: "Load")
            output = HelpConcise.call(cmd, "ace-bundle load")

            assert_includes output, "Run 'ace-bundle load --help' for full details."
          end

          def test_concise_help_strips_duplicate_command_name
            cmd = build_command(
              desc: "Analyze",
              examples: ["ace-docs analyze README.md"]
            )
            output = HelpConcise.call(cmd, "ace-docs analyze")

            assert_includes output, "$ ace-docs analyze README.md"
            refute_includes output, "ace-docs analyze ace-docs analyze"
          end

          def test_concise_help_no_description_shows_name_only
            cmd = build_command
            output = HelpConcise.call(cmd, "ace-test")

            # First line should just be the name without " - "
            first_line = output.lines.first.chomp
            assert_equal "ace-test", first_line
          end

          def test_concise_help_uses_first_line_of_multiline_desc
            cmd = build_command(desc: "First line summary\n\nDetailed paragraph")
            output = HelpConcise.call(cmd, "my-tool")

            assert_includes output, "my-tool - First line summary"
            refute_includes output, "Detailed paragraph"
          end
        end
      end
    end
  end
end
