# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # `ace-hitl lesson CASE_ID --by AGENT --relation accepted|rejected|
        # modified --takeaway ...` (task 8xs.t.pu0.c): the advisory
        # agent's takeaway from comparing the accepted human decision
        # with its own suggestion — one `## Lesson` section at the same
        # case, referencing the exact question/suggestion/decision
        # revisions. Never a new decision; never changes the answer's
        # author; identical repeats are no-ops.
        class Lesson < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Write the lesson drawn from the human decision vs the suggestion"

          example ['ace-hitl lesson 8xhkep --by second-captain --relation rejected ',
                   '         --takeaway "Captain prioritized rollout safety over speed"']

          argument :case_id, required: true, desc: "Exact HITL case id"

          option :by, type: :string, required: true, desc: "Advisory agent author identity"
          option :relation, type: :string, required: true,
            desc: "accepted | rejected | modified (decision vs suggestion)"
          option :takeaway, type: :string, required: true, desc: "What the next suggestion should learn"
          option :refs, type: :string, desc: "Comma-separated extra references"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(case_id:, by:, relation:, takeaway:, refs: nil, **)
            state = Ace::Hitl::Organisms::HitlManager.new
              .add_lesson(case_id, by: by, relation: relation, takeaway: takeaway,
                refs: refs.to_s.split(",").map(&:strip).reject(&:empty?))
            puts JSON.generate({"case" => case_id, "lesson" => state.to_s})
          rescue Ace::Hitl::Organisms::HitlManager::UnknownCaseError,
            Ace::Hitl::Organisms::HitlManager::AmbiguousReferenceError,
            Ace::Hitl::Organisms::HitlManager::LessonRefusedError => e
            raise Ace::Support::Cli::Error.new("lesson refused: #{e.message}")
          end
        end
      end
    end
  end
end
