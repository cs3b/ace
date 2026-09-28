# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Assign
    class AttemptStartCommandTest < AceAssignTestCase
      def create_assignment(cache_dir, managed: true)
        Molecules::AssignmentManager.new(cache_base: cache_dir).create(
          name: "attempt-start-test",
          source_config: "job.yaml",
          task_id: managed ? "8wr.t.qjl" : nil,
          project_id: "ace"
        )
      end

      def run_attempt_cli(*args)
        result = {}
        output = capture_io do
          result[:code] = CLI.start(args)
        end
        [result[:code], output.first]
      end

      def start_attempt(assignment_id, project: "ace", step: "010")
        code, out = run_attempt_cli(
          "attempt", "start",
          "--assignment", assignment_id,
          "--step", step,
          "--project", project
        )
        [code, JSON.parse(out)]
      end

      def test_start_binds_and_journals_a_managed_attempt
        with_attempt_cli_env do |cache_dir, repo|
          assignment = create_assignment(cache_dir)

          exit_code, payload = start_attempt(assignment.id)

          assert_equal 0, exit_code
          assert payload["attempt_id"]
          assert_equal "running", payload["state"]
          assert_equal "010", payload["scope"]
          assert_equal "ace", payload["project_id"]
          assert_equal "8wr.t.qjl", payload["task_id"]
          assert_equal git_in(repo, "rev-parse", "HEAD"), payload["base_head"]
          assert_equal "refs/ace/execution", payload["evidence_git_ref"]
          assert payload["journal_commit"]
          assert_equal "git", payload["recovery_mode"]
        end
      end

      def test_repeated_identical_start_returns_the_same_attempt
        with_attempt_cli_env do |cache_dir, _repo|
          assignment = create_assignment(cache_dir)

          _code, first = start_attempt(assignment.id)
          _code, second = start_attempt(assignment.id, step: " 010 ")

          assert_equal first["attempt_id"], second["attempt_id"]
        end
      end

      def test_conflicting_start_fails_without_second_writer
        with_attempt_cli_env do |cache_dir, _repo|
          assignment = create_assignment(cache_dir)
          start_attempt(assignment.id)

          error = assert_raises(AttemptErrors::Conflict) do
            run_attempt_cli(
              "attempt", "start",
              "--assignment", assignment.id,
              "--step", "010",
              "--project", "other-project"
            )
          end

          assert_equal 5, error.exit_code
        end
      end

      def test_taskless_start_reports_local_only_recovery
        with_attempt_cli_env do |cache_dir, _repo|
          assignment = create_assignment(cache_dir, managed: false)

          _code, payload = start_attempt(assignment.id)

          assert_equal "local_only", payload["recovery_mode"]
          assert_nil payload["evidence_git_ref"]
          assert_nil payload["journal_commit"]
        end
      end

      def test_missing_options_fail_with_usage
        with_attempt_cli_env do |_cache_dir, _repo|
          error = assert_raises(Ace::Support::Cli::Error) do
            run_attempt_cli("attempt", "start", "--assignment", "8wrabc")
          end
          assert_includes error.message, "Missing --step"
        end
      end
    end
  end
end
