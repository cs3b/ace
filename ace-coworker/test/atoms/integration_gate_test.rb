# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Atoms
      class IntegrationGateTest < AceCoworkerTestCase
        def ready_input(overrides = {})
          {
            "candidate_head" => "1a2b3c4",
            "review" => {"head" => "1a2b3c4", "verdict" => "accept"},
            "tests" => {"executed" => true, "passed" => true},
            "dependencies" => {"8xg.t.sbz.4.2" => true}
          }.merge(overrides)
        end

        def test_ready_candidate_passes_the_gate
          result = IntegrationGate.evaluate(ready_input)
          assert_equal :ready, result[:verdict]
          assert_empty result[:reasons]
          assert_empty result[:failed_checks]
        end

        def test_stale_review_after_candidate_change_blocks
          result = IntegrationGate.evaluate(
            ready_input("review" => {"head" => "0d0e0f0", "verdict" => "accept"})
          )
          assert_equal :blocked, result[:verdict]
          assert_includes result[:reasons],
                          "stale review: candidate 1a2b3c4 is not the reviewed head 0d0e0f0"
          assert_includes result[:failed_checks], :review
        end

        def test_unsatisfied_dependency_blocks
          result = IntegrationGate.evaluate(
            ready_input("dependencies" => {"8xg.t.sbz.4.1" => true, "8xg.t.sbz.4.2" => false})
          )
          assert_equal :blocked, result[:verdict]
          assert_includes result[:reasons], "dependencies not integrated: 8xg.t.sbz.4.2"
          assert_includes result[:failed_checks], :dependencies
        end

        def test_tests_not_executed_or_not_passing_block
          not_executed = IntegrationGate.evaluate(
            ready_input("tests" => {"executed" => false, "passed" => false})
          )
          assert_equal :blocked, not_executed[:verdict]
          assert_includes not_executed[:reasons],
                          "tests not executed: real executed-test evidence is required before merge"

          failed = IntegrationGate.evaluate(
            ready_input("tests" => {"executed" => true, "passed" => false})
          )
          assert_equal :blocked, failed[:verdict]
          assert_includes failed[:reasons], "tests not passing: executed tests failed or their outcome is unknown"
          assert_includes failed[:failed_checks], :tests
        end

        def test_review_verdict_other_than_accept_blocks
          result = IntegrationGate.evaluate(
            ready_input("review" => {"head" => "1a2b3c4", "verdict" => "continue"})
          )
          assert_equal :blocked, result[:verdict]
          assert_includes result[:reasons], "review verdict is 'continue', not accept"
        end

        def test_unknown_candidate_head_is_blocked_not_guessed
          result = IntegrationGate.evaluate(ready_input("candidate_head" => nil))
          assert_equal :blocked, result[:verdict]
          assert_includes result[:reasons],
                          "candidate head unknown: verify the actual worktree head instead of guessing"
          assert_includes result[:failed_checks], :candidate
        end

        def test_missing_review_head_blocks_as_unverifiable_evidence
          result = IntegrationGate.evaluate(
            ready_input("review" => {"head" => "", "verdict" => "accept"})
          )
          assert_equal :blocked, result[:verdict]
          assert_includes result[:reasons],
                          "review evidence missing: no reviewed head recorded - the verdict covers no verifiable candidate"
        end

        def test_missing_or_malformed_sections_block_instead_of_crashing
          result = IntegrationGate.evaluate("candidate_head" => "1a2b3c4")
          assert_equal :blocked, result[:verdict]
          # an absent dependencies section is empty (nothing unsatisfied),
          # but absent review/tests evidence blocks on the missing facts
          refute_includes result[:failed_checks], :dependencies
          assert_includes result[:reasons], "review evidence missing: no reviewed head recorded - the verdict covers no verifiable candidate"
          assert_includes result[:reasons], "tests not executed: real executed-test evidence is required before merge"
        end

        def test_non_hash_input_blocks_with_actionable_reason
          result = IntegrationGate.evaluate(nil)
          assert_equal :blocked, result[:verdict]
          assert_equal ["gate input must be a Hash with string keys, got NilClass"], result[:reasons]
        end

        def test_symbol_verdict_and_accept_synonym
          result = IntegrationGate.evaluate(
            ready_input("review" => {"head" => "1a2b3c4", "verdict" => "Accept"})
          )
          assert_equal :ready, result[:verdict]
        end

        def test_multiple_failures_report_all_reasons
          result = IntegrationGate.evaluate(
            "candidate_head" => "1a2b3c4",
            "review" => {"head" => "0d0e0f0", "verdict" => "escalate"},
            "tests" => {},
            "dependencies" => {"dep-a" => false, "dep-b" => false}
          )
          assert_equal :blocked, result[:verdict]
          assert_equal 5, result[:reasons].length
          assert_equal %i[dependencies review tests], result[:failed_checks]
        end
      end
    end
  end
end
