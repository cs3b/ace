# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Atoms
      class RoundRuleTest < AceCoworkerTestCase
        def clean
          {"type" => "full", "status" => "completed", "confirmed" => [], "resolved" => []}
        end

        def with_high(id: "f-1")
          {"type" => "full", "status" => "completed",
           "confirmed" => [{"id" => id, "severity" => "High"}], "resolved" => []}
        end

        def resolving(id: "f-1")
          {"type" => "full", "status" => "completed", "confirmed" => [], "resolved" => [id]}
        end

        def aborted
          {"type" => "full", "status" => "aborted", "confirmed" => [], "resolved" => []}
        end

        def delta(confirmed: [])
          {"type" => "delta", "status" => "completed", "confirmed" => confirmed, "resolved" => []}
        end

        def test_clean_clean_clean_accepts_at_round_three
          result = RoundRule.evaluate([clean, clean, clean])
          assert_equal :accept, result[:verdict]
          assert_equal 3, result[:full_rounds]
          assert_equal 3, result[:completed_full_rounds]
          assert_equal 3, result[:consecutive_clean]
          assert_empty result[:unresolved_high_critical]
        end

        def test_error_clean_clean_accepts_at_round_three_when_high_resolved
          result = RoundRule.evaluate([with_high, resolving, clean])
          assert_equal :accept, result[:verdict]
          assert_equal 3, result[:completed_full_rounds]
          assert_equal 2, result[:consecutive_clean]
          assert_empty result[:unresolved_high_critical]
        end

        def test_unresolved_high_blocks_accept_even_after_three_rounds
          result = RoundRule.evaluate([with_high, clean, clean])
          assert_equal :continue, result[:verdict]
          assert_equal ["f-1"], result[:unresolved_high_critical]
          assert_equal 2, result[:consecutive_clean]
        end

        def test_two_clean_rounds_continue
          result = RoundRule.evaluate([clean, clean])
          assert_equal :continue, result[:verdict]
        end

        def test_rule_satisfied_at_round_ten_succeeds
          rounds = Array.new(8) { |i| i.zero? ? with_high(id: "f-x") : clean }
          # round 1 confirmed High, resolved in round 8; rounds 9-10 clean
          rounds << resolving(id: "f-x")
          rounds << clean
          result = RoundRule.evaluate(rounds)
          assert_equal 10, result[:full_rounds]
          assert_equal :accept, result[:verdict]
        end

        def test_no_acceptance_after_round_ten_escalates_as_explicit_outcome
          rounds = Array.new(10) { with_high(id: "never-fixed") }
          result = RoundRule.evaluate(rounds)
          assert_equal :escalate, result[:verdict]
          assert_equal 10, result[:full_rounds]
          assert_equal ["never-fixed"], result[:unresolved_high_critical]
        end

        def test_aborted_round_is_not_clean_and_breaks_the_streak
          result = RoundRule.evaluate([clean, clean, aborted, clean])
          assert_equal :continue, result[:verdict]
          assert_equal 4, result[:full_rounds]
          assert_equal 3, result[:completed_full_rounds]
          assert_equal 1, result[:consecutive_clean]
        end

        def test_aborted_rounds_still_count_toward_the_ten_limit
          rounds = Array.new(9) { clean } << aborted
          result = RoundRule.evaluate(rounds)
          assert_equal :escalate, result[:verdict]
        end

        def test_high_critical_finding_resets_the_streak
          result = RoundRule.evaluate([clean, clean, with_high, resolving, clean])
          # the High round resets the streak; rounds 4-5 rebuild it, and
          # with the finding resolved the rule is satisfied again
          assert_equal :accept, result[:verdict]
          assert_equal 2, result[:consecutive_clean]

          still_short = RoundRule.evaluate([clean, clean, with_high, resolving])
          assert_equal :continue, still_short[:verdict]
          assert_equal 1, still_short[:consecutive_clean]

          reset = RoundRule.evaluate([clean, clean, with_high, clean])
          assert_equal 1, reset[:consecutive_clean]
          assert_equal :continue, reset[:verdict]
        end

        def test_delta_round_never_advances_the_counter_or_breaks_the_streak
          result = RoundRule.evaluate([clean, clean, delta, delta])
          assert_equal :continue, result[:verdict]
          assert_equal 2, result[:full_rounds]
          assert_equal 2, result[:completed_full_rounds]
          assert_equal 2, result[:consecutive_clean]

          accept = RoundRule.evaluate([clean, clean, delta, clean])
          assert_equal :accept, accept[:verdict]
        end

        def test_unresolved_high_confirmed_in_a_delta_round_blocks_accept
          result = RoundRule.evaluate([clean, clean, delta(confirmed: [{"id" => "d-1", "severity" => "Critical"}]), clean])
          assert_equal :continue, result[:verdict]
          assert_equal ["d-1"], result[:unresolved_high_critical]
        end

        def test_severity_matching_is_case_insensitive_and_limited_to_high_critical
          record = {"type" => "full", "status" => "completed",
                    "confirmed" => [{"id" => "a", "severity" => "CRITICAL"},
                                    {"id" => "b", "severity" => "high"},
                                    {"id" => "c", "severity" => "Medium"}],
                    "resolved" => []}
          result = RoundRule.evaluate([record, resolving(id: "a"), resolving(id: "b"), clean])
          assert_equal :accept, result[:verdict]
          assert_empty result[:unresolved_high_critical]
        end

        def test_empty_history_continues
          result = RoundRule.evaluate([])
          assert_equal :continue, result[:verdict]
          assert_equal 0, result[:full_rounds]
        end
      end
    end
  end
end
