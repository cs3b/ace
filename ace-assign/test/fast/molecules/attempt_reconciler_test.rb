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
            payload: {"runtime" => "local:test", "pid" => child,
              "process_identity" => Ace::Runtime::Molecules::ProcessIdentity.new.capture(child)}
          )
          reconciler = build_reconciler

          assert_equal :live, reconciler.classify(build_attempt(events: [process_start]))
        ensure
          Process.kill("TERM", child)
          Process.wait(child)
        end
      end

      def test_native_binding_reuse_keeps_live_pid_unknown
        identity = Ace::Runtime::Molecules::ProcessIdentity.new.capture(Process.pid)
        binding = {"runtime" => "herdr", "pane" => "w1:p1", "agent_session" => "old",
          "process_identity" => identity}
        native = Object.new
        live = binding.dup
        native.define_singleton_method(:process_binding) { |**options| live }
        runtime = Object.new
        runtime.define_singleton_method(:resolve) { |_name| native }
        event = Models::EvidenceEvent.build(type: "process_start", attempt_id: "atrec01",
          payload: {"runtime" => "local:test", "process_identity" => identity, "runtime_binding" => binding})
        reconciler = Molecules::AttemptReconciler.new(runtime_resolver: runtime)
        attempt = build_attempt(events: [event])
        assert_equal :live, reconciler.classify(attempt)
        live["agent_session"] = "replacement"
        assert_equal :uncertain, reconciler.classify(attempt)
        assert_equal "unknown", reconciler.observation(attempt)["liveness"]
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

      def test_events_from_other_attempts_are_ignored
        dead = Process.spawn("true")
        Process.wait(dead)
        foreign = Models::EvidenceEvent.build(
          type: "process_start", attempt_id: "atother", payload: {"runtime" => "foreign:r", "pid" => Process.pid}
        )
        own = Models::EvidenceEvent.build(
          type: "process_start", attempt_id: "atrec01", payload: {"runtime" => "own:r", "pid" => dead}
        )
        reconciler = build_reconciler
        attempt = build_attempt(events: [foreign, own])

        assert_equal "own:r", reconciler.recorded_runtime(attempt)
        assert_equal :uncertain, reconciler.classify(attempt)
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
