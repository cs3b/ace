# frozen_string_literal: true

module Ace
  module Support
    module Cli
      module Help
        class Usage
          COLUMN_WIDTH = 34

          def initialize(registry, program_name: nil)
            @registry = registry
            @program_name = program_name
          end

          def render
            commands = visible_commands
            groups = command_groups
            output = if groups && !groups.empty?
                       format_grouped(commands, groups)
                     else
                       format_flat(commands, header: "COMMANDS")
                     end

            examples = help_examples
            output += "\n\n#{format_examples(examples)}" if examples && !examples.empty?
            output
          end

          def render_concise
            output = format_flat(visible_commands, header: "Commands:")
            output + "\n\nRun '#{resolved_program_name} --help' for more info. Each command has its own --help."
          end

          private

          attr_reader :registry, :program_name

          def visible_commands
            all_commands.reject { |_name, value| value[:hidden] }
          end

          def all_commands
            if registry.respond_to?(:commands)
              convert_commands_hash(registry.commands)
            elsif registry.is_a?(Hash)
              convert_commands_hash(registry)
            elsif registry.respond_to?(:to_h)
              convert_commands_hash(registry.to_h)
            else
              []
            end.sort_by { |name, _| name }
          end

          def convert_commands_hash(hash)
            hash.map do |name, command|
              [name.to_s, { description: first_line(description(command)), hidden: hidden?(command) }]
            end
          end

          def format_flat(commands, header:)
            lines = commands.map do |name, meta|
              banner = "  #{name}"
              details = meta[:description] ? " # #{meta[:description]}" : nil
              justify(banner, details)
            end

            ([header] + lines).join("\n")
          end

          def format_grouped(commands, groups)
            index = commands.to_h
            grouped_names = groups.values.flatten.map(&:to_s)
            output = ["COMMANDS"]

            groups.each do |group_name, names|
              lines = names.filter_map do |name|
                meta = index[name.to_s]
                next unless meta

                banner = "  #{name}"
                details = meta[:description] ? " # #{meta[:description]}" : nil
                justify(banner, details, indent: 2)
              end
              next if lines.empty?

              output << ""
              output << "  #{group_name}"
              output.concat(lines)
            end

            ungrouped = commands.filter_map do |name, meta|
              next if grouped_names.include?(name)

              banner = "  #{name}"
              details = meta[:description] ? " # #{meta[:description]}" : nil
              justify(banner, details)
            end

            unless ungrouped.empty?
              output << ""
              output.concat(ungrouped)
            end
            output.join("\n")
          end

          def justify(banner, details, indent: 0)
            return "#{" " * indent}#{banner}" if details.nil?

            base = banner.ljust(COLUMN_WIDTH)
            "#{" " * indent}#{base}#{details}"
          end

          def command_groups
            return nil unless registry.respond_to?(:const_defined?)
            return nil unless registry.const_defined?(:COMMAND_GROUPS)

            registry.const_get(:COMMAND_GROUPS)
          end

          def help_examples
            return nil unless registry.respond_to?(:const_defined?)
            return nil unless registry.const_defined?(:HELP_EXAMPLES)

            registry.const_get(:HELP_EXAMPLES)
          end

          def format_examples(examples)
            lines = examples.map { |desc, cmd| "  $ #{cmd}  # #{desc}" }
            "EXAMPLES\n#{lines.join("\n")}"
          end

          def resolved_program_name
            return program_name unless program_name.nil? || program_name.empty?
            return registry.const_get(:PROGRAM_NAME) if registry.respond_to?(:const_defined?) && registry.const_defined?(:PROGRAM_NAME)

            $PROGRAM_NAME.split("/").last
          end

          def description(command)
            command.respond_to?(:description) ? command.description : nil
          end

          def hidden?(command)
            command.respond_to?(:hidden) && command.hidden
          end

          def first_line(text)
            return nil if text.nil?

            text.to_s.strip.split("\n").first&.strip
          end
        end
      end
    end
  end
end
