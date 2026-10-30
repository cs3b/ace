# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # `ace-hitl history` (task 8xs.t.pu0.c): the citable decision
        # history for the NEXT Second Captain suggestion — answered,
        # NON-SECRET question cases of THIS project scope, each row with
        # its checkable references (case id, suggestion, decision,
        # lesson). Secret/OTP cases never reach the model; no wider
        # lab-wide sharing. No embedding store or decision index: HITL
        # stays the single source.
        class History < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "List the citable decision history (answered, non-secret cases of this scope)"

          option :scope, type: :string, default: "current", desc: "current or all linked worktrees"
          option :limit, type: :integer, default: 50, desc: "Maximum rows"
          option :format, default: "json", desc: "Output format (json, table)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(scope: "current", limit: 50, format: "json", **)
            rows = Ace::Hitl::Organisms::HitlManager.new
              .decision_history(scope: scope, limit: limit)
            puts JSON.pretty_generate({"history" => rows, "count" => rows.size})
          rescue ArgumentError => e
            raise Ace::Support::Cli::Error.new(e.message)
          end
        end
      end
    end
  end
end
