# frozen_string_literal: true
require "json"
require_relative "../../molecules/event_observation"
module Ace
  module Overseer
    module CLI
      module Commands
        class Observe < Ace::Support::Cli::Command
          desc "Read incoming semantic revisions requiring owner reconciliation; no effects"
          option :owner, type: :string, required: true, desc: "Configured HITL recipient for this observer"
          option :scope, type: :string, default: "current", desc: "current or all linked worktrees"
          option :limit, type: :integer, default: 500, desc: "Maximum canonical events"
          def call(owner:, scope: "current", limit: 500, **)
            raise Ace::Support::Cli::Error, "invalid scope" unless %w[current all].include?(scope)
            puts JSON.generate(Molecules::EventObservation.new.call(owner: owner, scope: scope, limit: limit))
          rescue ArgumentError, Ace::Hitl::Molecules::HitlAddressResolver::UnknownRecipientError,
            Ace::Hitl::Molecules::HitlAddressResolver::InvalidAddressError => e
            raise Ace::Support::Cli::Error, e.message
          end
        end
      end
    end
  end
end
