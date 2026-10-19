# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Molecules
      class StepEvidenceReaderTest < AceCoworkerTestCase
        def test_reads_error_cause_from_step_state
          Dir.mktmpdir("coworker-evidence") do |dir|
            steps = File.join(dir, ".ace-local", "assign", "abc123", "steps")
            FileUtils.mkdir_p(steps)
            File.write(File.join(steps, "020-verify.st.md"), <<~MD)
              ---
              name: verify
              status: failed
              error: verifier exited 1
              ---

              body
            MD

            reader = StepEvidenceReader.new(project_root: dir)
            assert_equal "verifier exited 1", reader.read("abc123", "020")
          end
        end

        def test_absent_report_returns_nil
          Dir.mktmpdir("coworker-evidence") do |dir|
            reader = StepEvidenceReader.new(project_root: dir)
            assert_nil reader.read("abc123", "020")
            assert_nil reader.read("abc123", nil)
          end
        end

        def test_invalid_assignment_id_is_rejected
          Dir.mktmpdir("coworker-evidence") do |dir|
            reader = StepEvidenceReader.new(project_root: dir)
            error = assert_raises(Error) { reader.read("../escape", "020") }
            assert_includes error.message, "invalid assignment id"
          end
        end
      end

      class HitlReporterTest < AceCoworkerTestCase
        FakeRunner = Struct.new(:calls, :outcomes) do
          def call(argv, cwd)
            calls << {argv: argv, cwd: cwd}
            outcome = outcomes.call(argv)
            [outcome[:out], outcome[:err], OutcomeStatus.new(outcome[:success])]
          end

          OutcomeStatus = Struct.new(:success?)
        end

        def reporter(outcomes)
          @calls = []
          HitlReporter.new(project_root: "/proj", runner: FakeRunner.new(@calls, outcomes))
        end

        def config
          Models::Config.new(role: "worker", instructions: "roles/worker.md",
            start_prompt: "go", task: "8xg.t.sbz.2.2", assignment: "abc123",
            overseer: "overseer", source_path: nil)
        end

        def success_outcome
          Atoms::OutcomePlanner.plan(
            Ace::Coworker::Models::AssignmentSnapshot.new(id: "abc123", name: "work",
              state: "completed", progress: "2/2 done",
              steps: [{number: "010", name: "impl", status: "done"}, {number: "020", name: "verify", status: "done"}]))
        end

        def error_outcome
          Atoms::OutcomePlanner.plan(
            Ace::Coworker::Models::AssignmentSnapshot.new(id: "abc123", name: "work",
              state: "running", progress: "1/2 done",
              steps: [{number: "010", name: "impl", status: "done"}, {number: "020", name: "verify", status: "failed"}]),
            message: "verifier crashed")
        end

        def test_create_builds_correct_argv_and_parses_event_id
          reporter = reporter(->(argv) {
            assert_includes argv, "--type"
            {out: "HITL event created: 8xhk99 Work done - 8xg.t.sbz.2.2/abc123\n  Path: x\n", err: "", success: true}
          })

          event_id = reporter.create(success_outcome, config)

          assert_equal "8xhk99", event_id
          call = @calls.first
          assert_equal "/proj", call[:cwd]
          argv = call[:argv]
          assert_equal "create", argv[1]
          assert_includes argv, "--result"
          assert_includes argv, "success"
          assert_includes argv, "--task"
          assert_includes argv, "8xg.t.sbz.2.2"
          assert_includes argv, "--assignment"
          assert_includes argv, "abc123"
          assert_includes argv, "--step"
          assert_includes argv, "020"
          assert_includes argv, "--to"
          assert_includes argv, "overseer"
          body_index = argv.index("--body")
          assert body_index, "report carries --body lines"
        end

        def test_error_create_carries_cause_and_unfinished_step
          reporter = reporter(->(_argv) {
            {out: "HITL event created: 8xhk98 x\n", err: "", success: true}
          })

          reporter.create(error_outcome, config)

          argv = @calls.first[:argv]
          body = argv.each_cons(2).select { |k, _| k == "--body" }.map(&:last)
          assert body.any? { |line| line.include?("failed at step 020 verify: verifier crashed") }
          assert body.any? { |line| line.include?("unfinished: 020 verify (failed)") }
        end

        def test_create_failure_returns_failure_struct
          reporter = reporter(->(_argv) { {out: "", err: "Unknown HITL recipient 'ghost'", success: false} })

          result = reporter.create(success_outcome, config)

          assert_kind_of HitlReporter::Failure, result
          assert_equal "create", result.stage
          assert_includes result.message, "Unknown HITL recipient"
        end

        def test_create_conflict_builds_question_argv_and_parses_event_id
          reporter = reporter(->(_argv) {
            {out: "HITL event created: 8xhk77 Preparation conflict - 8xg.t.aaa/t.8xg-t-aaa\n", err: "", success: true}
          })

          event_id = reporter.create_conflict(
            title: "Preparation conflict - 8xg.t.aaa/t.8xg-t-aaa",
            question_lines: ["kind: active_executor", "assignment abc123 running"],
            task: "8xg.t.aaa", to: "overseer@lab")

          assert_equal "8xhk77", event_id
          argv = @calls.first[:argv]
          assert_equal "create", argv[1]
          assert_includes argv, "--type"
          assert_includes argv, "question"
          assert_includes argv, "--kind"
          assert_includes argv, "decision"
          questions = argv.each_cons(2).select { |k, _| k == "--question" }.map(&:last)
          assert_equal ["kind: active_executor", "assignment abc123 running"], questions
          assert_includes argv, "--task"
          assert_includes argv, "8xg.t.aaa"
          assert_includes argv, "--to"
          assert_includes argv, "overseer@lab"
          refute_includes argv, "--body"
        end

        def test_create_conflict_without_recipient_omits_to
          reporter = reporter(->(_argv) { {out: "HITL event created: 8xhk77 x\n", err: "", success: true} })

          reporter.create_conflict(title: "t", question_lines: ["q"], task: "8xg.t.aaa")

          refute_includes @calls.first[:argv], "--to"
        end

        def test_create_conflict_failure_returns_failure_struct
          reporter = reporter(->(_argv) { {out: "", err: "no route", success: false} })

          result = reporter.create_conflict(title: "t", question_lines: ["q"], task: "8xg.t.aaa")

          assert_kind_of HitlReporter::Failure, result
          assert_equal "create", result.stage
        end

        def test_send_report_success_and_failure
          ok = reporter(->(_argv) { {out: "delivered", err: "", success: true} })
          assert_equal true, ok.send_report("8xhk99")

          bad = reporter(->(_argv) { {out: "", err: "not delivered on all routes", success: false} })
          failure = bad.send_report("8xhk99")
          assert_equal "send", failure.stage
          assert_includes failure.message, "not delivered"

          sent = bad.instance_variable_get(:@runner).calls.first
          assert_equal ["ace-hitl", "send", "8xhk99"][1..], sent[:argv][1..]
        end
      end

      class TaskRecordWriterTest < AceCoworkerTestCase
        def test_atomic_write_into_task_coworker_subdir
          Dir.mktmpdir("coworker-record") do |dir|
            writer = TaskRecordWriter.new(task_path: dir)
            path = writer.write("abc123", "# Work done\n")

            assert_equal File.join(dir, "coworker", "abc123.md"), path
            assert_equal "# Work done\n", File.read(path)

            writer.write("abc123", "# rewritten\n")
            assert_equal "# rewritten\n", File.read(path)
          end
        end

        def test_invalid_assignment_id_rejected
          Dir.mktmpdir("coworker-record") do |dir|
            writer = TaskRecordWriter.new(task_path: dir)
            assert_raises(Error) { writer.write("../escape", "x") }
          end
        end
      end

      class ReportStateStoreTest < AceCoworkerTestCase
        def test_roundtrip
          Dir.mktmpdir("coworker-state") do |dir|
            store = ReportStateStore.new(project_root: dir)
            assert_nil store.read("abc123")

            store.write("abc123", {"result" => "success", "event_id" => "8xhk99"})

            assert_equal "8xhk99", store.read("abc123")["event_id"]
            assert_equal "success", store.read("abc123")["result"]
          end
        end
      end
    end
  end
end
