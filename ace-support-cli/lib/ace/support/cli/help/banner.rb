# frozen_string_literal: true

module Ace
  module Support
    module Cli
      module Help
        module Banner
          COLUMN_WIDTH = 34

          def self.call(command, name)
            [
              section_name(command, name),
              section_usage(command, name),
              section_description(command),
              section_subcommands(command),
              section_arguments(command),
              section_options(command),
              section_examples(command, name)
            ].compact.join("\n\n")
          end

          def self.section_name(command, name)
            summary = first_line(description(command))
            line = summary ? "#{name} - #{summary}" : name.to_s
            "NAME\n  #{line}"
          end

          def self.section_usage(command, name)
            usage = "#{name}#{arguments_synopsis(command)}"
            usage += " [OPTIONS]" if options(command).any?
            usage += " | #{name} SUBCOMMAND" if subcommands(command).any?
            "USAGE\n  #{usage}"
          end

          def self.section_description(command)
            text = description(command)
            return nil if text.nil?

            lines = text.to_s.strip.split("\n")
            return nil if lines.size <= 1

            rest = lines.drop(1).drop_while { |line| line.strip.empty? }
            return nil if rest.empty?

            "DESCRIPTION\n#{rest.map { |line| "  #{line.strip}" }.join("\n")}"
          end

          def self.section_subcommands(command)
            entries = subcommands(command)
            return nil if entries.empty?

            lines = entries.filter_map do |name, subcommand|
              next if hidden?(subcommand)

              desc = description(subcommand)
              "  #{name.to_s.ljust(COLUMN_WIDTH)}#{first_line(desc)}"
            end
            return nil if lines.empty?

            "SUBCOMMANDS\n#{lines.join("\n")}"
          end

          def self.section_arguments(command)
            args = arguments(command)
            return nil if args.empty?

            lines = args.map do |arg|
              label = arg.name.to_s.upcase
              label = "[#{label}]" unless argument_required?(arg)
              details = []
              details << argument_desc(arg) unless argument_desc(arg).to_s.empty?
              details << "(required)" if argument_required?(arg)
              "  #{label.ljust(COLUMN_WIDTH)}#{details.join(" ")}"
            end
            "ARGUMENTS\n#{lines.join("\n")}"
          end

          def self.section_options(command)
            lines = options(command).map { |option| format_option(option) }
            lines << "  #{"--help, -h".ljust(COLUMN_WIDTH)}Show this help"
            "OPTIONS\n#{lines.join("\n")}"
          end

          def self.section_examples(command, name)
            items = examples(command)
            return nil if items.empty?

            lines = items.map do |item|
              cleaned = item.to_s.sub(/\A#{Regexp.escape(name)}\s*/, "")
              "  $ #{name} #{cleaned}".rstrip
            end
            "EXAMPLES\n#{lines.join("\n")}"
          end

          def self.format_option(option)
            rendered = option_name(option)
            rendered = "#{rendered}, #{option_aliases(option).join(", ")}" if option_aliases(option).any?
            label = "  --#{rendered}"

            details = []
            desc = option_desc(option)
            details << desc unless desc.to_s.empty?
            values = option_values(option)
            details << "(values: #{Array(values).join(", ")})" if values && !Array(values).empty?
            default = option_default(option)
            details << "(default: #{default.inspect})" unless default.nil?
            details << "(required)" if option_required?(option)

            return label if details.empty?

            "#{label.ljust(COLUMN_WIDTH + 2)}#{details.join(" ")}"
          end

          def self.option_name(option)
            name = dasherize(option_name_raw(option))
            if option_boolean?(option)
              "[no-]#{name}"
            elsif option_array?(option)
              "#{name}=VALUE1,VALUE2,.."
            elsif option_flag?(option)
              name
            else
              "#{name}=VALUE"
            end
          end

          def self.arguments_synopsis(command)
            required = arguments(command).select { |arg| argument_required?(arg) }.map { |arg| arg.name.to_s.upcase }
            optional = arguments(command).reject { |arg| argument_required?(arg) }.map { |arg| "[#{arg.name.to_s.upcase}]" }
            values = required + optional
            values.empty? ? "" : " #{values.join(" ")}"
          end

          def self.description(command)
            command.respond_to?(:description) ? command.description : nil
          end

          def self.subcommands(command)
            return [] unless command.respond_to?(:subcommands)

            value = command.subcommands
            return value.to_a if value.respond_to?(:to_a)

            []
          end

          def self.hidden?(command)
            command.respond_to?(:hidden) && command.hidden
          end

          def self.arguments(command)
            return command.arguments if command.respond_to?(:arguments)
            return [] unless command.respond_to?(:required_arguments) && command.respond_to?(:optional_arguments)

            command.required_arguments + command.optional_arguments
          end

          def self.argument_required?(argument)
            argument.respond_to?(:required?) ? argument.required? : !!argument.required
          end

          def self.argument_desc(argument)
            argument.respond_to?(:desc) ? argument.desc : nil
          end

          def self.options(command)
            command.respond_to?(:options) ? command.options : []
          end

          def self.examples(command)
            command.respond_to?(:examples) ? command.examples : []
          end

          def self.option_name_raw(option)
            return option.name if option.respond_to?(:name)
            return option.option_name if option.respond_to?(:option_name)

            "option"
          end

          def self.option_aliases(option)
            return option.alias_names if option.respond_to?(:alias_names)
            return option.aliases if option.respond_to?(:aliases)

            []
          end

          def self.option_desc(option)
            option.respond_to?(:desc) ? option.desc : nil
          end

          def self.option_default(option)
            option.respond_to?(:default) ? option.default : nil
          end

          def self.option_values(option)
            option.respond_to?(:values) ? option.values : nil
          end

          def self.option_required?(option)
            return option.required if option.respond_to?(:required)
            return option.required? if option.respond_to?(:required?)

            false
          end

          def self.option_boolean?(option)
            return option.boolean? if option.respond_to?(:boolean?)

            option.respond_to?(:type) && option.type.to_sym == :boolean
          end

          def self.option_array?(option)
            return option.array? if option.respond_to?(:array?)

            option.respond_to?(:type) && option.type.to_sym == :array
          end

          def self.option_flag?(option)
            return option.flag? if option.respond_to?(:flag?)

            false
          end

          def self.first_line(text)
            return nil if text.nil?

            text.to_s.strip.split("\n").first&.strip
          end

          def self.dasherize(value)
            value.to_s.tr("_", "-")
          end
        end
      end
    end
  end
end
