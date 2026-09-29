# frozen_string_literal: true

module Ace
  module Support
    module Cli
      module Help
        module HelpCommand
          # Statically declared command class: Spinel bakes the class
          # graph at compile time (Class.new is unsupported in AOT).
          # build returns an instance; Runner dispatches instance
          # targets via #call. Behaviorally equivalent to the previous
          # per-build anonymous class for single-CLI processes.
          class Command < ::Ace::Support::Cli::Command
            desc "Show top-level help"
            argument :args, type: :array, required: false

            attr_reader :program_name, :version, :commands, :examples

            def initialize(program_name:, version:, commands:, examples: nil)
              @program_name = program_name
              @version = version
              @commands = commands
              @examples = examples
            end

            def call(**_params)
              puts render
              0
            end

            def render
              sections = []
              sections << "#{program_name} #{version}".strip
              sections << render_commands
              rendered_examples = render_examples
              sections << rendered_examples if rendered_examples
              sections << render_options
              sections.join("\n\n")
            end

            def render_commands
              lines = normalized_commands.map do |name, description|
                "#{"  #{name}".ljust(16)}# #{description}"
              end
              "Commands:\n#{lines.join("\n")}"
            end

            def render_examples
              return nil if examples.nil? || examples.empty?

              "Examples:\n#{examples.map { |item| "  #{item}" }.join("\n")}"
            end

            def render_options
              <<~OPTIONS.chomp
                Options:
                  --help, -h      # Print this help
                  --version       # Print version
              OPTIONS
            end

            def normalized_commands
              commands.is_a?(Hash) ? commands.to_a : commands
            end
          end

          def self.build(program_name:, version:, commands:, examples: nil)
            Command.new(
              program_name: program_name,
              version: version,
              commands: commands,
              examples: examples
            )
          end
        end
      end
    end
  end
end
