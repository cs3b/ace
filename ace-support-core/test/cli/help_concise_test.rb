# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Core
    module CLI
      class HelpConciseTest < Minitest::Test
        def build_command(desc: nil, arguments: [], options: [], examples: [])
          cmd_class = Class.new(Ace::Support::Cli::Command)
          cmd_class.class_eval do
            self.desc desc if desc
            examples.each { |ex| example(ex) } if examples.any?
            arguments.each { |arg| argument arg[:name], **arg.except(:name) }
            options.each { |opt| option opt[:name], **opt.except(:name) }
          end
          cmd_class
        end

        def test_concise_help_has_header_and_usage
          cmd = build_command(
            desc: "Load context",
            arguments: [{ name: :input, required: false, desc: "Preset" }],
            options: [{ name: :quiet, type: :boolean }]
          )

          output = HelpConcise.call(cmd, "ace-bundle load")
          assert_includes output, "ace-bundle load - Load context"
          assert_includes output, "Usage: ace-bundle load [INPUT] [OPTIONS]"
        end

        def test_concise_help_includes_help_option_and_footer
          cmd = build_command(desc: "Load")
          output = HelpConcise.call(cmd, "ace-bundle load")

          assert_includes output, "--help, -h"
          assert_includes output, "Run 'ace-bundle load --help' for full details."
        end

        def test_concise_help_limits_to_3_examples
          cmd = build_command(desc: "Load", examples: %w[one two three four])
          output = HelpConcise.call(cmd, "my-tool")

          assert_includes output, "$ my-tool one"
          assert_includes output, "$ my-tool three"
          refute_includes output, "$ my-tool four"
        end
      end
    end
  end
end
