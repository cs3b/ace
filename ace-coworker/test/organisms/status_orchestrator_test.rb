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

        def test_relative_config_path_resolves_against_project_root_not_cwd
          subdir = File.join(@dir, "deep", "sub")
          FileUtils.mkdir_p(subdir)
          Dir.chdir(subdir) do
            result = orchestrator.call(config_path: ".ace-local/coworker/config.yml")
            assert result.is_a?(StatusOrchestrator::Ready), result.respond_to?(:message) ? result.message : nil
            assert_equal "abc123", result.config.assignment
          end
        end

        def test_assignment_override_reports_effective_assignment_identity
          CoworkerFixture.build_assignment(@dir, id: "zzz999", task_id: "8xh.t.aaa")
          probed = []
          runner = ->(argv, _cwd) do
            probed << argv[argv.index("--assignment") + 1]
            [CoworkerFixture.status_json(state: "running",
              steps: [{number: 1, name: "a", status: "done"}], id: "zzz999"), "",
              CoworkerFixture::SuccessStatus.ok]
          end
          orchestrator_override = StatusOrchestrator.new(
            project_root: @dir,
            assignment_probe: Molecules::AssignmentProbe.new(project_root: @dir, runner: runner)
          )
          result = orchestrator_override.call(assignment: "zzz999")

          assert result.is_a?(StatusOrchestrator::Ready)
          assert_equal "zzz999", result.assignment
          assert_equal "zzz999", probed.last
          refute_equal result.assignment, result.config.assignment
        end

        def test_malformed_yaml_renders_not_ready_without_raising
          File.write(File.join(@dir, ".ace-local", "coworker", "config.yml"), "role: [unclosed\n")
          result = orchestrator.call
          assert result.is_a?(StatusOrchestrator::NotReady)
          assert_includes result.message, "invalid config"
        end

        def test_scalar_nested_sections_render_not_ready_without_raising
          File.write(File.join(@dir, ".ace-local", "coworker", "config.yml"), <<~YAML)
            role: worker
            instructions: roles/worker.md
            start_prompt: "Drive it."
            task: 8xh.t.aaa
            assignment: abc123
            overseer: overseer@lab
            reporting: hitl
          YAML
          result = orchestrator.call
          assert result.is_a?(StatusOrchestrator::NotReady)
          assert_includes result.message, "'reporting' must be a mapping"
        end
      end
    end
  end
end
