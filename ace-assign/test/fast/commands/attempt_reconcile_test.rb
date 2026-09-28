# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Assign
    # Public CLI recovery scenario (SC4): an interrupted attempt is
    # classified conservatively and resolved only against a verified,
    # boundary-attributed receipt.
    class AttemptReconcileCommandTest < AceAssignTestCase
      ReceiptAttempt = Struct.new(:attempt_id, :binding, keyword_init: true)
      ReceiptBinding = Struct.new(:assignment_id, :project_id, :scope, keyword_init: true)

      # Taskless so the event trail is local and the recovery scenario can
      # exercise public CLI reconciliation without a managed journal.
      def create_assignment(cache_dir)
        Molecules::AssignmentManager.new(cache_base: cache_dir).create(
          name: "attempt-reconcile-test",
          source_config: "job.yaml",
          task_id: nil,
          project_id: "ace"
        )
      end

      def run_cli(*args)
        result = {}
        output = capture_io do
          result[:code] = CLI.start(args)
        end
        [result[:code], output.first]
      end

      def start_attempt(assignment_id)
        code, out = run_cli(
          "attempt", "start",
          "--assignment", assignment_id,
          "--step", "010",
          "--project", "ace"
        )
        [code, JSON.parse(out)]
      end

      def rewrite_with_dead_process(assignment_id, attempt_id)
        store = Molecules::AssignmentManager.new(cache_base: Ace::Assign.cache_dir).attempt_store
        attempt = store.load(assignment_id, attempt_id)
        dead = Process.spawn("true")
        Process.wait(dead)
        events = [
          Models::EvidenceEvent.build(type: "intent", attempt_id: attempt_id, payload: {"scope" => "010"}),
          Models::EvidenceEvent.build(
            type: "process_start",
            attempt_id: attempt_id,
            payload: {"runtime" => "local:#{Socket.gethostname}", "pid" => dead}
          )
        ]
        store.save(Models::Attempt.new(binding: attempt.binding, state: "running", events: events))
      end

      def test_public_recovery_scenario_classifies_then_resolves_with_receipt
        with_attempt_cli_env do |cache_dir, repo|
          assignment = create_assignment(cache_dir)
          _code, started = start_attempt(assignment.id)
          rewrite_with_dead_process(assignment.id, started["attempt_id"])

          code, out = run_cli("attempt", "status", "--assignment", assignment.id, "--format", "json")
          assert_equal 0, code
          assert_equal "running", JSON.parse(out)["state"]

          code, out = run_cli("attempt", "reconcile", "--attempt", started["attempt_id"])
          assert_equal 0, code
          assert_equal "uncertain", JSON.parse(out)["state"]

          error = assert_raises(AttemptErrors::InvalidState) do
            run_cli("attempt", "reconcile", "--attempt", started["attempt_id"])
          end
          assert_equal 5, error.exit_code
          assert_includes error.message, "receipt"

          receipt = write_attempt_receipt(
            cache_dir, repo,
            ReceiptAttempt.new(
              attempt_id: started["attempt_id"],
              binding: ReceiptBinding.new(assignment_id: assignment.id, project_id: "ace", scope: "010")
            )
          )
          code, out = run_cli("attempt", "reconcile", "--attempt", started["attempt_id"], "--receipt", receipt)
          assert_equal 0, code
          assert_equal "succeeded", JSON.parse(out)["state"]
        end
      end

      def test_reconcile_without_attempt_fails_closed
        with_attempt_cli_env do |_cache_dir, _repo|
          error = assert_raises(AttemptErrors::NotFound) do
            run_cli("attempt", "reconcile", "--attempt", "atmissing")
          end

          assert_equal 5, error.exit_code
        end
      end

      def test_reconcile_receipt_from_unrecorded_boundary_is_rejected
        with_attempt_cli_env do |cache_dir, repo|
          assignment = create_assignment(cache_dir)
          _code, started = start_attempt(assignment.id)
          rewrite_with_dead_process(assignment.id, started["attempt_id"])
          run_cli("attempt", "reconcile", "--attempt", started["attempt_id"])

          receipt = write_attempt_receipt(
            cache_dir, repo,
            ReceiptAttempt.new(
              attempt_id: started["attempt_id"],
              binding: ReceiptBinding.new(assignment_id: assignment.id, project_id: "ace", scope: "010")
            ),
            "producer" => {"actor" => "intruder", "role" => "worker", "runtime" => "fork:66"}
          )
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            run_cli("attempt", "reconcile", "--attempt", started["attempt_id"], "--receipt", receipt)
          end

          assert_equal 5, error.exit_code
          assert_includes error.message, "execution boundary"
        end
      end
    end
  end
end
