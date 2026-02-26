# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Builds deterministic synthesis payloads from stage artifacts.
      class SimulationSynthesisBuilder
        DEFAULT_IDEA_QUESTIONS = [
          "What problem statement should be clarified to make drafting deterministic?"
        ].freeze
        DEFAULT_IDEA_REFINEMENTS = [
          "Add explicit scope boundaries and non-goals to the idea description."
        ].freeze

        def build(run_id:, source:, stage_outputs:, stage_payloads:, partial: false, failed_stage: nil, error: nil)
          questions = collect_list(stage_payloads, "questions")
          refinements = collect_list(stage_payloads, "refinements")
          unresolved_gaps = collect_list(stage_payloads, "unresolved_gaps")

          if source[:type] == "idea"
            questions = DEFAULT_IDEA_QUESTIONS if questions.empty?
            refinements = DEFAULT_IDEA_REFINEMENTS if refinements.empty?
          end

          if partial && failed_stage
            unresolved_gaps << "Stage '#{failed_stage}' failed: #{error}"
          end

          {
            run_id: run_id,
            status: partial ? "partial" : "ok",
            stage_count: stage_outputs.length,
            stages: stage_outputs,
            questions: questions.uniq,
            refinements: refinements.uniq,
            unresolved_gaps: unresolved_gaps.uniq
          }
        end

        private

        def collect_list(stage_payloads, key)
          stage_payloads.values.flat_map do |payload|
            value = payload[key.to_sym] || payload[key.to_s]
            Array(value).map(&:to_s).map(&:strip).reject(&:empty?)
          end
        end
      end
    end
  end
end
