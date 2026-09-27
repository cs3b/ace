# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"

module Ace
  module Hitl
    module CLI
      module Commands
        # The ONLY way to abandon a relay request: explicit, audited
        # cancellation recorded in the public lifecycle projection
        # (spec 8wm.t.y21 §3).
        class Cancel < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand

          desc "Cancel one HITL relay request with an audited reason"

          argument :id, required: true, desc: "HITL relay request id"

          option :reason, type: :string, desc: "Audited reason recorded in the public lifecycle record"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(id:, **options)
            emit(lifecycle_store.cancel(id, reason: options[:reason] || ""))
          rescue Lifecycle::Error => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
