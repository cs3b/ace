# frozen_string_literal: true

require_relative "../test_helper"
require "json"
require "pathname"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Organisms
      class ReportOrchestratorTest < AceCoworkerTestCase
        FakeHitlRunner = Struct.new(:calls, :script) do
          def call(argv, _cwd)
            calls << argv
            step = script.shift || {success: true, out: "HITL event created: 8xhq01 x\n"}
            [step[:out], step[:err], Status.new(step[:success])]
          end

          Status = Struct.new(:success?)
        end

        def setup
          super
          @dir = Dir.mktmpdir("coworker-report")
          @task_path = CoworkerFixture.build_task(@dir, id: "8xh.t.aaa")
          CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "8xh.t.aaa")
          @config_path = CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xh.t.aaa")
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def orchestrator(json:, script: [])
          @runner_calls = []
          runner = FakeHitlRunner.new(@runner_calls, script.dup)
          config = {"hitl" => {"root_dir" => File.join(@dir, ".ace-local", "hitl")}}
          # The coworker HitlReporter resolves bin/ace-hitl from project root;
          # with no binstub it falls back to PATH "ace-hitl", which the fake
          # runner intercepts regardless.
          ReportOrchestrator.new(
            project_root: @dir,
            config: {"config_path" => @config_path},
            assignment_probe: Molecules::AssignmentProbe.new(project_root: @dir,
              runner: ->(_argv, _cwd) { [json, "", CoworkerFixture::SuccessStatus.ok] }),
            reporter: Molecules::HitlReporter.new(project_root: @dir, runner: runner))
        end

        def completed_json
          CoworkerFixture.status_json(state: "completed",
            steps: [{number: "010", name: "impl", status: "done"}, {number: "020", name: "verify", status: "done"}])
        end

        def failed_json
          CoworkerFixture.status_json(state: "running",
            steps: [{number: "010", name: "impl", status: "done"}, {number: "020", name: "verify", status: "failed"}])
        end

        def record_path
          File.join(@task_path, "coworker", "abc123.md")
        end

        def state_path
          File.join(@dir, ".ace-local", "coworker", "reports", "abc123.json")
        end

        def test_completed_assignment_records_result_and_reports_success
          result = orchestrator(json: completed_json,
            script: [{success: true, out: "HITL event created: 8xhq01 x\n"},
                     {success: true, out: "delivered"}])
            .call(config_path: nil)

          assert_equal 0, result.exit_code, result.message
          assert result.outcome.success?
          assert File.file?(record_path), "durable record in the task folder"
          assert_includes File.read(record_path), "result: success"
          assert File.file?(state_path), "helper state under .ace-local/coworker/"
          assert_equal "8xhq01", result.event_id
          assert result.delivery

          create_argv = @runner_calls.find { |argv| argv[1] == "create" }
          refute_nil create_argv
          assert_includes create_argv, "--result"
          assert_includes create_argv, "success"
          send_argv = @runner_calls.find { |argv| argv[1] == "send" }
          assert_equal "8xhq01", send_argv[2]
        end

        def test_send_failure_preserves_success_outcome_and_rerun_resends_only
          orch = orchestrator(json: completed_json,
            script: [{success: true, out: "HITL event created: 8xhq02 x\n"},
                     {success: false, err: "not delivered on all routes"}])

          first = orch.call(config_path: nil)
          assert_equal 1, first.exit_code
          assert_includes first.message, "outcome recorded: success"
          assert_includes first.message, "delivery failed"
          assert_includes File.read(record_path), "result: success", "work success survives delivery failure"

          # Rerun after transport restored: same result + existing event =>
          # send-only redelivery, no second create, no duplicate event.
          orch2 = orchestrator(json: completed_json,
            script: [{success: true, out: "delivered"}])
          # Simulate the event file existing (event_exists? check).
          hitl_dir = File.join(@dir, ".ace-local", "hitl")
          FileUtils.mkdir_p(File.join(hitl_dir, "8xhq02-evt"))
          File.write(File.join(hitl_dir, "8xhq02-evt", "8xhq02-evt.hitl.s.md"), "x")

          second = orch2.call(config_path: nil)

          assert_equal 0, second.exit_code, second.message
          creates = @runner_calls.count { |argv| argv[1] == "create" }
          assert_equal 0, creates, "rerun must not create a second event"
          sends = @runner_calls.select { |argv| argv[1] == "send" }
          assert_equal 1, sends.size
          assert_equal "8xhq02", sends.first[2], "rerun resends the same event"
          assert_equal "8xhq02", second.event_id
        end

        def test_error_outcome_records_cause_and_reports_error
          # Failed-step evidence gives the cause.
          steps = File.join(@dir, ".ace-local", "assign", "abc123", "steps")
          FileUtils.mkdir_p(steps)
          File.write(File.join(steps, "020-verify.st.md"), <<~MD)
            ---
            name: verify
            status: failed
            error: verifier crashed with exit 1
            ---
          MD

          result = orchestrator(json: failed_json,
            script: [{success: true, out: "HITL event created: 8xhq03 x\n"},
                     {success: true, out: "delivered"}])
            .call(config_path: nil)

          assert_equal 1, result.exit_code, "error outcome never exits success"
          assert_equal "error", result.outcome.result
          assert_includes result.outcome.cause, "verifier crashed"
          assert_includes File.read(record_path), "result: error"
          assert_includes File.read(record_path), "verifier crashed"

          create_argv = @runner_calls.find { |argv| argv[1] == "create" }
          assert_includes create_argv, "error"
        end

        def test_create_failure_preserves_outcome_without_event
          result = orchestrator(json: completed_json,
            script: [{success: false, err: "Unknown HITL recipient 'ghost'"}])
            .call(config_path: nil)

          assert_equal 1, result.exit_code
          assert_nil result.event_id
          assert_includes result.message, "outcome recorded: success"
          assert_includes result.message, "HITL create failed"
          assert File.file?(record_path), "local result survives create failure"
        end

        def test_false_success_refusal_writes_nothing
          error = assert_raises(Coworker::Error) do
            orchestrator(json: failed_json).call(config_path: nil, result: "success")
          end
          assert_includes error.message, "refusing to record work done"
          refute File.file?(record_path)
          refute File.file?(state_path)
        end

        def test_dry_run_writes_nothing
          result = orchestrator(json: completed_json).call(config_path: nil, dry_run: true)

          assert_equal 0, result.exit_code
          refute File.file?(record_path)
          refute File.file?(state_path)
          assert_empty @runner_calls
        end

        def test_no_send_creates_event_without_delivery
          result = orchestrator(json: completed_json,
            script: [{success: true, out: "HITL event created: 8xhq04 x\n"}])
            .call(config_path: nil, no_send: true)

          assert_equal 0, result.exit_code, result.message
          assert_equal "8xhq04", result.event_id
          assert_nil result.delivery
          refute @runner_calls.any? { |argv| argv[1] == "send" }
        end

        def test_on_failure_stop_rerun_with_bound_event_still_skips_hitl
          # First run reports normally and binds an event...
          FileUtils.mkdir_p(File.dirname(state_path))
          File.write(state_path, JSON.generate({"result" => "error", "event_id" => "8xhq09"}))
          hitl_dir = File.join(@dir, ".ace-local", "hitl")
          FileUtils.mkdir_p(File.join(hitl_dir, "8xhq09-evt"))
          File.write(File.join(hitl_dir, "8xhq09-evt", "8xhq09-evt.hitl.s.md"), "x")
          File.write(@config_path, File.read(@config_path) + "\nerrors:\n  on_failure: stop\n")

          result = orchestrator(json: failed_json).call(config_path: nil, message: "boom")

          assert_equal 1, result.exit_code
          assert_empty @runner_calls, "stop must gate resends too"
        end

        def test_send_failure_record_carries_event_and_failure_detail
          result = orchestrator(json: completed_json,
            script: [{success: true, out: "HITL event created: 8xhq10 x\n"},
                     {success: false, err: "no adapter routes"}])
            .call(config_path: nil)

          assert_equal 1, result.exit_code
          content = File.read(record_path)
          assert_includes content, "event_id: 8xhq10"
          assert_includes content, "failed: no adapter routes"
        end

        def test_record_evidence_path_points_at_the_real_file
          result = orchestrator(json: completed_json,
            script: [{success: true, out: "HITL event created: 8xhq11 x\n"},
                     {success: true, out: "delivered"}])
            .call(config_path: nil)

          content = File.read(record_path)
          expected = Pathname.new(record_path).relative_path_from(Pathname.new(@dir)).to_s
          assert_includes content, "record: #{expected}"
          assert File.file?(File.join(@dir, expected)), "evidence path must resolve"
        end

        def test_on_failure_stop_skips_hitl_entirely_for_errors
          File.write(@config_path, File.read(@config_path) + "\nerrors:\n  on_failure: stop\n")
          result = orchestrator(json: failed_json).call(config_path: nil, message: "verifier crashed")

          assert_equal 1, result.exit_code
          assert File.file?(record_path), "outcome still recorded locally"
          assert_empty @runner_calls, "stop means no HITL subprocess at all"
        end
      end
    end
  end
end
