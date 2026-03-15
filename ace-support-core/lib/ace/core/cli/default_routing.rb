# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Core
    module CLI
      # Compatibility helper for registries exposing a `start` method.
      module DefaultRouting
        def start(args)
          normalized_args = args.empty? ? ["--help"] : args
          Ace::Support::Cli::Runner.new(self).call(args: normalized_args)
        end
      end
    end
  end
end
