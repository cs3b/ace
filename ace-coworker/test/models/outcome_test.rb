# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Models
      class OutcomeTest < AceCoworkerTestCase
        def test_to_h_shape
          outcome = Outcome.new(result: "error", verdict: :incomplete,
            cause: "boom", step: Outcome::StepRef.new(number: "020", name: "build"),
            unfinished_steps: ["020 build (failed)"],
            evidence: {"reports_dir" => ".ace-local/assign/abc123/reports"})

          refute outcome.success?
          payload = outcome.to_h
          assert_equal "error", payload["result"]
          assert_equal "boom", payload["cause"]
          assert_equal "020", payload["step"]["number"]
          assert_equal ["020 build (failed)"], payload["unfinished_steps"]
        end
      end
    end
  end
end
