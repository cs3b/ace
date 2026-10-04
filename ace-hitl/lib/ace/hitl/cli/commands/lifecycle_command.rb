# frozen_string_literal: true

require "json"

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
          def lifecycle_client
            Providers::Lab.boundary_client
          end

          def overseer
            channel_root = ENV.fetch("ACE_HITL_OVERSEER_CHANNEL_ROOT", "/lab/state/overseer-channel")
            Lifecycle::Overseer.new(outbox_dir: File.join(channel_root, "outbox"))
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
