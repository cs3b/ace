# frozen_string_literal: true

require_relative "../../test_helper"

class ListCommandTest < Minitest::Test
  class FakeControlSurface
    attr_reader :pane_calls, :window_calls, :session_calls

    def initialize
      @pane_calls = []
      @window_calls = []
      @session_calls = 0
    end

    def list_panes(session: nil, window: nil, all_panes: false)
      @pane_calls << {session: session, window: window, all_panes: all_panes}
      [
        {
          active: true,
          pane_id: "%8",
          target: "default:work.1",
          command: "codex",
          cwd: "ace-t.n1d"
        }
      ]
    end

    def list_windows(session: nil)
      @window_calls << {session: session}
      [
        {
          active: true,
          id: "@2",
          session: session || "default",
          index: 3,
          name: "work",
          pane_count: 4
        }
      ]
    end

    def list_sessions
      @session_calls += 1
      [
        {
          session: "default",
          attached_clients: 1,
          window_count: 3
        }
      ]
    end
  end

  def test_default_lists_panes_in_current_window
    fake = FakeControlSurface.new
    command = Ace::Tmux::CLI::Commands::List.new

    output = Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      capture_io { command.call }[0]
    end

    assert_equal [{session: nil, window: nil, all_panes: false}], fake.pane_calls
    assert_includes output, "PANE"
    assert_includes output, "%8"
    assert_includes output, "default:work.1"
  end

  def test_all_panes_scope_passes_session_wide_flag
    fake = FakeControlSurface.new
    command = Ace::Tmux::CLI::Commands::List.new

    Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      capture_io { command.call(session: "dev", all_panes: true) }
    end

    assert_equal [{session: "dev", window: nil, all_panes: true}], fake.pane_calls
  end

  def test_windows_scope_lists_windows_for_session
    fake = FakeControlSurface.new
    command = Ace::Tmux::CLI::Commands::List.new

    output = Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      capture_io { command.call(session: "dev", windows: true) }[0]
    end

    assert_equal [{session: "dev"}], fake.window_calls
    assert_includes output, "@2"
    assert_includes output, "dev:3"
  end

  def test_sessions_scope_lists_sessions
    fake = FakeControlSurface.new
    command = Ace::Tmux::CLI::Commands::List.new

    output = Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      capture_io { command.call(sessions: true) }[0]
    end

    assert_equal 1, fake.session_calls
    assert_includes output, "SESSION"
    assert_includes output, "default"
  end

  def test_rejects_multiple_scope_flags
    command = Ace::Tmux::CLI::Commands::List.new

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(windows: true, sessions: true)
    end

    assert_includes error.message, "Use only one"
  end

  def test_rejects_window_flag_with_sessions_scope
    command = Ace::Tmux::CLI::Commands::List.new

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(sessions: true, window: "work")
    end

    assert_includes error.message, "--sessions does not accept"
  end
end
