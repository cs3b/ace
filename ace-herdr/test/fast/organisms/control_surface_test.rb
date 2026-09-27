# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Organisms
      class ControlSurfaceTest < Minitest::Test
        def setup
          @executor = HerdrTestHelper::FakeExecutor.new
          @control = ControlSurface.new(executor: @executor)
        end

        def native_result(payload)
          Molecules::ExecutionResult.new(
            stdout: JSON.generate(payload), stderr: "", success: true, exit_code: 0
          )
        end

        # agent_get raising agent_not_found proves a plain pane
        def plain_control
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_get: Ace::Herdr::AgentNotFoundError.new("agent_not_found: no agent")
          })
          [ControlSurface.new(executor: executor), executor]
        end

        def tokens_from(*pairs)
          pairs.map { |type, value| {type: type, value: value} }
        end

        # --- send: plain pane --------------------------------------------------

        def test_plain_cmd_submits_via_pane_run
          control, executor = plain_control

          result = control.send_input(pane: "p1", tokens: tokens_from([:cmd, "ls -la"]))

          assert_equal({pane: "p1", sent: "cmd"}, result)
          assert_equal({pane: "p1", command: "ls -la"}, executor.calls_of(:pane_run).first[:args])
          assert_empty executor.calls_of(:pane_send_keys)
        end

        def test_plain_cmd_with_trailing_keys_sends_keys_after_submission
          control, executor = plain_control

          result = control.send_input(pane: "p1", tokens: tokens_from([:cmd, "y"], [:key, "enter"]))

          assert_equal({pane: "p1", sent: "cmd"}, result)
          assert_equal({pane: "p1", keys: ["enter"]}, executor.calls_of(:pane_send_keys).first[:args])
        end

        def test_plain_msgs_type_without_submitting
          control, executor = plain_control

          result = control.send_input(pane: "p1", tokens: tokens_from([:msg, "line one"], [:msg, "line two"]))

          assert_equal({pane: "p1", sent: "text"}, result)
          assert_equal 2, executor.calls_of(:pane_send_text).length
          assert_empty executor.calls_of(:pane_send_keys)
        end

        def test_plain_interleaved_msgs_and_keys_preserve_declaration_order
          control, executor = plain_control
          tokens = tokens_from([:msg, "a"], [:key, "esc"], [:msg, "b"], [:key, "enter"])

          control.send_input(pane: "p1", tokens: tokens)

          assert_equal(
            %i[pane_send_text pane_send_keys pane_send_text pane_send_keys],
            executor.calls.map { |call| call[:operation] }.reject { |op| op == :agent_get }
          )
        end

        def test_plain_keys_only_sends_each_key
          control, executor = plain_control

          result = control.send_input(pane: "p1", tokens: tokens_from([:key, "esc"], [:key, "enter"]))

          assert_equal({pane: "p1", sent: "keys"}, result)
          assert_equal(
            [{pane: "p1", keys: ["esc"]}, {pane: "p1", keys: ["enter"]}],
            executor.calls_of(:pane_send_keys).map { |call| call[:args] }
          )
        end

        def test_plain_multiple_enters_submit_per_enter
          control, _executor = plain_control

          result = control.send_input(pane: "p1", tokens: tokens_from([:msg, "a"], [:key, "enter"], [:msg, "b"], [:key, "enter"]))

          assert_equal({pane: "p1", sent: "text"}, result)
        end

        # --- send: rejected shapes fail before any transport -------------------

        def test_empty_input_rejected_before_transport
          control, executor = plain_control

          error = assert_raises(ValidationError) { control.send_input(pane: "p1", tokens: []) }

          assert_match(/at least one/, error.message)
          assert_empty executor.calls
        end

        def test_blank_token_rejected_before_transport
          control, executor = plain_control

          assert_raises(ValidationError) { control.send_input(pane: "p1", tokens: tokens_from([:cmd, "   "])) }

          assert_empty executor.calls
        end

        def test_cmd_with_msg_rejected_before_transport
          control, executor = plain_control

          error = assert_raises(ValidationError) do
            control.send_input(pane: "p1", tokens: tokens_from([:cmd, "ls"], [:msg, "x"]))
          end

          assert_match(/either --cmd or --msg/, error.message)
          assert_empty executor.calls
        end

        def test_double_cmd_rejected_before_transport
          control, executor = plain_control

          assert_raises(ValidationError) do
            control.send_input(pane: "p1", tokens: tokens_from([:cmd, "a"], [:cmd, "b"]))
          end

          assert_empty executor.calls
        end

        def test_key_before_cmd_rejected_before_transport
          control, executor = plain_control

          error = assert_raises(ValidationError) do
            control.send_input(pane: "p1", tokens: tokens_from([:key, "esc"], [:cmd, "run"]))
          end

          assert_match(/after --cmd/, error.message)
          assert_empty executor.calls
        end

        # --- send: agent pane ---------------------------------------------------

        def test_agent_cmd_becomes_one_self_submitting_prompt
          result = @control.send_input(pane: "p1", tokens: tokens_from([:cmd, "review it"]))

          assert_equal({pane: "p1", sent: "prompt"}, result)
          assert_equal(
            {pane: "p1", text: "review it"},
            @executor.calls_of(:agent_prompt).first[:args]
          )
        end

        def test_agent_msgs_become_one_newline_joined_prompt
          result = @control.send_input(pane: "p1", tokens: tokens_from([:msg, "line one"], [:msg, "line two"]))

          assert_equal({pane: "p1", sent: "prompt"}, result)
          assert_equal({pane: "p1", text: "line one\nline two"}, @executor.calls_of(:agent_prompt).first[:args])
        end

        def test_agent_trailing_enter_dropped_and_reported
          result = @control.send_input(pane: "p1", tokens: tokens_from([:msg, "hello"], [:key, "Enter"]))

          assert_equal({pane: "p1", sent: "prompt", dropped_keys: ["Enter"]}, result)
          assert_equal 1, @executor.calls_of(:agent_prompt).length
          assert_empty @executor.calls_of(:agent_send_keys)
        end

        def test_agent_cmd_with_trailing_enter_dropped_and_reported
          result = @control.send_input(pane: "p1", tokens: tokens_from([:cmd, "go"], [:key, "enter"]))

          assert_equal({pane: "p1", sent: "prompt", dropped_keys: ["Enter"]}, result)
        end

        def test_agent_keys_only_route_to_agent_transport
          result = @control.send_input(pane: "p1", tokens: tokens_from([:key, "esc"], [:key, "ctrl+c"]))

          assert_equal({pane: "p1", sent: "keys"}, result)
          assert_equal({pane: "p1", keys: %w[esc ctrl+c]}, @executor.calls_of(:agent_send_keys).first[:args])
        end

        def test_agent_cmd_with_non_enter_key_rejected_before_transport
          error = assert_raises(ValidationError) do
            @control.send_input(pane: "p1", tokens: tokens_from([:cmd, "go"], [:key, "esc"]))
          end

          assert_match(/at most one trailing/, error.message)
          assert_empty @executor.calls_of(:agent_prompt)
        end

        def test_agent_msgs_with_non_enter_key_rejected_before_transport
          assert_raises(ValidationError) do
            @control.send_input(pane: "p1", tokens: tokens_from([:msg, "hello"], [:key, "esc"]))
          end

          assert_empty @executor.calls_of(:agent_prompt)
        end

        def test_agent_enter_between_msgs_rejected
          error = assert_raises(ValidationError) do
            @control.send_input(pane: "p1", tokens: tokens_from([:msg, "a"], [:key, "Enter"], [:msg, "b"]))
          end

          assert_match(/must trail the text/, error.message)
          assert_empty @executor.calls_of(:agent_prompt)
        end

        def test_agent_multiple_enters_rejected
          assert_raises(ValidationError) do
            @control.send_input(pane: "p1", tokens: tokens_from([:key, "enter"], [:key, "enter"]))
          end

          assert_empty @executor.calls_of(:agent_send_keys)
        end

        def test_agent_blocked_propagates_from_prompt
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_prompt: Ace::Herdr::AgentBlockedError.new("agent_blocked: busy")
          })
          @control = ControlSurface.new(executor: @executor)

          assert_raises(AgentBlockedError) do
            @control.send_input(pane: "p1", tokens: tokens_from([:cmd, "go"]))
          end
        end

        def test_probe_failure_other_than_missing_agent_propagates
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_get: Ace::Herdr::CommandError.new("herdr command failed (exit 1)")
          })
          @control = ControlSurface.new(executor: @executor)

          assert_raises(CommandError) do
            @control.send_input(pane: "p1", tokens: tokens_from([:cmd, "go"]))
          end
        end

        # --- capture / wait: output ---------------------------------------------

        def test_capture_returns_raw_stdout_without_json_wrapping
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_read: Molecules::ExecutionResult.new(
              stdout: "plain text\nexit 0", stderr: "", success: true, exit_code: 0
            )
          })
          @control = ControlSurface.new(executor: @executor)

          assert_equal "plain text\nexit 0", @control.capture(pane: "p1")
        end

        def test_capture_passes_source_and_lines
          @control.capture(pane: "p1", source: "visible", lines: 10)

          call = @executor.calls_of(:pane_read).first
          assert_equal({pane: "p1", source: "visible", lines: 10}, call[:args])
        end

        def test_wait_output_delegates_pattern_and_timeout_ms
          @control.wait_output(pane: "p1", pattern: "done", timeout_ms: 2500)

          call = @executor.calls_of(:pane_wait_output).first
          assert_equal(
            {pane: "p1", pattern: "done", source: "recent", lines: nil, timeout_ms: 2500},
            call[:args]
          )
        end

        def test_wait_output_timeout_propagates
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_wait_output: Ace::Herdr::WaitTimeoutError.new("timeout: no match")
          })
          @control = ControlSurface.new(executor: @executor)

          assert_raises(WaitTimeoutError) do
            @control.wait_output(pane: "p1", pattern: "nope", timeout_ms: 100)
          end
        end

        # --- list -----------------------------------------------------------

        def test_list_panes_normalizes_native_rows
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: native_result(
              id: "cli:pane:list",
              result: {
                type: "pane_list",
                panes: [
                  {
                    "pane_id" => "w1:p1", "tab_id" => "w1:t1", "workspace_id" => "w1",
                    "terminal_title" => "~", "terminal_title_stripped" => "~",
                    "cwd" => "/tmp", "focused" => true, "agent_status" => "idle"
                  }
                ]
              }
            )
          })
          @control = ControlSurface.new(executor: @executor)

          panes = @control.list_panes

          assert_equal(
            [{id: "w1:p1", tab: "w1:t1", workspace: "w1", title: "~", cwd: "/tmp",
              focused: true, agent_status: "idle"}],
            panes
          )
        end

        def test_list_panes_falls_back_to_raw_title
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: native_result(
              result: {panes: [{"pane_id" => "w1:p1", "terminal_title" => "raw"}]}
            )
          })
          @control = ControlSurface.new(executor: @executor)

          assert_equal "raw", @control.list_panes.first[:title]
        end

        def test_list_panes_scopes_by_workspace
          @control.list_panes(workspace_id: "w2")

          call = @executor.calls_of(:pane_list).first
          assert_equal({workspace_id: "w2"}, call[:args])
        end

        def test_list_panes_empty_result_is_empty_array
          assert_empty @control.list_panes
        end

        def test_list_tabs_normalizes_native_rows
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            tab_list: native_result(
              result: {
                tabs: [{
                  "tab_id" => "w1:t1", "workspace_id" => "w1", "label" => "editor",
                  "number" => 1, "pane_count" => 2, "focused" => true
                }]
              }
            )
          })
          @control = ControlSurface.new(executor: @executor)

          assert_equal(
            [{id: "w1:t1", workspace: "w1", title: "editor", number: 1,
              pane_count: 2, focused: true}],
            @control.list_tabs
          )
        end

        def test_list_workspaces_normalizes_native_rows
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            workspace_list: native_result(
              result: {
                workspaces: [{
                  "workspace_id" => "w1", "label" => "dev", "number" => 1,
                  "tab_count" => 2, "pane_count" => 3, "focused" => false
                }]
              }
            )
          })
          @control = ControlSurface.new(executor: @executor)

          assert_equal(
            [{id: "w1", title: "dev", number: 1, tab_count: 2, pane_count: 3, focused: false}],
            @control.list_workspaces
          )
        end
      end
    end
  end
end
