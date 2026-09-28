# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Assign
    class AttemptStatusCommandTest < AceAssignTestCase
      def create_assignment(cache_dir, managed: true)
        Molecules::AssignmentManager.new(cache_base: cache_dir).create(
          name: "attempt-status-test",
          source_config: "job.yaml",
          task_id: managed ? "8wr.t.qjl" : nil,
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

      def test_status_json_exposes_binding_and_references_without_credentials
        with_attempt_cli_env do |cache_dir, repo|
          assignment = create_assignment(cache_dir)
          _code, started = start_attempt(assignment.id)

          result = {}
          output = capture_io do
            result[:code] = CLI.start(["attempt", "status", "--assignment", assignment.id, "--format", "json"])
          end
          payload = JSON.parse(output.first)

          assert_equal 0, result[:code]
          assert_equal started["attempt_id"], payload["attempt_id"]
          assert_equal "running", payload["state"]
          assert_equal "010", payload["scope"]
          assert_equal git_in(repo, "rev-parse", "HEAD"), payload["base_head"]
          assert_equal "refs/ace/execution", payload["evidence_git_ref"]
          assert payload["journal_commit"]
          refute payload.key?("credentials")
          refute payload.key?("receipts")
        end
      end

      def test_status_json_for_unknown_assignment_reports_absence
        with_attempt_cli_env do |_cache_dir, _repo|
          result = {}
          output = capture_io do
            result[:code] = CLI.start(["attempt", "status", "--assignment", "8wrnope", "--format", "json"])
          end

          assert_equal 0, result[:code]
          assert_equal({"attempt" => nil}, JSON.parse(output.first))
        end
      end

      def test_status_text_mode_lists_recovery_and_heads
        with_attempt_cli_env do |cache_dir, _repo|
          assignment = create_assignment(cache_dir, managed: false)
          _code, started = start_attempt(assignment.id)

          result = {}
          output = capture_io do
            result[:code] = CLI.start(["attempt", "status", "--assignment", assignment.id, "--format", "text"])
          end
          text = output.first

          assert_equal 0, result[:code]
          assert_includes text, started["attempt_id"]
          assert_includes text, "running"
          assert_includes text, "local-only"
          assert_includes text, "unpinned"
        end
      end
    end
  end
end
