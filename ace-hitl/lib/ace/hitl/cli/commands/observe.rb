# frozen_string_literal: true
require "ace/support/cli"
require_relative "../../molecules/event_observation"
module Ace
  module Hitl
    module CLI
      module Commands
        class Observe < Ace::Support::Cli::Command
          desc "Read bounded semantic event revisions without private message text"
          option :scope, type: :string, default: "current", desc: "current or all linked worktrees"
          option :owner, type: :string, desc: "Configured recipient owning incoming events"
          option :limit, type: :integer, default: 500, desc: "Maximum event count (1..2000)"
          def call(**options)
            scope = options[:scope] || "current"
            raise Ace::Support::Cli::Error, "invalid scope" unless %w[current all].include?(scope)
            puts JSON.generate(Molecules::EventObservation.new.call(scope: scope, limit: options[:limit] || 500, owner: options[:owner]))
          rescue ArgumentError => e
            raise Ace::Support::Cli::Error, e.message
          end
        end
      end
    end
  end
end
