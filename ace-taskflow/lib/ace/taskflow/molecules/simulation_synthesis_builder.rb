# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Builds deterministic synthesis payloads from stage artifacts.
      class SimulationSynthesisBuilder
        def build(run_id:, source:, stage_outputs:, stage_payloads:, partial: false, failed_stage: nil, error: nil,
                  list_orders: {})
          questions = collect_list(stage_payloads, "questions", order: list_orders[:questions])
          refinements = collect_list(stage_payloads, "refinements", order: list_orders[:refinements])
          unresolved_gaps = collect_list(stage_payloads, "unresolved_gaps", order: list_orders[:unresolved_gaps])
          artifacts = collect_artifacts(stage_payloads)

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
            unresolved_gaps: unresolved_gaps.uniq,
            artifacts: artifacts
          }
        end

        private

        def collect_list(stage_payloads, key, order: nil)
          stage_entries = stage_payloads.to_a
          stage_entries.reverse! if reverse_order?(order)

          stage_entries.flat_map do |_stage_name, payload|
            value = payload[key.to_sym] || payload[key.to_s]
            Array(value).map(&:to_s).map(&:strip).reject(&:empty?)
          end
        end

        def collect_artifacts(stage_payloads)
          stage_payloads.to_a.each_with_object({}) do |(stage_name, payload), acc|
            artifact = payload[:artifact] || payload["artifact"]
            content = artifact.to_s
            acc[stage_name.to_s] = content unless content.strip.empty?

            review_artifact = payload[:review_artifact] || payload["review_artifact"]
            review_content = review_artifact.to_s
            acc["#{stage_name}_review"] = review_content unless review_content.strip.empty?
          end
        end

        def reverse_order?(order)
          order.to_s.strip.downcase == "reverse"
        end
      end
    end
  end
end
