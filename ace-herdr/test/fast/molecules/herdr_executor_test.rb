# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Molecules
      class HerdrExecutorTest < Minitest::Test
        # Executor with the process boundary stubbed out: run/raise at the
        # Open3 seam so argv building and error classification are tested
        # without the herdr binary.
        class StubbedExecutor < HerdrExecutor
          attr_reader :commands

          def initialize(results: [], **kwargs)
            super(**kwargs)
            @results = results.dup
            @commands = []
          end

          private

          def run(cmd)
            @commands << cmd
            @results.shift || ExecutionResult.new(stdout: "{}", stderr: "", success: true, exit_code: 0)
          end
        end

        def error_result(code, message = "boom")
          ExecutionResult.new(
            stdout: JSON.generate({error: {code: code, message: message}, id: "cli:test"}),
            stderr: "", success: false, exit_code: 1
          )
        end

        def test_agent_start_builds_expected_argv
          executor = StubbedExecutor.new(binary: "herdr")

          executor.agent_start(name: "8wm.t.vs0", kind: "pi", pane: "p5", timeout_ms: 60_000)

          assert_equal(
            [["herdr", "agent", "start", "8wm.t.vs0", "--kind", "pi", "--pane", "p5", "--timeout", "60000"]],
            executor.commands
          )
        end

        def test_agent_prompt_passes_text_as_single_argv_element
          executor = StubbedExecutor.new

          executor.agent_prompt(pane: "p5", text: "line1\nline2")

          assert_equal ["herdr", "agent", "prompt", "p5", "line1\nline2"], executor.commands.first
        end

        def test_agent_wait_repeats_until_flags
          executor = StubbedExecutor.new

          executor.agent_wait(pane: "p5", until_states: %w[idle done], timeout_ms: 2500)

          assert_equal(
            ["herdr", "agent", "wait", "p5", "--until", "idle", "--until", "done", "--timeout", "2500"],
            executor.commands.first
          )
        end

        def test_agent_blocked_maps_to_terminal_error
          executor = StubbedExecutor.new(results: [error_result("agent_blocked", "blocked")])

          error = assert_raises(AgentBlockedError) { executor.agent_prompt(pane: "p5", text: "x") }

          assert_equal "agent_blocked: blocked", error.message
          refute error.retryable?
        end

        def test_pane_not_found_maps_to_terminal_error
          executor = StubbedExecutor.new(results: [error_result("pane_not_found")])

          assert_raises(PaneNotFoundError) { executor.agent_get("p5") }
        end

        def test_timeout_maps_to_retryable_error
          executor = StubbedExecutor.new(results: [error_result("timeout")])

          error = assert_raises(AgentNotReadyError) do
            executor.agent_wait(pane: "p5", until_states: %w[idle], timeout_ms: 1000)
          end

          assert error.retryable?
        end

        def test_stalled_prompt_maps_to_retryable_error
          executor = StubbedExecutor.new(results: [error_result("agent_prompt_stalled")])

          assert_raises(AgentNotReadyError) { executor.agent_prompt(pane: "p5", text: "x") }
        end

        def test_unclassified_failure_maps_to_retryable_command_error
          executor = StubbedExecutor.new(results: [
            ExecutionResult.new(stdout: "", stderr: "segmentation fault?", success: false, exit_code: 139)
          ])

          error = assert_raises(CommandError) { executor.agent_get("p5") }

          assert error.retryable?
          assert_match(/exit 139/, error.message)
        end

        def test_error_json_on_stderr_is_recognized
          executor = StubbedExecutor.new(results: [
            ExecutionResult.new(
              stdout: "", stderr: JSON.generate({error: {code: "pane_not_found", message: "gone"}}),
              success: false, exit_code: 1
            )
          ])

          assert_raises(PaneNotFoundError) { executor.pane_close("p5") }
        end

        def test_success_returns_result_without_raising
          executor = StubbedExecutor.new

          result = executor.agent_get("p5")

          assert result.success?
        end

        # --- terminal-control surface (spec 8wq.t.k84) ----------------------

        def test_workspace_list_builds_expected_argv
          executor = StubbedExecutor.new

          executor.workspace_list

          assert_equal ["herdr", "workspace", "list"], executor.commands.first
        end

        def test_tab_list_scopes_by_workspace_when_given
          executor = StubbedExecutor.new

          executor.tab_list(workspace_id: "w1")
          executor.tab_list(workspace_id: nil)

          assert_equal(
            [["herdr", "tab", "list", "--workspace", "w1"], ["herdr", "tab", "list"]],
            executor.commands
          )
        end

        def test_pane_list_scopes_by_workspace_when_given
          executor = StubbedExecutor.new

          executor.pane_list(workspace_id: "w1")
          executor.pane_list(workspace_id: nil)

          assert_equal(
            [["herdr", "pane", "list", "--workspace", "w1"], ["herdr", "pane", "list"]],
            executor.commands
          )
        end

        def test_pane_send_text_passes_text_as_single_argv_element
          executor = StubbedExecutor.new

          executor.pane_send_text("p5", "echo hi")

          assert_equal ["herdr", "pane", "send-text", "p5", "echo hi"], executor.commands.first
        end

        def test_pane_send_keys_passes_keys_in_order
          executor = StubbedExecutor.new

          executor.pane_send_keys("p5", %w[enter])

          assert_equal ["herdr", "pane", "send-keys", "p5", "enter"], executor.commands.first
        end

        def test_agent_send_keys_passes_keys_in_order
          executor = StubbedExecutor.new

          executor.agent_send_keys("p5", %w[esc ctrl+c])

          assert_equal ["herdr", "agent", "send-keys", "p5", "esc", "ctrl+c"], executor.commands.first
        end

        def test_pane_read_defaults_to_recent_source_without_lines
          executor = StubbedExecutor.new

          executor.pane_read("p5")

          assert_equal ["herdr", "pane", "read", "p5", "--source", "recent"], executor.commands.first
        end

        def test_pane_read_passes_source_and_lines
          executor = StubbedExecutor.new

          executor.pane_read("p5", source: "visible", lines: 20)

          assert_equal(
            ["herdr", "pane", "read", "p5", "--source", "visible", "--lines", "20"],
            executor.commands.first
          )
        end

        def test_pane_wait_output_builds_expected_argv
          executor = StubbedExecutor.new

          executor.pane_wait_output("p5", pattern: "done", timeout_ms: 2500)

          assert_equal(
            ["herdr", "pane", "wait-output", "p5", "--match", "done", "--source", "recent", "--timeout", "2500"],
            executor.commands.first
          )
        end

        def test_pane_wait_output_timeout_maps_to_wait_timeout_error
          executor = StubbedExecutor.new(results: [error_result("timeout", "timed out waiting for output match")])

          error = assert_raises(Ace::Herdr::WaitTimeoutError) do
            executor.pane_wait_output("p5", pattern: "nope", timeout_ms: 250)
          end

          assert_equal "timeout: timed out waiting for output match", error.message
        end

        def test_workspace_create_builds_expected_argv
          executor = StubbedExecutor.new

          executor.workspace_create(label: "dev", cwd: "/tmp", focus: true)

          assert_equal(
            ["herdr", "workspace", "create", "--label", "dev", "--cwd", "/tmp", "--focus"],
            executor.commands.first
          )
        end

        def test_workspace_create_omits_absent_options
          executor = StubbedExecutor.new

          executor.workspace_create(label: "dev")

          assert_equal ["herdr", "workspace", "create", "--label", "dev"], executor.commands.first
        end

        def test_tab_close_builds_expected_argv
          executor = StubbedExecutor.new

          executor.tab_close("w1:t1")

          assert_equal ["herdr", "tab", "close", "w1:t1"], executor.commands.first
        end

        def test_tab_create_accepts_focus
          executor = StubbedExecutor.new

          executor.tab_create(workspace_id: "w1", label: "editor", focus: true)

          assert_equal(
            ["herdr", "tab", "create", "--workspace", "w1", "--label", "editor", "--focus"],
            executor.commands.first
          )
        end

        def test_pane_split_builds_expected_argv
          executor = StubbedExecutor.new

          executor.pane_split(pane: "p1", direction: "right", cwd: "/tmp", ratio: 0.5, focus: true)

          assert_equal(
            [
              "herdr", "pane", "split", "--pane", "p1", "--direction", "right",
              "--cwd", "/tmp", "--ratio", "0.5", "--focus"
            ],
            executor.commands.first
          )
        end

        def test_pane_split_omits_absent_options
          executor = StubbedExecutor.new

          executor.pane_split(pane: "p1", direction: "down")

          assert_equal(
            ["herdr", "pane", "split", "--pane", "p1", "--direction", "down"],
            executor.commands.first
          )
        end

        def test_tab_not_found_maps_to_terminal_error
          executor = StubbedExecutor.new(results: [error_result("tab_not_found", "tab nope not found")])

          error = assert_raises(TabNotFoundError) { executor.pane_list(workspace_id: "nope") }

          assert_equal "tab_not_found: tab nope not found", error.message
        end

        def test_workspace_not_found_maps_to_terminal_error
          executor = StubbedExecutor.new(results: [error_result("workspace_not_found", "workspace nope not found")])

          error = assert_raises(WorkspaceNotFoundError) { executor.workspace_list }

          assert_equal "workspace_not_found: workspace nope not found", error.message
        end

        def test_available_false_when_binary_missing
          executor = HerdrExecutor.new(binary: "ace-herdr-no-such-binary-xyz")

          refute executor.available?
        end

        def test_missing_binary_raises_executor_unavailable
          executor = HerdrExecutor.new(binary: "ace-herdr-no-such-binary-xyz")

          error = assert_raises(ExecutorUnavailableError) { executor.pane_current }

          assert error.retryable?
        end
      end
    end
  end
end
