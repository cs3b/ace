# frozen_string_literal: true

require "json"
require_relative "../../providers/lab"

module Ace
  module Hitl
    module CLI
      module Commands
        # Shared plumbing for the lifecycle commands (spec 8wm.t.y21 §8,
        # scoped by 8wq.t.34i): every lifecycle operation reaches the
        # store through the AUTHENTICATED BOUNDARY CLIENT — direct
        # shared-store access is not a CLI option — and machine outputs
        # are one JSON line, byte-compatible with the migrated CLI
        # contract.
        module LifecycleCommand
          STDIN_READER = ->(limit) { $stdin.read(limit) }.freeze

          def lifecycle_client
            Providers::Lab.boundary_client
          end

          def emit(result)
            puts JSON.generate(result)
          end

          def raise_lifecycle_error(message)
            raise Ace::Support::Cli::Error.new(message)
          end
        end
      end
    end
  end
end
