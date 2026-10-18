# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Organisms
      class ResumeOrchestratorTest < AceCoworkerTestCase
        def setup
          super
          @dir = Dir.mktmpdir("coworker-resume")
          @task_path = CoworkerFixture.build_task(@dir, id: "8xh.t.aaa")
          CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "8xh.t.aaa")
          @config_path = CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xh.t.aaa")
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def orchestrator(json:, report_orchestrator: nil)
          ResumeOrchestrator.new(
            project_root: @dir,
            config: {"config_path" => @config_path},
            assignment_probe: Molecules::AssignmentProbe.new(project_root: @dir,
              runner: ->(_argv, _cwd) { [json, "", CoworkerFixture::SuccessStatus.ok] }),
            git_probe: git_probe,
            report_orchestrator: report_orchestrator)
        end

        def git_probe
          state = {"branch" => "feature", "ahead_behind" => "ahead 1",
            "dirty_entries" => ["M lib/a.rb"], "last_commit" => "abc1234 x"}
          Object.new.tap do |probe|
            probe.define_singleton_method(:state) { state }
          end
        end

        def running_json
          CoworkerFixture.status_json(state: "running",
            steps: [{number: "010", name: "impl", status: "done"},
                    {number: "020", name: "verify", status: "active"}])
        end

        def completed_json
          CoworkerFixture.status_json(state: "completed",
            steps: [{number: "010", name: "impl", status: "done"}])
        end

        def tree_snapshot
          Dir.glob(File.join(@dir, "**", "*"), File::FNM_DOTMATCH).sort
        end

        def test_continue_writes_nothing_and_surfaces_remaining_work
          before = tree_snapshot
          result = orchestrator(json: running_json).call(config_path: nil)

          assert_equal 0, result.exit_code, result.message
          assert result.plan.continue?
          assert_equal ["010 impl"], result.plan.preserved_steps
          assert_equal ["020 verify (active)"], result.plan.remaining_steps
          assert_equal ["M lib/a.rb"], result.plan.git["dirty_entries"]
          assert_equal before, tree_snapshot, "resume writes nothing on :continue"
        end

        def test_missing_config_reuses_start_error_message
          File.delete(@config_path)
          error = assert_raises(Error) { orchestrator(json: running_json).call(config_path: nil) }
          assert_includes error.message, "not ready: .ace-local/coworker/config.yml not found"
        end

        def test_mismatched_assignment_is_refused_without_substitute
          CoworkerFixture.build_assignment(@dir, id: "other99", task_id: "8xh.t.bbb")
          error = assert_raises(Error) { orchestrator(json: running_json).call(config_path: nil, assignment: "other99") }
          assert_includes error.message, "belongs to task"
        end

        def test_report_disposition_delegates_to_report_orchestrator
          delegated = []
          report_double = Object.new
          report_double.define_singleton_method(:call) do |**options|
            delegated << options
            ReportOrchestrator::ReportResult.new(outcome: nil, record_path: "/rec",
              event_id: "ab12cd", delivery: nil,
              message: "outcome recorded: success at /rec; delivery failed: x", exit_code: 1)
          end

          result = orchestrator(json: completed_json, report_orchestrator: report_double)
            .call(config_path: nil)

          assert_equal 1, result.exit_code
          assert_equal 1, delegated.size
          assert_equal "abc123", delegated.first[:assignment]
          assert_equal :report, result.plan.disposition
          assert_nil result.plan.redeliver_event_id, "no prior event: plan chooses create"
          assert_equal "ab12cd", result.report_result.event_id
          assert_includes result.message, "redelivering the report"
        end

        def test_report_disposition_dry_run_does_not_delegate
          report_double = Object.new
          report_double.define_singleton_method(:call) { flunk "dry-run must not delegate" }

          result = orchestrator(json: completed_json, report_orchestrator: report_double)
            .call(config_path: nil, dry_run: true)

          assert_equal 0, result.exit_code
          assert_nil result.report_result
        end

        def test_complete_and_delivered_is_informational
          state_dir = File.join(@dir, ".ace-local", "coworker", "reports")
          FileUtils.mkdir_p(state_dir)
          File.write(File.join(state_dir, "abc123.json"),
            JSON.generate({"result" => "success", "event_id" => "ab12cd",
              "delivery" => "delivered (event ab12cd)"}))

          result = orchestrator(json: completed_json).call(config_path: nil)

          assert_equal 0, result.exit_code
          assert_equal :complete, result.plan.disposition
          assert_includes result.message, "nothing to resume"
        end
      end
    end
  end
end
