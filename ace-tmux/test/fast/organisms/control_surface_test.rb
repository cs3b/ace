# frozen_string_literal: true

require_relative "../../test_helper"

class ControlSurfaceTest < Minitest::Test
  def test_default_constructor_uses_tmux_executor
    control = Ace::Tmux::Organisms::ControlSurface.new

    assert_instance_of Ace::Tmux::Molecules::TmuxExecutor, control.send(:executor)
  end

  def test_send_command_sends_text_then_enter
    executor = MockExecutor.new
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%2")
    )

    control.send_command(pane: "%2", command: "echo hi")

    assert_equal [
      ["tmux", "send-keys", "-t", "%2", "echo hi"],
      ["tmux", "send-keys", "-t", "%2", "Enter"]
    ], executor.run_commands
  end

  def test_send_command_delays_before_enter_for_interactive_cli_panes
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t %2 -p #{pane_current_command}	#{pane_height}	#{alternate_on}	#{pane_pid}' => mock_result(stdout: "codex\t74\t0\t120")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%2")
    )
    sleeps = []
    control.define_singleton_method(:sleep) { |duration| sleeps << duration }

    control.send_command(pane: "%2", command: "echo hi")

    assert_equal [Ace::Tmux::Organisms::ControlSurface::INTERACTIVE_SUBMIT_DELAY], sleeps
    assert_equal [
      ["tmux", "send-keys", "-t", "%2", "echo hi"],
      ["tmux", "send-keys", "-t", "%2", "Enter"]
    ], executor.run_commands
  end

  def test_send_text_sends_literal_text_without_enter
    executor = MockExecutor.new
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%2")
    )

    control.send_text(pane: "%2", text: "echo hi")

    assert_equal [["tmux", "send-keys", "-t", "%2", "echo hi"]], executor.run_commands
  end

  def test_send_sequence_runs_messages_then_keys
    executor = MockExecutor.new
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%2")
    )

    control.send_sequence(pane: "%2", messages: ["echo", " hi"], keys: ["Enter", "C-c"])

    assert_equal [
      ["tmux", "send-keys", "-t", "%2", "echo"],
      ["tmux", "send-keys", "-t", "%2", " hi"],
      ["tmux", "send-keys", "-t", "%2", "Enter"],
      ["tmux", "send-keys", "-t", "%2", "C-c"]
    ], executor.run_commands
  end

  def test_send_sequence_delays_before_first_enter_after_messages_for_interactive_cli_panes
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t %2 -p #{pane_current_command}	#{pane_height}	#{alternate_on}	#{pane_pid}' => mock_result(stdout: "claude\t40\t0\t121")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%2")
    )
    sleeps = []
    control.define_singleton_method(:sleep) { |duration| sleeps << duration }

    control.send_sequence(pane: "%2", messages: ["ping"], keys: ["Enter", "C-c"])

    assert_equal [Ace::Tmux::Organisms::ControlSurface::INTERACTIVE_SUBMIT_DELAY], sleeps
    assert_equal [
      ["tmux", "send-keys", "-t", "%2", "ping"],
      ["tmux", "send-keys", "-t", "%2", "Enter"],
      ["tmux", "send-keys", "-t", "%2", "C-c"]
    ], executor.run_commands
  end

  def test_send_sequence_does_not_delay_non_enter_keys_after_messages_for_interactive_cli_panes
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t %2 -p #{pane_current_command}	#{pane_height}	#{alternate_on}	#{pane_pid}' => mock_result(stdout: "pi\t40\t0\t122")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%2")
    )
    sleeps = []
    control.define_singleton_method(:sleep) { |duration| sleeps << duration }

    control.send_sequence(pane: "%2", messages: ["ping"], keys: ["Tab", "Enter"])

    assert_equal [], sleeps
    assert_equal [
      ["tmux", "send-keys", "-t", "%2", "ping"],
      ["tmux", "send-keys", "-t", "%2", "Tab"],
      ["tmux", "send-keys", "-t", "%2", "Enter"]
    ], executor.run_commands
  end

  def test_capture_recent_output_returns_stdout
    executor = MockExecutor.new(
      capture_responses: {
        "tmux capture-pane -p -t %3 -S -10 -E -1" => mock_result(stdout: "Task context:")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%3")
    )

    assert_equal "Task context:", control.capture_recent_output(pane: "%3", lines: 10)
  end

  def test_capture_recent_output_uses_visible_tail_for_interactive_cli_panes
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t %3 -p #{pane_current_command}	#{pane_height}	#{alternate_on}	#{pane_pid}' => mock_result(stdout: "codex\t74\t0\t123"),
        "tmux capture-pane -p -t %3 -S 64 -E 73" => mock_result(stdout: "ping")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%3")
    )

    assert_equal "ping", control.capture_recent_output(pane: "%3", lines: 10)
  end

  def test_capture_recent_output_includes_alternate_screen_for_interactive_cli_panes
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t %3 -p #{pane_current_command}	#{pane_height}	#{alternate_on}	#{pane_pid}' => mock_result(stdout: "claude\t20\t1\t124"),
        "tmux capture-pane -p -a -t %3 -S 10 -E 19" => mock_result(stdout: "visible")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%3")
    )

    assert_equal "visible", control.capture_recent_output(pane: "%3", lines: 10)
  end

  def test_capture_recent_output_uses_visible_tail_for_shell_wrapped_interactive_cli_panes
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t %3 -p #{pane_current_command}	#{pane_height}	#{alternate_on}	#{pane_pid}' => mock_result(stdout: "fish\t74\t0\t125"),
        "tmux capture-pane -p -t %3 -S 64 -E 73" => mock_result(stdout: "pong")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%3"),
      process_inspector: fake_process_inspector("codex")
    )

    assert_equal "pong", control.capture_recent_output(pane: "%3", lines: 10)
  end

  def test_wait_for_output_succeeds_when_pattern_found
    executor = MockExecutor.new(
      capture_responses: {
        "tmux capture-pane -p -t %4 -S -40 -E -1" => mock_result(stdout: "Task context:")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%4")
    )

    assert control.wait_for_condition(condition: "output", pane: "%4", pattern: "Task context:", timeout: 0.01, interval: 0.0)
  end

  def test_wait_for_output_uses_post_send_match_when_baseline_is_provided
    executor = MockExecutor.new(
      capture_responses: {
        "tmux capture-pane -p -t %4 -S -40 -E -1" => [
          mock_result(stdout: "done"),
          mock_result(stdout: "done\ndone")
        ]
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%4")
    )

    assert control.wait_for_condition(
      condition: "output",
      pane: "%4",
      pattern: "done",
      timeout: 0.01,
      interval: 0.0,
      baseline_output: "done"
    )
  end

  def test_wait_for_agent_succeeds_after_interactive_response_settles
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t %4 -p #{pane_current_command}	#{pane_height}	#{alternate_on}	#{pane_pid}' => mock_result(stdout: "codex\t74\t0\t126"),
        "tmux capture-pane -p -t %4 -S 34 -E 73" => [
          mock_result(stdout: "› ping\n• Working (1s • esc to interrupt)"),
          mock_result(stdout: "› ping\n• pong"),
          mock_result(stdout: "› ping\n• pong")
        ]
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%4")
    )

    assert control.wait_for_condition(
      condition: "agent",
      pane: "%4",
      timeout: 0.01,
      interval: 0.0,
      settle: 0.0,
      baseline_output: "› ping",
      require_change: true
    )
  end

  def test_wait_for_agent_succeeds_for_shell_wrapped_interactive_cli_panes
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t %4 -p #{pane_current_command}	#{pane_height}	#{alternate_on}	#{pane_pid}' => mock_result(stdout: "fish\t74\t0\t127"),
        "tmux capture-pane -p -t %4 -S 34 -E 73" => [
          mock_result(stdout: "› ping\n• Working (1s • esc to interrupt)"),
          mock_result(stdout: "› ping\n• pong"),
          mock_result(stdout: "› ping\n• pong")
        ]
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%4"),
      process_inspector: fake_process_inspector("codex")
    )

    assert control.wait_for_condition(
      condition: "agent",
      pane: "%4",
      timeout: 0.01,
      interval: 0.0,
      settle: 0.0,
      baseline_output: "› ping",
      require_change: true
    )
  end

  def test_wait_for_agent_rejects_generic_shell_panes
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t %4 -p #{pane_current_command}	#{pane_height}	#{alternate_on}	#{pane_pid}' => mock_result(stdout: "fish\t74\t0\t128")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%4")
    )

    error = assert_raises(Ace::Tmux::ValidationError) do
      control.wait_for_condition(condition: "agent", pane: "%4", timeout: 0.01, interval: 0.0)
    end

    assert_includes error.message, "interactive CLI pane"
  end

  def test_wait_for_pane_exited_succeeds_when_pane_disappears
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t %5 -p #{pane_dead}' => mock_result(success: false, exit_code: 1)
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(pane: "%5")
    )

    assert control.wait_for_condition(condition: "pane-exited", pane: "%5", timeout: 0.01, interval: 0.0)
  end

  def test_list_sessions_returns_sorted_rows
    executor = MockExecutor.new(
      capture_responses: {
        'tmux list-sessions -F #{session_name}	#{session_attached}	#{session_windows}' => mock_result(stdout: "zeta\t0\t1\nalpha\t2\t3")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(executor: executor, resolver: explicit_resolver)

    assert_equal [
      {session: "alpha", attached_clients: 2, window_count: 3},
      {session: "zeta", attached_clients: 0, window_count: 1}
    ], control.list_sessions
  end

  def test_list_windows_returns_window_rows
    executor = MockExecutor.new(
      capture_responses: {
        'tmux list-windows -t dev -F #{window_active}	#{window_id}	#{session_name}	#{window_index}	#{window_name}	#{window_panes}' => mock_result(stdout: "1\t@2\tdev\t3\twork\t4")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(session: "dev")
    )

    assert_equal [
      {active: true, id: "@2", session: "dev", index: 3, name: "work", pane_count: 4}
    ], control.list_windows(session: "dev")
  end

  def test_list_panes_returns_rows_for_current_window
    executor = MockExecutor.new(
      capture_responses: {
        'tmux list-panes -t dev:work -F #{pane_active}	#{pane_id}	#{session_name}	#{window_id}	#{window_index}	#{window_name}	#{pane_index}	#{pane_current_command}	#{pane_current_path}' => mock_result(stdout: "1\t%8\tdev\t@2\t3\twork\t1\tcodex\t/home/mc/ace-t.n1d")
      }
    )
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(session: "dev", window: "work")
    )

    assert_equal [
      {
        active: true,
        pane_id: "%8",
        session: "dev",
        window_id: "@2",
        window_index: 3,
        window_name: "work",
        pane_index: 1,
        target: "dev:work.1",
        command: "codex",
        cwd: "ace-t.n1d"
      }
    ], control.list_panes(session: "dev", window: "work")
  end

  def test_detach_session_runs_detach_client
    executor = MockExecutor.new
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: explicit_resolver(session: "dev")
    )

    session = control.detach_session(session: "dev")

    assert_equal [["tmux", "detach-client", "-s", "dev"]], executor.run_commands
    assert_equal "dev", session
  end

  private

  def fake_process_inspector(command = nil)
    inspector = Object.new
    inspector.define_singleton_method(:find_descendant_command) do |_root_pid, allowed_commands:|
      candidate = command.to_s.strip
      return nil if candidate.empty?

      allowed_commands.include?(candidate) ? candidate : nil
    end
    inspector
  end

  def explicit_resolver(session: nil, window: nil, pane: nil)
    resolver = Object.new
    resolver.define_singleton_method(:resolve_session) do |session: nil|
      Ace::Tmux::Models::RuntimeTarget.new(session: session || "dev", source: "explicit")
    end
    resolver.define_singleton_method(:resolve_window) do |session: nil, window: nil|
      Ace::Tmux::Models::RuntimeTarget.new(session: session || "dev", window: window || "work", source: "explicit")
    end
    resolver.define_singleton_method(:resolve_pane) do |session: nil, window: nil, pane: nil|
      Ace::Tmux::Models::RuntimeTarget.new(
        session: session || "dev",
        window: window || "work",
        pane: pane || pane,
        source: "explicit"
      )
    end
    resolver
  end
end
