# frozen_string_literal: true

require "dry/cli"

module Ace
  module Core
    module CLI
      module DryCli
        # Concise help formatter for -h flag.
        #
        # Produces a compact, scannable output:
        #   command-name - summary
        #   Usage: command-name [ARGS] [OPTIONS]
        #   Options: (flag + alias only, no long descriptions)
        #   Run 'command-name --help' for full details.
        #
        # @since 0.12.0
        module HelpConcise
          # Render concise help for a subcommand.
          #
          # @param command [Dry::CLI::Command] the command
          # @param name [String] the program/command name
          # @return [String] compact help text
          def self.call(command, name)
            [
              header_line(command, name),
              usage_line(command, name),
              options_block(command),
              examples_block(command, name),
              footer_line(name)
            ].compact.join("\n\n")
          end

          # "command-name - one-line summary"
          def self.header_line(command, name)
            summary = first_line(command.description)
            summary ? "#{name} - #{summary}" : name.to_s
          end

          # "Usage: command-name [ARGS] [OPTIONS]"
          def self.usage_line(command, name)
            args = arguments_synopsis(command)
            opts = command.options.any? ? " [OPTIONS]" : ""
            "Usage: #{name}#{args}#{opts}"
          end

          # Compact options: flag + alias + type only, no descriptions
          def self.options_block(command)
            lines = command.options.map do |option|
              format_option_concise(option)
            end
            lines << "  --help, -h            Show this help"

            "Options:\n#{lines.join("\n")}"
          end

          # Show up to 3 examples in compact form
          def self.examples_block(command, name)
            return nil if command.examples.empty?

            examples = command.examples.first(3).map do |example|
              cleaned = example.to_s.sub(/\A#{Regexp.escape(name)}\s*/, "")
              "  $ #{name} #{cleaned}".rstrip
            end

            "Examples:\n#{examples.join("\n")}"
          end

          # Footer suggesting --help for full details
          def self.footer_line(name)
            "Run '#{name} --help' for full details."
          end

          # --- Private helpers ---

          def self.first_line(description)
            return nil if description.nil?
            description.to_s.strip.split("\n").first&.strip
          end

          def self.arguments_synopsis(command)
            required = command.required_arguments.map { |a| a.name.upcase }
            optional = command.optional_arguments.map { |a| "[#{a.name.upcase}]" }
            result = (required + optional).compact
            result.empty? ? "" : " #{result.join(" ")}"
          end

          # Format option for concise display: --flag, -alias TYPE
          def self.format_option_concise(option)
            name = ::Dry::CLI::Inflector.dasherize(option.name)
            name = if option.boolean?
                     "[no-]#{name}"
                   elsif option.flag?
                     name
                   elsif option.array?
                     "#{name} VALUES"
                   else
                     "#{name} VALUE"
                   end

            if option.aliases.any?
              name = "#{name}, #{option.alias_names.join(", ")}"
            end

            "  --#{name}"
          end
        end
      end
    end
  end
end
