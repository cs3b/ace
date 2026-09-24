# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # Shared plumbing for the operator/broker lifecycle commands
        # (spec 8wm.t.y21 §8): the store is built through the provider=lab
        # seam and machine outputs are one JSON line, byte-compatible
        # with the migrated CLI contract.
        module LifecycleCommand
          STDIN_READER = ->(limit) { $stdin.read(limit) }.freeze

          def lifecycle_store(store: nil)
            Providers::Lab.lifecycle_store(store: store)
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
