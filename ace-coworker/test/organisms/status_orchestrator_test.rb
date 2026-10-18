# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Organisms
      class StatusOrchestratorTest < AceCoworkerTestCase
        def setup
          super
          @dir = Dir.mktmpdir("coworker-status")
          CoworkerFixture.build_task(@dir, id: "8xh.t.aaa")
          CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "8xh.t.aaa")
          CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xh.t.aaa")
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def orchestrator(json: nil)
          runner = ->(_argv, _cwd) { [json || default_json, "", CoworkerFixture::SuccessStatus.ok] }
          StatusOrchestrator.new(
            project_root: @dir,
            assignment_probe: Molecules::AssignmentProbe.new(project_root: @dir, runner: runner)
          )
        end

        def default_json
          CoworkerFixture.status_json(state: "running",
            steps: [{number: 1, name: "a", status: "done"}, {number: 2, name: "b", status: "active"}])
        end

        def test_missing_config_renders_not_ready_without_raising
          File.delete(File.join(@dir, ".ace-local", "coworker", "config.yml"))
          result = orchestrator.call
          assert result.is_a?(StatusOrchestrator::NotReady)
          assert_equal "not ready: .ace-local/coworker/config.yml not found", result.message
        end

        def test_ready_with_progress_and_incomplete_verdict
          result = orchestrator.call
          assert result.is_a?(StatusOrchestrator::Ready)
          assert_equal "abc123", result.config.assignment
          assert_equal :incomplete, result.snapshot.completion_verdict
          assert_includes result.snapshot.incomplete_reasons.join("; "), "active step"
        end

        def test_completed_assignment_is_complete_verdict
          json = CoworkerFixture.status_json(state: "completed",
            steps: [{number: 1, name: "a", status: "done"}, {number: 2, name: "b", status: "done"}])
          assert_equal :complete, orchestrator(json: json).call.snapshot.completion_verdict
        end

        def test_probe_error_is_carried_without_raising
          result = orchestrator(json: nil)
          runner = ->(_argv, _cwd) { ["", "boom", CoworkerFixture::SuccessStatus.new(false)] }
          failing = StatusOrchestrator.new(
            project_root: @dir,
            assignment_probe: Molecules::AssignmentProbe.new(project_root: @dir, runner: runner)
          )
          result = failing.call
          assert result.is_a?(StatusOrchestrator::Ready)
          assert_nil result.snapshot
          assert_includes result.probe_error, "cannot read assignment 'abc123'"
        end
      end
    end
  end
end
