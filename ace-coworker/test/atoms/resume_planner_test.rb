# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Atoms
      class ResumePlannerTest < AceCoworkerTestCase
        def snapshot(state:, steps:)
          Ace::Coworker::Models::AssignmentSnapshot.new(
            id: "abc123", name: "work", state: state, progress: "1/3 done",
            steps: steps.map { |s| {number: s[0], name: s[1], status: s[2]} })
        end

        def test_incomplete_continues_with_preserved_and_remaining
          snap = snapshot(state: "running", steps: [
            ["010", "impl", "done"], ["020", "verify", "active"], ["030", "docs", "pending"]])
          plan = ResumePlanner.plan(snapshot: snap, git_state: {"branch" => "main"})

          assert plan.continue?
          assert_equal ["010 impl"], plan.preserved_steps
          assert_equal ["020 verify (active)", "030 docs (pending)"], plan.remaining_steps
          assert_equal "020", plan.in_flight["number"]
        end

        def test_failed_step_is_in_flight_with_cause
          snap = snapshot(state: "running", steps: [
            ["010", "impl", "done"], ["020", "verify", "failed"]])
          plan = ResumePlanner.plan(snapshot: snap, step_cause: "verifier crashed")

          assert_equal "020", plan.in_flight["number"]
          assert_equal "failed", plan.in_flight["status"]
          assert_equal "verifier crashed", plan.in_flight_cause
          assert_nil plan.step_report_path
        end

        def test_complete_without_report_state_reports
          snap = snapshot(state: "completed", steps: [["010", "impl", "done"]])
          plan = ResumePlanner.plan(snapshot: snap)

          assert_equal :report, plan.disposition
          assert_nil plan.redeliver_event_id
        end

        def test_complete_with_undelivered_event_resends_same_id
          snap = snapshot(state: "completed", steps: [["010", "impl", "done"]])
          plan = ResumePlanner.plan(snapshot: snap,
            report_state: {"result" => "success", "event_id" => "ab12cd", "delivery" => nil})

          assert_equal :report, plan.disposition
          assert_equal "ab12cd", plan.redeliver_event_id
        end

        def test_complete_and_delivered_is_complete
          snap = snapshot(state: "completed", steps: [["010", "impl", "done"]])
          plan = ResumePlanner.plan(snapshot: snap,
            report_state: {"result" => "success", "event_id" => "ab12cd",
              "delivery" => "delivered (event ab12cd)"})

          assert_equal :complete, plan.disposition
        end

        def test_effect_caution_flags_external_effect_steps
          snap = snapshot(state: "running", steps: [
            ["010", "impl", "done"], ["020", "merge-pr", "active"], ["030", "release-check", "pending"]])
          plan = ResumePlanner.plan(snapshot: snap)

          assert_includes plan.effect_caution_steps, "020 merge-pr (active)"
          assert plan.effect_caution_steps.any? { |s| s.include?("release-check") }
        end

        def test_plain_step_names_are_not_flagged
          snap = snapshot(state: "running", steps: [
            ["010", "impl", "done"], ["020", "readme-notes", "active"]])
          plan = ResumePlanner.plan(snapshot: snap)

          assert_empty plan.effect_caution_steps
        end
      end
    end
  end
end
