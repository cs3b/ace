# frozen_string_literal: true

require "dry/cli"

module Ace
  module Core
    module CLI
      module DryCli
        # Shared help routing for registry-level help across all CLI gems.
        #
        # Extracts the common pattern of detecting help flags and rendering
        # the appropriate format (concise vs full) from individual start() methods.
        #
        # Two-tier help:
        # - `-h` renders concise, scannable output with footer
        # - `--help` / `help` renders full reference with ALL-CAPS sections and examples
        #
        # @example Usage in custom start() method
        #   def self.start(args)
        #     return 0 if HelpRouter.handle(args, self)
        #     # ... rest of custom routing
        #   end
        #
        # @since 0.24.0
        module HelpRouter
          # Flags that trigger registry-level help
          HELP_FLAGS = %w[help --help -h].freeze

          # Flags that trigger concise output (subset of HELP_FLAGS)
          CONCISE_FLAGS = %w[-h].freeze

          # Handle registry-level help if the first argument is a help flag.
          #
          # @param args [Array<String>] command-line arguments
          # @param registry [Module] the CLI registry module (extends Dry::CLI::Registry)
          # @return [Boolean] true if help was handled, false otherwise
          def self.handle(args, registry)
            return false unless args.first && HELP_FLAGS.include?(args.first)

            result = registry.get([])

            if CONCISE_FLAGS.include?(args.first)
              puts Dry::CLI::Usage.call_concise(result, registry: registry)
            else
              puts Dry::CLI::Usage.call(result, registry: registry)
            end

            true
          end
        end
      end
    end
  end
end
