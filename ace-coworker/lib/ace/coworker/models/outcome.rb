# frozen_string_literal: true

module Ace
  module Coworker
    module Models
      # Immutable derived outcome of one reporting run.
      class Outcome
        StepRef = Struct.new(:number, :name, keyword_init: true)

        attr_reader :result, :verdict, :cause, :step, :unfinished_steps, :evidence, :snapshot

        def initialize(result:, verdict:, cause: nil, step: nil, unfinished_steps: [], evidence: {}, snapshot: nil)
          @result = result.freeze
          @verdict = verdict
          @cause = cause.freeze
          @step = step
          @unfinished_steps = unfinished_steps.map(&:freeze).freeze
          @evidence = evidence.freeze
          @snapshot = snapshot
        end

        def success?
          result == "success"
        end

        def to_h
          {
            "result" => result,
            "verdict" => verdict.to_s,
            "cause" => cause,
            "step" => step && {"number" => step.number, "name" => step.name},
            "unfinished_steps" => unfinished_steps,
            "evidence" => evidence
          }
        end
      end
    end
  end
end
