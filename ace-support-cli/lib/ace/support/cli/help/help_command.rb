# frozen_string_literal: true

module Ace
  module Support
    module Cli
      module Help
        module HelpCommand
          def self.build(program_name:, version:, commands:, examples: nil)
            Class.new(Command) do
              @program_name = program_name
              @version = version
              @commands = commands
              @examples = examples

              class << self
                attr_reader :program_name, :version, :commands, :examples
              end

              desc "Show top-level help"
              argument :args, type: :array, required: false

              def call(**_params)
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
                  "#{("  #{name}").ljust(16)}# #{description}"
                end
                "Commands:\n#{lines.join("\n")}"
              end

              def self.render_examples
                return nil if examples.nil? || examples.empty?

                "Examples:\n#{examples.map { |item| "  #{item}" }.join("\n")}"
              end

              def self.render_options
                <<~OPTIONS.chomp
                  Options:
                    --help, -h      # Print this help
                    --version       # Print version
                OPTIONS
              end

              def self.normalized_commands
                commands.is_a?(Hash) ? commands.to_a : commands
              end
            end
          end
        end
      end
    end
  end
end
