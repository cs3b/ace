# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # `ace-hitl apply CASE --ref OWNER_REF` (task 8xs.t.pu0.6):
        # record that the answer's effect was applied, WITH the
        # reference to the effect owner (task/assignment/PR) the
        # consumer verified first. Exactly-once belongs to the effect:
        # after a crash the consumer re-checks the effect at its owner
        # before calling this; an undecidable outcome is an explicit
        # reconciliation block, never a blind retry. Close happens only
        # after this proof exists.
        class Apply < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Record the answer's applied effect with its owner reference"

          example ['ace-hitl apply 8xhkep --ref pr:398']

          argument :case_id, required: true, desc: "Exact HITL case id"

          option :ref, type: :string, required: true,
            desc: "Effect owner reference (task/assignment/PR) verified by the consumer"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(case_id:, ref:, **)
            state = Ace::Hitl::Organisms::HitlManager.new.apply_answer_effect(case_id, ref)
            puts JSON.generate({"case" => case_id, "state" => state.to_s})
          rescue Ace::Hitl::Organisms::HitlManager::UnknownCaseError,
            Ace::Hitl::Organisms::HitlManager::AmbiguousReferenceError,
            Ace::Hitl::Organisms::HitlManager::NotAnswerableError,
            Ace::Hitl::Organisms::HitlManager::LifecycleTransitionError => e
            raise Ace::Support::Cli::Error.new("not applied: #{e.message}")
          end
        end
      end
    end
  end
end
