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

          assert_equal "blocked", error.message
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
