# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # `ace-hitl suggest CASE_ID --by AUTHOR --text ... --rationale ...`
        # (task 8xs.t.pu0.b): the Second Captain's ADVISORY proposal —
        # one marked section in the exact case, with author, rationale
        # and grounds. Never an Answer, never a human approval, never a
        # gate release. Identical repeats are no-ops; a second different
        # proposal, a secret case, or a case the human already answered
        # are explicit refusals without side effects.
        class Suggest < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Write the Second Captain's marked advisory suggestion into one exact case"

          example ['ace-hitl suggest 8xhkep --by second-captain --text "Proceed" ',
                   '         --rationale "tests green, review accept at same head" --refs pr:398']

          argument :case_id, required: true, desc: "Exact HITL case id"

          option :by, type: :string, required: true, desc: "Advisory author identity"
          option :text, type: :string, required: true, desc: "Proposed answer text"
          option :rationale, type: :string, required: true, desc: "Why this proposal is defensible"
          option :refs, type: :string, desc: "Comma-separated grounds references"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(case_id:, by:, text:, rationale:, refs: nil, **)
            state = Ace::Hitl::Organisms::HitlManager.new
              .add_suggestion(case_id, author: by, text: text, rationale: rationale,
                refs: refs.to_s.split(",").map(&:strip).reject(&:empty?))
            puts JSON.generate({"case" => case_id, "suggestion" => state.to_s})
          rescue Ace::Hitl::Organisms::HitlManager::UnknownCaseError,
            Ace::Hitl::Organisms::HitlManager::AmbiguousReferenceError,
            Ace::Hitl::Organisms::HitlManager::SuggestionRefusedError,
            Ace::Hitl::Organisms::HitlManager::TerminalCaseError => e
            raise Ace::Support::Cli::Error.new("suggestion refused: #{e.message}")
          end
        end
      end
    end
  end
end
