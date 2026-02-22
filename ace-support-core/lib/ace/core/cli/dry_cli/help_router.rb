# frozen_string_literal: true

require "dry/cli"

module Ace
  module Core
    module CLI
      module DryCli
        # Temporary compatibility shim for registries that still invoke
        # `HelpRouter.handle(args, registry)` directly in custom start methods.
        module HelpRouter
          HELP_FLAGS = %w[help --help -h].freeze
          CONCISE_FLAGS = %w[-h].freeze

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
