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
            "tests" => {"executed" => true, "passed" => true, "head" => "1a2b3c4"},
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
          assert_equal [:input], result[:failed_checks]
        end

        def test_verdict_comparison_is_case_insensitive
          result = IntegrationGate.evaluate(
            ready_input("review" => {"head" => "1a2b3c4", "verdict" => "Accept"})
          )
          assert_equal :ready, result[:verdict]
        end

        def test_head_comparison_tolerates_case_drift_but_not_length_mismatch
          drift = IntegrationGate.evaluate(
            ready_input("candidate_head" => "1A2B3C4", "review" => {"head" => "1a2b3c4", "verdict" => "accept"})
          )
          assert_equal :ready, drift[:verdict]

          truncated = IntegrationGate.evaluate(
            ready_input("review" => {"head" => "1a2b3c", "verdict" => "accept"})
          )
          assert_equal :blocked, truncated[:verdict]
          assert_includes truncated[:reasons],
                          "stale review: candidate 1a2b3c4 is not the reviewed head 1a2b3c"
        end

        def test_multiple_failures_report_all_reasons
          result = IntegrationGate.evaluate(
            "candidate_head" => "1a2b3c4",
            "review" => {"head" => "0d0e0f0", "verdict" => "escalate"},
            "tests" => {},
            "dependencies" => {"dep-a" => false, "dep-b" => false}
          )
          assert_equal :blocked, result[:verdict]
          assert_equal %i[dependencies review tests], result[:failed_checks]
          # 2 review reasons + 3 tests reasons (executed, passed, head binding)
          assert_equal 6, result[:reasons].length
        end

        # --- HEAD binding of evidence (8xs.t.pu0.8) ---------------------

        def test_test_evidence_without_a_head_covers_nothing
          result = IntegrationGate.evaluate(ready_input(
            "tests" => {"executed" => true, "passed" => true}
          ))

          assert_equal :blocked, result[:verdict]
          assert(result[:reasons].any? { |reason| reason.include?("test evidence not bound to a candidate head") })
          assert_includes result[:failed_checks], :tests
        end

        def test_stale_test_evidence_after_a_candidate_change_blocks
          result = IntegrationGate.evaluate(ready_input(
            "tests" => {"executed" => true, "passed" => true, "head" => "0d0e0f0"}
          ))

          assert_equal :blocked, result[:verdict]
          assert(result[:reasons].any? { |reason| reason.include?("stale test evidence") })
          assert_includes result[:failed_checks], :tests
        end

        def test_formal_approval_must_name_the_candidate_head_and_differ_from_the_author
          ok = IntegrationGate.evaluate(ready_input(
            "approval" => {"head" => "1a2b3c4", "by" => "lab-merge-ace"},
            "author" => "lab-overseer"
          ))
          assert_equal :ready, ok[:verdict]

          stale = IntegrationGate.evaluate(ready_input(
            "approval" => {"head" => "0d0e0f0", "by" => "lab-merge-ace"},
            "author" => "lab-overseer"
          ))
          assert_equal :blocked, stale[:verdict]
          assert(stale[:reasons].any? { |reason| reason.include?("stale formal approval") })

          unbound = IntegrationGate.evaluate(ready_input(
            "approval" => {"by" => "lab-merge-ace"}, "author" => "lab-overseer"
          ))
          assert_equal :blocked, unbound[:verdict]
          assert(unbound[:reasons].any? { |reason| reason.include?("formal approval not bound") })

          self_approved = IntegrationGate.evaluate(ready_input(
            "approval" => {"head" => "1a2b3c4", "by" => "lab-overseer"},
            "author" => "lab-overseer"
          ))
          assert_equal :blocked, self_approved[:verdict]
          assert(self_approved[:reasons].any? { |reason| reason.include?("the author's own account") })
          assert_includes self_approved[:failed_checks], :approval
        end

        def test_omitted_formal_approval_keeps_the_previous_semantics
          result = IntegrationGate.evaluate(ready_input)

          assert_equal :ready, result[:verdict]
          refute_includes result[:failed_checks], :approval
        end
      end
    end
  end
end
