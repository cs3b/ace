# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Assign
    class AttemptReconcilerTest < AceAssignTestCase
      def build_attempt(events: [])
        binding = Models::AttemptBinding.new(
          attempt_id: "atrec01",
          assignment_id: "8wrecc",
          scope: "010",
          project_id: "ace",
          actor: "mc",
          role: "coordinator",
          runtime: "local:test",
          base_head: "deadbeef",
          task_id: nil,
          created_at: Time.now.utc
        )
        Models::Attempt.new(binding: binding, state: "running", events: events)
      end

      def build_reconciler
        Molecules::AttemptReconciler.new
      end

      def test_running_with_only_intent_classifies_stopped
        intent = Models::EvidenceEvent.build(type: "intent", attempt_id: "atrec01", payload: {"scope" => "010"})
        reconciler = build_reconciler

        assert_equal :stopped, reconciler.classify(build_attempt(events: [intent]))
      end

      def test_running_with_live_recorded_process_stays_running
        child = Process.spawn("sleep", "10")
        begin
          process_start = Models::EvidenceEvent.build(
            type: "process_start",
            attempt_id: "atrec01",
            payload: {"runtime" => "local:test", "pid" => child}
          )
          reconciler = build_reconciler

          assert_equal :live, reconciler.classify(build_attempt(events: [process_start]))
        ensure
          Process.kill("TERM", child)
          Process.wait(child)
        end
      end

      def test_running_with_dead_recorded_process_classifies_uncertain
        child = Process.spawn("true")
        Process.wait(child)
        process_start = Models::EvidenceEvent.build(
          type: "process_start",
          attempt_id: "atrec01",
          payload: {"runtime" => "local:test", "pid" => child}
        )
        reconciler = build_reconciler

        assert_equal :uncertain, reconciler.classify(build_attempt(events: [process_start]))
      end

      def test_recorded_runtime_exposes_execution_boundary
        process_start = Models::EvidenceEvent.build(
          type: "process_start",
          attempt_id: "atrec01",
          payload: {"runtime" => "herdr:session-7", "pid" => 1}
        )
        reconciler = build_reconciler

        assert_equal "herdr:session-7", reconciler.recorded_runtime(build_attempt(events: [process_start]))
        assert_nil reconciler.recorded_runtime(build_attempt(events: []))
      end

      def test_missing_pid_never_counts_as_live
        process_start = Models::EvidenceEvent.build(
          type: "process_start",
          attempt_id: "atrec01",
          payload: {"runtime" => "local:test"}
        )
        reconciler = build_reconciler

        refute reconciler.process_live?(build_attempt(events: [process_start]))
      end
    end
  end
end
