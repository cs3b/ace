# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # `ace-hitl close CASE` (task 8xs.t.pu0.6): terminal close, only
        # after the proven applied effect. A duplicate close is a no-op;
        # a late different answer was already rejected at delivery and a
        # closed case never re-opens — an explicit decision change needs
        # a NEW case.
        class Close < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Close a case terminally after its applied effect"

          example ['ace-hitl close 8xhkep']

          argument :case_id, required: true, desc: "Exact HITL case id"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(case_id:, **)
            state = Ace::Hitl::Organisms::HitlManager.new.close_case(case_id)
            puts JSON.generate({"case" => case_id, "state" => state.to_s})
          rescue Ace::Hitl::Organisms::HitlManager::UnknownCaseError,
            Ace::Hitl::Organisms::HitlManager::AmbiguousReferenceError,
            Ace::Hitl::Organisms::HitlManager::LifecycleTransitionError => e
            raise Ace::Support::Cli::Error.new("not closed: #{e.message}")
          end
        end
      end
    end
  end
end
