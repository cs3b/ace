# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Atoms
      class OutcomePlannerTest < AceCoworkerTestCase
        def snapshot(state:, steps:)
          Ace::Coworker::Models::AssignmentSnapshot.new(
            id: "abc123", name: "work", state: state, progress: "0/2 done",
            steps: steps.map { |s| {number: s[0], name: s[1], status: s[2]} })
        end

        def test_complete_snapshot_derives_success_with_last_step
          snap = snapshot(state: "completed", steps: [["010", "impl", "done"], ["020", "verify", "done"]])
          outcome = OutcomePlanner.plan(snap)

          assert outcome.success?
          assert_equal "020", outcome.step.number
          assert_equal "verify", outcome.step.name
          assert_empty outcome.unfinished_steps
        end

        def test_incomplete_snapshot_without_result_flag_derives_error
          snap = snapshot(state: "running", steps: [["010", "impl", "done"], ["020", "verify", "failed"]])
          outcome = OutcomePlanner.plan(snap, message: "verifier crashed")

          refute outcome.success?
          assert_equal "verifier crashed", outcome.cause
          assert_equal "020", outcome.step.number
          assert_includes outcome.unfinished_steps.join("; "), "020 verify (failed)"
        end

        def test_explicit_success_on_incomplete_is_refused
          snap = snapshot(state: "running", steps: [["010", "impl", "pending"]])
          error = assert_raises(Coworker::Error) do
            OutcomePlanner.plan(snap, explicit_result: "success")
          end
          assert_includes error.message, "refusing to record work done"
          assert_includes error.message, "1 pending step"
        end

        def test_error_without_cause_is_refused
          snap = snapshot(state: "running", steps: [["010", "impl", "failed"]])
          error = assert_raises(Coworker::Error) do
            OutcomePlanner.plan(snap)
          end
          assert_includes error.message, "needs a cause"
        end

        def test_step_evidence_used_as_cause_when_no_message
          snap = snapshot(state: "running", steps: [["010", "impl", "failed"]])
          outcome = OutcomePlanner.plan(snap, step_evidence: "verifier exited 1\nstack...")
          assert_equal "verifier exited 1\nstack...", outcome.cause
        end

        def test_explicit_step_override_respected
          snap = snapshot(state: "completed", steps: [["010", "impl", "done"], ["020", "verify", "done"]])
          outcome = OutcomePlanner.plan(snap, step_override: "010")
          assert_equal "010", outcome.step.number
          assert_equal "impl", outcome.step.name
        end

        def test_error_step_defaults_to_active_then_pending
          snap = snapshot(state: "running", steps: [["010", "a", "done"], ["020", "b", "active"], ["030", "c", "pending"]])
          outcome = OutcomePlanner.plan(snap, message: "x")
          assert_equal "020", outcome.step.number

          snap2 = snapshot(state: "running", steps: [["010", "a", "done"], ["030", "c", "pending"]])
          outcome2 = OutcomePlanner.plan(snap2, message: "x")
          assert_equal "030", outcome2.step.number
        end
      end
    end
  end
end
