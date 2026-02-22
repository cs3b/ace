# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Core
    module CLI
      module DryCli
        class UsageFormatterTest < Minitest::Test
          # Build a test registry with commands
          def build_registry(commands = {})
            registry = Module.new do
              extend Dry::CLI::Registry
            end

            commands.each do |name, desc|
              cmd_class = Class.new(Dry::CLI::Command)
              cmd_class.class_eval do
                self.desc desc
              end
              registry.register(name, cmd_class)
            end

            registry
          end

          # ---- Usage.description ----

          def test_description_returns_first_line_only
            cmd_class = Class.new(Dry::CLI::Command) do
              desc "First line\nSecond line\nThird line"
            end

            result = Dry::CLI::Usage.description(cmd_class)
            assert_equal " # First line", result
          end

          def test_description_returns_nil_for_nil_description
            cmd_class = Class.new(Dry::CLI::Command)

            result = Dry::CLI::Usage.description(cmd_class)
            assert_nil result
          end

          def test_description_returns_single_line_desc
            cmd_class = Class.new(Dry::CLI::Command) do
              desc "Simple description"
            end

            result = Dry::CLI::Usage.description(cmd_class)
            assert_equal " # Simple description", result
          end

          # ---- Usage.call (full format) ----

          def test_full_usage_has_commands_header
            registry = build_registry("load" => "Load context", "list" => "List presets")
            result = registry.get([])
            output = Dry::CLI::Usage.call(result)

            assert output.start_with?("COMMANDS"), "Expected output to start with 'COMMANDS', got: #{output.lines.first}"
          end

          def test_full_usage_lists_commands_with_descriptions
            registry = build_registry("load" => "Load context", "list" => "List presets")
            result = registry.get([])
            output = Dry::CLI::Usage.call(result)

            assert_includes output, "load"
            assert_includes output, "# Load context"
            assert_includes output, "list"
            assert_includes output, "# List presets"
          end

          # ---- Usage.call_concise (concise format) ----

          def test_concise_usage_has_commands_colon_header
            registry = build_registry("load" => "Load context")
            result = registry.get([])
            output = Dry::CLI::Usage.call_concise(result)

            assert output.start_with?("Commands:"), "Expected output to start with 'Commands:', got: #{output.lines.first}"
          end

          def test_concise_usage_lists_commands
            registry = build_registry("load" => "Load context", "list" => "List presets")
            result = registry.get([])
            output = Dry::CLI::Usage.call_concise(result)

            assert_includes output, "load"
            assert_includes output, "# Load context"
          end

          # ---- Multiline desc fix: first line only in registry listing ----

          def test_multiline_desc_shows_first_line_only_in_registry
            registry = build_registry(
              "load" => "Load context from preset\n\nINPUT can be a preset name.\nProtocols: wfi://, guide://"
            )
            result = registry.get([])
            output = Dry::CLI::Usage.call(result)

            assert_includes output, "# Load context from preset"
            refute_includes output, "INPUT can be a preset name"
            refute_includes output, "Protocols:"
          end

          # ---- Grouped commands ----

          def test_grouped_usage_with_command_groups
            registry = build_registry(
              "task" => "Manage tasks",
              "tasks" => "List tasks",
              "status" => "Show status",
              "version" => "Show version"
            )

            registry.const_set(:COMMAND_GROUPS, {
              "Task Management" => %w[task tasks],
              "Utilities" => %w[status]
            })

            result = registry.get([])
            output = Dry::CLI::Usage.call(result, registry: registry)

            assert_includes output, "COMMANDS"
            assert_includes output, "Task Management"
            assert_includes output, "Utilities"
          end

          def test_ungrouped_commands_appear_at_end
            registry = build_registry(
              "task" => "Manage tasks",
              "version" => "Show version"
            )

            registry.const_set(:COMMAND_GROUPS, {
              "Task Management" => %w[task]
            })

            result = registry.get([])
            output = Dry::CLI::Usage.call(result, registry: registry)

            # "version" is not in any group, should still appear
            assert_includes output, "version"
          end

          def test_no_groups_shows_flat_list
            registry = build_registry("load" => "Load context", "list" => "List presets")
            result = registry.get([])
            output = Dry::CLI::Usage.call(result)

            # Should be flat list without group headings
            assert_includes output, "COMMANDS"
            refute_includes output, "Task Management"
          end

          # ---- Two-tier routing integration ----

          def test_default_routing_help_renders_full_format
            registry = build_routing_registry("load" => "Load context")

            stdout, = capture_io do
              registry.start(["--help"])
            end

            assert_includes stdout, "COMMANDS"
            assert_includes stdout, "Load context"
          end

          def test_default_routing_concise_h_renders_compact_format
            registry = build_routing_registry("load" => "Load context")

            stdout, = capture_io do
              registry.start(["-h"])
            end

            assert_includes stdout, "Commands:"
            assert_includes stdout, "Load context"
          end

          private

          def build_routing_registry(commands = {})
            reg = Module.new do
              extend Dry::CLI::Registry
              extend Ace::Core::CLI::DryCli::DefaultRouting
            end

            commands.each do |name, desc|
              cmd_class = Class.new(Dry::CLI::Command) { self.desc desc }
              reg.register(name, cmd_class)
            end

            all_cmds = commands.keys + %w[version help --help -h --version]
            reg.const_set(:KNOWN_COMMANDS, Set.new(all_cmds))
            reg.const_set(:DEFAULT_COMMAND, commands.keys.first)

            reg
          end
        end
      end
    end
  end
end
