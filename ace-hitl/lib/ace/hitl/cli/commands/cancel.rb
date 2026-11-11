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

          desc "Cancel a relay request or an explicit local case with an audited reason"

          argument :id, required: true, desc: "HITL relay request id"

          option :case, type: :boolean, desc: "Cancel an exact local case instead of a relay request; requires --reason"

          option :reason, type: :string, desc: "Audited reason recorded in the public lifecycle record"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(id:, **options)
            if options[:case]
              reason = options[:reason].to_s.strip
              raise Ace::Support::Cli::Error.new("local case cancellation requires --reason") if reason.empty?
              state = Organisms::HitlManager.new.cancel_case(id, reason: reason)
              emit({"case" => id, "state" => state.to_s})
            else
              emit(lifecycle_client.cancel(id, reason: options[:reason] || ""))
            end
          rescue Organisms::HitlManager::UnknownCaseError,
            Organisms::HitlManager::AmbiguousReferenceError,
            Organisms::HitlManager::LifecycleTransitionError => e
            raise_lifecycle_error("not cancelled: #{e.message}")
          rescue Lifecycle::Error, Providers::ProviderUnavailableError => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
