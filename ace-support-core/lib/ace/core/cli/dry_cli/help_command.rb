# frozen_string_literal: true

require "dry/cli"

module Ace
  module Core
    module CLI
      module DryCli
        # Helper for creating standard top-level help commands in dry-cli registries.
        #
        # Use this for multi-command tools that register `--help` and `-h` as explicit
        # commands at the registry level.
        module HelpCommand
          def self.build(program_name:, version:, commands:, examples: nil)
            Class.new(Dry::CLI::Command) do
              @program_name = program_name
              @version = version
              @commands = commands
              @examples = examples

              class << self
                attr_reader :program_name, :version, :commands, :examples
              end

              desc "Show top-level help"

              def call(*)
                puts self.class.render
                0
              end

              def self.render
                sections = []
                sections << "#{program_name} #{version}".strip
                sections << render_commands
                rendered_examples = render_examples
                sections << rendered_examples if rendered_examples
                sections << render_options
                sections.join("\n\n")
              end

              def self.render_commands
                lines = normalized_commands.map do |name, description|
                  formatted = "  #{name}".ljust(16)
                  "#{formatted}# #{description}"
                end
                "Commands:\n#{lines.join("\n")}"
              end

              def self.render_examples
                return nil if examples.nil? || examples.empty?

                lines = examples.map { |example| "  #{example}" }
                "Examples:\n#{lines.join("\n")}"
              end

              def self.render_options
                <<~OPTIONS.chomp
                  Options:
                    --help, -h      # Print this help
                    --version       # Print version
                OPTIONS
              end

              def self.normalized_commands
                case commands
                when Hash
                  commands.to_a
                else
                  commands
                end
              end
            end
          end
        end
      end
    end
  end
end
