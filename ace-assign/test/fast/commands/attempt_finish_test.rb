# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Assign
    class AttemptFinishCommandTest < AceAssignTestCase
      ReceiptAttempt = Struct.new(:attempt_id, :binding, keyword_init: true)
      ReceiptBinding = Struct.new(:assignment_id, :project_id, :scope, keyword_init: true)

      def receipt_attempt(attempt_id, assignment_id)
        ReceiptAttempt.new(
          attempt_id: attempt_id,
          binding: ReceiptBinding.new(assignment_id: assignment_id, project_id: "ace", scope: "010")
        )
      end
      def create_assignment(cache_dir)
        Molecules::AssignmentManager.new(cache_base: cache_dir).create(
          name: "attempt-finish-test",
          source_config: "job.yaml",
          task_id: "8wr.t.qjl",
          project_id: "ace"
        )
      end

      def start_attempt(assignment_id)
        result = {}
        output = capture_io do
          result[:code] = CLI.start([
            "attempt", "start",
            "--assignment", assignment_id,
            "--step", "010",
            "--project", "ace"
          ])
        end
        [result[:code], JSON.parse(output.first)]
      end

      def run_cli(*args)
        result = {}
        output = capture_io do
          result[:code] = CLI.start(args)
        end
        [result[:code], output.first]
      end

      def test_finish_accepts_structured_receipt_and_pins_candidate
        with_attempt_cli_env do |cache_dir, repo|
          assignment = create_assignment(cache_dir)
          _code, started = start_attempt(assignment.id)
          candidate_before = git_in(repo, "rev-parse", "HEAD")
          receipt = write_attempt_receipt(cache_dir, repo, receipt_attempt(started["attempt_id"], assignment.id))

          result = {}
          output = capture_io do
            result[:code] = CLI.start([
              "attempt", "finish",
              "--attempt", started["attempt_id"],
              "--receipt", receipt
            ])
          end
          payload = JSON.parse(output.first)

          assert_equal 0, result[:code]
          assert_equal "succeeded", payload["state"]
          assert_equal candidate_before, payload["candidate_head"]
          assert_equal candidate_before, git_in(repo, "rev-parse", "HEAD")
          assert payload["journal_commit"]
        end
      end

      def test_finish_rejects_stale_head_receipt
        with_attempt_cli_env do |cache_dir, repo|
          assignment = create_assignment(cache_dir)
          _code, started = start_attempt(assignment.id)
          stale_head = git_in(repo, "rev-parse", "HEAD")
          File.write(File.join(repo, "later.txt"), "candidate moved\n")
          git_in(repo, "add", "later.txt")
          git_in(repo, "commit", "-m", "move candidate")
          receipt = write_attempt_receipt(cache_dir, repo, receipt_attempt(started["attempt_id"], assignment.id), "head" => stale_head)

          error = assert_raises(AttemptErrors::ReceiptRejected) do
            run_cli(
              "attempt", "finish",
              "--attempt", started["attempt_id"],
              "--receipt", receipt
            )
          end

          assert_equal 5, error.exit_code
          assert_includes error.message, "stale"
        end
      end

      def test_finish_refuses_terminal_attempt
        with_attempt_cli_env do |cache_dir, repo|
          assignment = create_assignment(cache_dir)
          _code, started = start_attempt(assignment.id)
          receipt = write_attempt_receipt(cache_dir, repo, receipt_attempt(started["attempt_id"], assignment.id))
          capture_io do
            CLI.start(["attempt", "finish", "--attempt", started["attempt_id"], "--receipt", receipt])
          end

          error = assert_raises(AttemptErrors::InvalidState) do
            run_cli(
              "attempt", "finish",
              "--attempt", started["attempt_id"],
              "--receipt", receipt
            )
          end

          assert_equal 5, error.exit_code
          assert_includes error.message, "immutable"
        end
      end
    end
  end
end
