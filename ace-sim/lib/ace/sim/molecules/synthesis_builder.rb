# frozen_string_literal: true

module Ace
  module Sim
    module Molecules
      class SynthesisBuilder
        def build(session:, resolved_source:, chains:)
          {
            "run_id" => session.run_id,
            "preset" => session.preset,
            "source" => resolved_source,
            "providers" => session.providers,
            "repeat" => session.repeat,
            "dry_run" => session.dry_run?,
            "writeback" => session.writeback?,
            "chains" => chains,
            "status" => overall_status(chains)
          }
        end

        private

        def overall_status(chains)
          return "failed" if chains.empty?
          return "failed" if chains.all? { |chain| chain["status"] == "failed" }
          return "partial" if chains.any? { |chain| chain["status"] == "failed" }

          "ok"
        end
      end
    end
  end
end
