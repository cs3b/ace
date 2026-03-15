# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Core
    module CLI
      module HelpRouter
        HELP_FLAGS = %w[help --help -h].freeze
        CONCISE_FLAGS = %w[-h].freeze

        def self.handle(args, registry)
          return false unless args.first && HELP_FLAGS.include?(args.first)

          usage = Ace::Support::Cli::Usage.new(registry, program_name: resolve_program_name(registry))
          output = CONCISE_FLAGS.include?(args.first) ? usage.render_concise : usage.render
          puts output
          true
        end

        def self.resolve_program_name(registry)
          if registry.respond_to?(:const_defined?) && registry.const_defined?(:PROGRAM_NAME)
            registry.const_get(:PROGRAM_NAME)
          else
            $PROGRAM_NAME.split("/").last
          end
        end
      end
    end
  end
end
