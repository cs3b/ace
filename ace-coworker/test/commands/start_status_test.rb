# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module CLI
      module Commands
        class StartTest < AceCoworkerTestCase
          def setup
            super
            @dir = Dir.mktmpdir("coworker-cmd")
            CoworkerFixture.build_task(@dir, id: "8xh.t.aaa")
            CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "8xh.t.aaa")
            CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xh.t.aaa")
            @probe_runner = ->(_argv, _cwd) {
              [CoworkerFixture.status_json(state: "running", steps: [{number: 1, name: "s", status: "pending"}]),
                "", CoworkerFixture::SuccessStatus.ok]
            }
          end

          def teardown
            FileUtils.remove_entry(@dir)
          end

          def command
            Start.new(orchestrator: Organisms::StartOrchestrator.new(
              project_root: @dir,
              assignment_probe: Molecules::AssignmentProbe.new(project_root: @dir, runner: @probe_runner)
            ))
          end

          def capture
            original = $stdout
            $stdout = StringIO.new
            yield
            $stdout.string
          ensure
            $stdout = original
          end

          def test_start_outputs_brief_table
            out = capture { command.call(config: nil, format: "table", quiet: false) }
            assert_includes out, "Coworker brief"
            assert_includes out, "--assignment abc123"
          end

          def test_start_outputs_brief_json
            require "json"
            out = capture { command.call(config: nil, format: "json", quiet: false) }
            payload = JSON.parse(out)
            assert_equal "worker", payload["role"]
            assert_equal "abc123", payload["assignment"]
          end

          def test_start_with_missing_config_raises_cli_error
            File.delete(File.join(@dir, ".ace-local", "coworker", "config.yml"))
            error = assert_raises(Ace::Support::Cli::Error) { command.call(config: nil, format: "table", quiet: false) }
            assert_equal "not ready: .ace-local/coworker/config.yml not found", error.message
          end

          def test_quiet_suppresses_output
            assert_empty capture { command.call(config: nil, format: "table", quiet: true) }
          end

          def test_interrupt_propagates_to_the_exe_wrapper
            # F9 regression: Ctrl-C during start must reach exe/ace-coworker
            # (exit 130), not be swallowed into a success return.
            interrupting = Start.new(orchestrator: ->(*) { raise Interrupt })
            assert_raises(Interrupt) { interrupting.call(config: nil, format: "table", quiet: false) }
          end
        end

        class StatusTest < AceCoworkerTestCase
          def setup
            super
            @dir = Dir.mktmpdir("coworker-cmd-status")
            CoworkerFixture.build_task(@dir, id: "8xh.t.aaa")
            CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "8xh.t.aaa")
            CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xh.t.aaa")
          end

          def teardown
            FileUtils.remove_entry(@dir)
          end

          def command(json: nil, success: true)
            runner = ->(_argv, _cwd) { [json.to_s, "", CoworkerFixture::SuccessStatus.new(success)] }
            Status.new(orchestrator: Organisms::StatusOrchestrator.new(
              project_root: @dir,
              assignment_probe: Molecules::AssignmentProbe.new(project_root: @dir, runner: runner)
            ))
          end

          def capture
            original = $stdout
            $stdout = StringIO.new
            yield
            $stdout.string
          ensure
            $stdout = original
          end

          def test_missing_config_renders_not_ready_exit_zero
            File.delete(File.join(@dir, ".ace-local", "coworker", "config.yml"))
            out = capture { command.call(config: nil, assignment: nil, format: "table", quiet: false) }
            assert_includes out, "not ready: .ace-local/coworker/config.yml not found"
          end

          def test_status_table_shows_verdict_and_remaining
            json = CoworkerFixture.status_json(state: "running",
              steps: [{number: 1, name: "a", status: "done"}, {number: 2, name: "b", status: "pending"}])
            out = capture { command(json: json).call(config: nil, assignment: nil, format: "table", quiet: false) }
            assert_includes out, "incomplete"
            assert_includes out, "pending step"
          end

          def test_status_json_payload
            require "json"
            json = CoworkerFixture.status_json(state: "completed", steps: [{number: 1, name: "a", status: "done"}])
            out = capture { command(json: json).call(config: nil, assignment: nil, format: "json", quiet: false) }
            payload = JSON.parse(out)
            assert_equal true, payload["ready"]
            assert_equal true, payload["assignment_status"]["complete"]
          end

          def test_interrupt_propagates_to_the_exe_wrapper
            # F9 regression: Ctrl-C during status must reach
            # exe/ace-coworker (exit 130), not be swallowed into success.
            interrupting = Status.new(orchestrator: ->(**) { raise Interrupt })
            assert_raises(Interrupt) { interrupting.call(config: nil, assignment: nil, format: "table", quiet: false) }
          end
        end
      end
    end
  end
end
