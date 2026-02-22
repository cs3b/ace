# frozen_string_literal: true

require "dry/cli"

module Ace
  module Core
    module CLI
      module DryCli
        # Temporary compatibility shim for older CLI registries that still call
        # `extend DefaultRouting`. This no longer performs DWIM command routing.
        module DefaultRouting
          def start(args)
            normalized_args = args.empty? ? ["--help"] : args
            Dry::CLI.new(self).call(arguments: normalized_args)
          end
        end
      end
    end
  end
end
