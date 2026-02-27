# frozen_string_literal: true

module Ace
  module Sim
    module Molecules
      class SynthesisBuilder
        def build(session:, resolved_source:, chains:, final_stage: nil)
          {
            "run_id" => session.run_id,
            "preset" => session.preset,
            "source" => resolved_source,
            "providers" => session.providers,
            "repeat" => session.repeat,
            "dry_run" => session.dry_run?,
            "writeback" => session.writeback,
            "synthesis_workflow" => session.synthesis_workflow,
            "synthesis_provider" => session.synthesis_provider,
            "chains" => chains,
            "final_stage" => final_stage,
            "status" => overall_status(chains, final_stage: final_stage)
          }
        end

        def chain_status(step_results)
          step_results.any? { |step| step["status"] == "failed" } ? "failed" : "ok"
        end

        private

        def overall_status(chains, final_stage: nil)
          return "failed" if final_stage && final_stage["status"] == "failed"
          return "failed" if chains.empty?
          return "failed" if chains.all? { |chain| chain["status"] == "failed" }
          return "partial" if chains.any? { |chain| chain["status"] == "failed" }

          "ok"
        end
      end
    end
  end
end
