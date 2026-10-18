# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Molecules
      class AssignmentProbeTest < AceCoworkerTestCase
        def setup
          super
          @dir = Dir.mktmpdir("coworker-probe")
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def probe_with(json, success: true)
          status = CoworkerFixture::SuccessStatus.new(success)
          runner = ->(argv, cwd) { @seen_argv = argv; @seen_cwd = cwd; [json, "", status] }
          AssignmentProbe.new(project_root: @dir, runner: runner)
        end

        def test_uses_assign_status_json_with_argv_and_cwd
          probe = probe_with(CoworkerFixture.status_json(state: "running", steps: [{number: 1, name: "a", status: "pending"}]))
          snapshot = probe.snapshot("abc123")
          assert_equal ["ace-assign", "status", "--assignment", "abc123", "--format", "json"], @seen_argv
          assert_equal @dir, @seen_cwd
          assert_equal "running", snapshot.state
          assert_equal "0/1 done", snapshot.progress
        end

        def test_failed_runner_raises_with_stderr_message
          probe = probe_with("", success: false)
          error = assert_raises(Error) { probe.snapshot("abc123") }
          assert_includes error.message, "cannot read assignment 'abc123'"
        end

        def test_invalid_json_raises_parse_error
          probe = probe_with("not json")
          error = assert_raises(Error) { probe.snapshot("abc123") }
          assert_includes error.message, "cannot parse ace-assign status"
        end

        def test_completion_verdict_rules
          complete = CoworkerFixture.status_json(state: "completed",
            steps: [{number: 1, name: "a", status: "done"}, {number: 2, name: "b", status: "done"}])
          assert_equal :complete, probe_with(complete).snapshot("x").completion_verdict

          empty = CoworkerFixture.status_json(state: "completed", steps: [])
          assert_equal :incomplete, probe_with(empty).snapshot("x").completion_verdict

          failed = CoworkerFixture.status_json(state: "failed", steps: [{number: 1, name: "a", status: "failed"}])
          snapshot = probe_with(failed).snapshot("x")
          assert_equal :incomplete, snapshot.completion_verdict
          assert_includes snapshot.incomplete_reasons.join("; "), "failed step"

          pending = CoworkerFixture.status_json(state: "running",
            steps: [{number: 1, name: "a", status: "done"}, {number: 2, name: "b", status: "active"}])
          snapshot = probe_with(pending).snapshot("x")
          assert_equal :incomplete, snapshot.completion_verdict
          assert_includes snapshot.incomplete_reasons.join("; "), "active step"
        end
      end
    end
  end
end
