# frozen_string_literal: true

require_relative "../../test_helper"

class TmuxCommandBuilderTest < Minitest::Test
  Builder = Ace::Tmux::Atoms::TmuxCommandBuilder

  def test_version
    assert_equal ["tmux", "-V"], Builder.version
  end

  def test_version_custom_binary
    assert_equal ["/usr/local/bin/tmux", "-V"], Builder.version(tmux: "/usr/local/bin/tmux")
  end

  def test_has_session
    assert_equal ["tmux", "has-session", "-t", "dev"], Builder.has_session("dev")
  end

  def test_new_session_minimal
    cmd = Builder.new_session("dev")
    assert_equal ["tmux", "new-session", "-d", "-s", "dev"], cmd
  end

  def test_new_session_with_root
    cmd = Builder.new_session("dev", root: "~/projects")
    assert_includes cmd, "-c"
    assert_includes cmd, File.expand_path("~/projects")
  end

  def test_new_session_with_window_name
    cmd = Builder.new_session("dev", window_name: "editor")
    assert_equal ["tmux", "new-session", "-d", "-s", "dev", "-n", "editor"], cmd
  end

  def test_new_session_with_tmux_options
    cmd = Builder.new_session("dev", tmux_options: "-f ~/.tmux.conf")
    assert_equal ["tmux", "-f", "~/.tmux.conf", "new-session", "-d", "-s", "dev"], cmd
  end

  def test_new_session_with_print_format
    cmd = Builder.new_session("dev", print_format: '#{window_id}')
    assert_equal ["tmux", "new-session", "-d", "-s", "dev", "-P", "-F", '#{window_id}'], cmd
  end

  def test_new_session_without_print_format
    cmd = Builder.new_session("dev")
    refute_includes cmd, "-P"
    refute_includes cmd, "-F"
  end

  def test_new_window
    cmd = Builder.new_window("dev", name: "logs")
    assert_equal ["tmux", "new-window", "-t", "dev:", "-n", "logs"], cmd
  end

  def test_new_window_with_root
    cmd = Builder.new_window("dev", name: "logs", root: "~/logs")
    assert_includes cmd, "-c"
    assert_includes cmd, File.expand_path("~/logs")
  end

  def test_new_window_with_print_format
    cmd = Builder.new_window("dev", name: "logs", print_format: '#{window_id}')
    assert_equal ["tmux", "new-window", "-t", "dev:", "-n", "logs", "-P", "-F", '#{window_id}'], cmd
  end

  def test_new_window_without_print_format
    cmd = Builder.new_window("dev", name: "logs")
    refute_includes cmd, "-P"
    refute_includes cmd, "-F"
  end

  def test_split_window_vertical
    cmd = Builder.split_window("dev:editor")
    assert_equal ["tmux", "split-window", "-t", "dev:editor"], cmd
  end

  def test_split_window_horizontal
    cmd = Builder.split_window("dev:editor", horizontal: true)
    assert_equal ["tmux", "split-window", "-h", "-t", "dev:editor"], cmd
  end

  def test_split_window_with_root
    cmd = Builder.split_window("dev:editor", root: "~/src")
    assert_includes cmd, "-c"
  end

  def test_send_keys
    cmd = Builder.send_keys("dev:editor.0", "vim .")
    assert_equal ["tmux", "send-keys", "-t", "dev:editor.0", "vim .", "Enter"], cmd
  end

  def test_select_layout
    cmd = Builder.select_layout("dev:editor", "main-vertical")
    assert_equal ["tmux", "select-layout", "-t", "dev:editor", "main-vertical"], cmd
  end

  def test_select_window
    cmd = Builder.select_window("dev:editor")
    assert_equal ["tmux", "select-window", "-t", "dev:editor"], cmd
  end

  def test_select_pane
    cmd = Builder.select_pane("dev:editor.1")
    assert_equal ["tmux", "select-pane", "-t", "dev:editor.1"], cmd
  end

  def test_attach_session
    cmd = Builder.attach_session("dev")
    assert_equal ["tmux", "attach-session", "-t", "dev"], cmd
  end

  def test_kill_session
    cmd = Builder.kill_session("dev")
    assert_equal ["tmux", "kill-session", "-t", "dev"], cmd
  end

  def test_list_sessions
    assert_equal ["tmux", "list-sessions"], Builder.list_sessions
  end

  def test_list_sessions_with_format
    fmt = '#S:#{session_name}'
    cmd = Builder.list_sessions(format: fmt)
    assert_equal ["tmux", "list-sessions", "-F", fmt], cmd
  end

  def test_set_window_option
    cmd = Builder.set_window_option("dev:main", "main-pane-width", "40%")
    assert_equal ["tmux", "set-window-option", "-t", "dev:main", "main-pane-width", "40%"], cmd
  end

  def test_set_window_option_with_integer
    cmd = Builder.set_window_option("dev:main", "main-pane-width", 80)
    assert_equal ["tmux", "set-window-option", "-t", "dev:main", "main-pane-width", "80"], cmd
  end

  def test_set_pane_option
    cmd = Builder.set_pane_option("dev:main.0", "remain-on-exit", "on")
    assert_equal ["tmux", "set-option", "-p", "-t", "dev:main.0", "remain-on-exit", "on"], cmd
  end

  def test_display_message
    cmd = Builder.display_message("#S")
    assert_equal ["tmux", "display-message", "-p", "#S"], cmd
  end

  def test_display_message_target
    cmd = Builder.display_message_target("dev:main.0", '#{window_width}x#{window_height}')
    assert_equal ["tmux", "display-message", "-t", "dev:main.0", "-p", '#{window_width}x#{window_height}'], cmd
  end

  def test_list_panes
    cmd = Builder.list_panes("dev:main")
    assert_equal ["tmux", "list-panes", "-t", "dev:main"], cmd
  end

  def test_list_panes_with_format
    cmd = Builder.list_panes("dev:main", format: '#{pane_index}')
    assert_equal ["tmux", "list-panes", "-t", "dev:main", "-F", '#{pane_index}'], cmd
  end

  def test_set_environment_with_value
    cmd = Builder.set_environment("dev", "FOO", value: "bar")
    assert_equal ["tmux", "set-environment", "-t", "dev", "FOO", "bar"], cmd
  end

  def test_set_environment_unset
    cmd = Builder.set_environment("dev", "FOO", unset: true)
    assert_equal ["tmux", "set-environment", "-t", "dev", "-u", "FOO"], cmd
  end

  def test_set_environment_inherit
    cmd = Builder.set_environment("dev", "FOO")
    assert_equal ["tmux", "set-environment", "-t", "dev", "FOO"], cmd
  end

  def test_set_environment_custom_binary
    cmd = Builder.set_environment("dev", "FOO", unset: true, tmux: "/usr/local/bin/tmux")
    assert_equal ["/usr/local/bin/tmux", "set-environment", "-t", "dev", "-u", "FOO"], cmd
  end
end
