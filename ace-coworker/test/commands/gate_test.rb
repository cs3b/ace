# frozen_string_literal: true

require_relative "../test_helper"
require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        class GateTest < AceCoworkerTestCase
          def test_ready_candidate_prints_ready_without_reasons
            out, = capture_io do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "1a2b3c4",
                            review_verdict: "accept", tests: ["executed", "passed"],
                            dep: ["8xg.t.sbz.4.2=integrated"])
            end
            assert_includes out, "Coworker integration gate"
            assert_includes out, "verdict:        ready"
            refute_includes out, "blocked:"
          end

          def test_stale_review_after_candidate_change_prints_blocked_reason
            out, = capture_io do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "0d0e0f0",
                            review_verdict: "accept", tests: ["executed", "passed"],
                            dep: ["8xg.t.sbz.4.2=integrated"])
            end
            assert_includes out, "verdict:        blocked"
            assert_includes out, "stale review: candidate 1a2b3c4 is not the reviewed head 0d0e0f0"
          end

          def test_unsatisfied_dependency_prints_blocked_reason
            out, = capture_io do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "1a2b3c4",
                            review_verdict: "accept", tests: ["executed", "passed"],
                            dep: ["8xg.t.sbz.4.2=missing"])
            end
            assert_includes out, "verdict:        blocked"
            assert_includes out, "dependencies not integrated: 8xg.t.sbz.4.2"
          end

          def test_missing_test_evidence_blocks
            out, = capture_io do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "1a2b3c4",
                            review_verdict: "accept", tests: [], dep: [])
            end
            assert_includes out, "verdict:        blocked"
            assert_includes out, "tests not executed"
            assert_includes out, "tests not passing"
          end

          def test_json_output_shape
            out, = capture_io do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "0d0e0f0",
                            review_verdict: "escalate", tests: ["executed"],
                            dep: ["dep-a=missing"], format: "json")
            end
            payload = JSON.parse(out)
            assert_equal "blocked", payload["verdict"]
            assert_includes payload["reasons"], "review verdict is 'escalate', not accept"
            assert_includes payload["failed_checks"], "review"
            assert_includes payload["failed_checks"], "dependencies"
          end

          def test_comma_separated_tests_and_dep_flags
            out, = capture_io do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "1a2b3c4",
                            review_verdict: "accept", tests: ["executed,passed"],
                            dep: ["dep-a=integrated", "dep-b=integrated"])
            end
            assert_includes out, "verdict:        ready"
          end

          def test_invalid_dep_pair_fails_with_actionable_error
            error = assert_raises(Ace::Support::Cli::Error) do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "1a2b3c4",
                            review_verdict: "accept", tests: [], dep: ["=integrated"])
            end
            assert_includes error.message, "invalid --dep"
          end

          def test_dep_without_state_fails_with_actionable_error
            error = assert_raises(Ace::Support::Cli::Error) do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "1a2b3c4",
                            review_verdict: "accept", tests: [], dep: ["foo"])
            end
            assert_equal "invalid --dep 'foo' (expected name=integrated|missing)", error.message
          end

          def test_duplicate_dep_name_fails_with_actionable_error
            error = assert_raises(Ace::Support::Cli::Error) do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "1a2b3c4",
                            review_verdict: "accept", tests: [],
                            dep: ["dep-a=integrated", "dep-a=missing"])
            end
            assert_equal "duplicate --dep 'dep-a'", error.message
          end

          def test_unknown_tests_token_fails_with_actionable_error
            error = assert_raises(Ace::Support::Cli::Error) do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "1a2b3c4",
                            review_verdict: "accept", tests: ["executed", "green"], dep: [])
            end
            assert_equal "invalid --tests 'green' (expected: executed, passed)", error.message
          end

          def test_quiet_suppresses_output
            out, = capture_io do
              Gate.new.call(candidate_head: "1a2b3c4", review_head: "1a2b3c4",
                            review_verdict: "accept", tests: ["executed", "passed"],
                            dep: ["8xg.t.sbz.4.2=integrated"], quiet: true)
            end
            assert_empty out
          end
        end
      end
    end
  end
end
