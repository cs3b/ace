# frozen_string_literal: true

module Ace
  module Support
    module Cli
      module Help
        module Concise
          def self.call(command, name)
            [
              header_line(command, name),
              usage_line(command, name),
              options_block(command),
              examples_block(command, name),
              footer_line(name)
            ].compact.join("\n\n")
          end

          def self.header_line(command, name)
            summary = first_line(command.respond_to?(:description) ? command.description : nil)
            summary ? "#{name} - #{summary}" : name.to_s
          end

          def self.usage_line(command, name)
            args = Banner.arguments_synopsis(command)
            opts = Banner.options(command).any? ? " [OPTIONS]" : ""
            "Usage: #{name}#{args}#{opts}"
          end

          def self.options_block(command)
            lines = Banner.options(command).map { |option| format_option(option) }
            lines << "  --help, -h            Show this help"
            "Options:\n#{lines.join("\n")}"
          end

          def self.examples_block(command, name)
            items = Banner.examples(command)
            return nil if items.empty?

            rendered = items.first(3).map do |item|
              cleaned = item.to_s.sub(/\A#{Regexp.escape(name)}\s*/, "")
              "  $ #{name} #{cleaned}".rstrip
            end
            "Examples:\n#{rendered.join("\n")}"
          end

          def self.footer_line(name)
            "Run '#{name} --help' for full details."
          end

          def self.format_option(option)
            name = Banner.option_name(option).sub("=VALUE1,VALUE2,..", " VALUES").sub("=VALUE", " VALUE")
            aliases = Banner.option_aliases(option)
            name = "#{name}, #{aliases.join(", ")}" if aliases.any?
            "  --#{name}"
          end

          def self.first_line(text)
            return nil if text.nil?

            text.to_s.strip.split("\n").first&.strip
          end
        end
      end
    end
  end
end
