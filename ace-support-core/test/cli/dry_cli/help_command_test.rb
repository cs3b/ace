# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Core
    module CLI
      module DryCli
        class HelpCommandTest < AceTestCase
          def test_build_creates_dry_cli_command_class
            help_cmd = HelpCommand.build(
              program_name: "ace-sample",
              version: "0.1.0",
              commands: [["status", "Show status"]]
            )

            assert_kind_of Class, help_cmd
            assert_includes help_cmd.ancestors.to_s, "Dry::CLI::Command"
          end

          def test_build_outputs_required_sections
            help_cmd = HelpCommand.build(
              program_name: "ace-sample",
              version: "0.1.0",
              commands: [
                ["status", "Show status"],
                ["doctor", "Run diagnostics"]
              ],
              examples: [
                "ace-sample status",
                "ace-sample doctor"
              ]
            )

            output = capture_stdout do
              help_cmd.new.call
            end

            assert_includes output, "ace-sample 0.1.0"
            assert_includes output, "Commands:"
            assert_includes output, "status"
            assert_includes output, "doctor"
            assert_includes output, "Examples:"
            assert_includes output, "ace-sample status"
            assert_includes output, "Options:"
            assert_includes output, "--help, -h"
            assert_includes output, "--version"
          end

          def test_examples_section_is_omitted_when_not_provided
            help_cmd = HelpCommand.build(
              program_name: "ace-sample",
              version: "0.1.0",
              commands: [["status", "Show status"]]
            )

            output = capture_stdout do
              help_cmd.new.call
            end

            refute_includes output, "Examples:"
          end

          def test_call_returns_zero
            help_cmd = HelpCommand.build(
              program_name: "ace-sample",
              version: "0.1.0",
              commands: [["status", "Show status"]]
            )

            assert_equal 0, help_cmd.new.call
          end

          def test_registry_alias_registration_for_help_flags
            registry = Class.new { extend Dry::CLI::Registry }
            help_cmd = HelpCommand.build(
              program_name: "ace-sample",
              version: "0.1.0",
              commands: [["status", "Show status"]]
            )

            registry.register "--help", help_cmd
            registry.register "-h", help_cmd

            assert registry
          end
        end
      end
    end
  end
end
