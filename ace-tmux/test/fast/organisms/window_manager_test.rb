# frozen_string_literal: true

require_relative "../../test_helper"

class WindowManagerTest < Minitest::Test
  def setup
    @temp_dir = create_temp_preset_dir

    write_preset(@temp_dir, "windows", "code-editor", {
      "name" => "code-editor",
      "layout" => "main-vertical",
      "panes" => [
        {"commands" => ["vim"], "focus" => true},
        {"commands" => ["bash"]}
      ]
    })

    write_preset(@temp_dir, "windows", "with-pre-window", {
      "name" => "dev-window",
      "pre_window" => "nvm use 18",
      "panes" => [{"commands" => ["node"]}]
    })

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)

    @executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        "tmux display-message -p #S" => mock_result(stdout: "my-session"),
        :default => mock_result(stdout: "@1")
      }
    )

    @manager = Ace::Tmux::Organisms::WindowManager.new(
      executor: @executor,
      session_builder: builder
    )
  end

  def teardown
    cleanup_temp_dir(@temp_dir)
  end

  def test_add_window_creates_window_in_specified_session
    @manager.add_window("code-editor", session: "dev")

    new_window_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-window") }
    assert new_window_cmd
    assert_includes new_window_cmd, "dev:"
    assert_includes new_window_cmd, "code-editor"
  end

  def test_add_window_detects_current_session
    # Simulate being inside tmux
    ENV["TMUX"] = "/tmp/tmux-1000/default,12345,0"

    @manager.add_window("code-editor")

    new_window_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-window") }
    assert new_window_cmd
    assert_includes new_window_cmd, "my-session:"
  ensure
    ENV.delete("TMUX")
  end

  def test_add_window_raises_when_not_in_tmux
    ENV.delete("TMUX")

    assert_raises(Ace::Tmux::NotInTmuxError) do
      @manager.add_window("code-editor")
    end
  end

  def test_add_window_creates_panes
    @manager.add_window("code-editor", session: "dev")

    split_cmds = @executor.run_commands.select { |cmd| cmd.include?("split-window") }
    assert_equal 1, split_cmds.length  # Second pane needs a split
  end

  def test_add_window_sends_pane_commands
    @manager.add_window("code-editor", session: "dev")

    send_keys_cmds = @executor.run_commands.select { |cmd| cmd.include?("send-keys") }
    vim_cmd = send_keys_cmds.find { |cmd| cmd.include?("vim") }
    bash_cmd = send_keys_cmds.find { |cmd| cmd.include?("bash") }

    assert vim_cmd, "Expected send-keys with vim"
    assert bash_cmd, "Expected send-keys with bash"
  end

  def test_add_window_applies_layout
    @manager.add_window("code-editor", session: "dev")

    layout_cmds = @executor.run_commands.select { |cmd| cmd.include?("select-layout") }
    assert_equal 1, layout_cmds.length
    assert_includes layout_cmds[0], "main-vertical"
  end

  def test_add_window_focuses_pane
    @manager.add_window("code-editor", session: "dev")

    focus_cmds = @executor.run_commands.select { |cmd| cmd.include?("select-pane") }
    assert_equal 1, focus_cmds.length
  end

  def test_add_window_sends_pre_window_commands
    @manager.add_window("with-pre-window", session: "dev")

    send_keys_cmds = @executor.run_commands.select { |cmd| cmd.include?("send-keys") }
    nvm_cmd = send_keys_cmds.find { |cmd| cmd.include?("nvm use 18") }
    assert nvm_cmd, "Expected pre_window command"
  end

  def test_flat_panes_send_keys_after_select_layout
    @manager.add_window("code-editor", session: "dev")

    commands = @executor.run_commands
    layout_idx = commands.index { |cmd| cmd.include?("select-layout") }
    assert layout_idx, "Expected select-layout command"

    send_keys_indices = commands.each_with_index.filter_map { |cmd, i| i if cmd.include?("send-keys") }
    assert send_keys_indices.any?, "Expected send-keys commands"

    send_keys_indices.each do |idx|
      assert idx > layout_idx, "send-keys at index #{idx} should come after select-layout at index #{layout_idx}"
    end
  end

  # --- Window naming tests ---

  def test_add_window_name_from_root
    result = @manager.add_window("code-editor", session: "dev", root: "/home/mc/ace-task.240.02")

    new_window_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-window") }
    assert_includes new_window_cmd, "ace-task.240.02"
    assert_equal "ace-task.240.02", result
  end

  def test_add_window_name_from_explicit_flag
    result = @manager.add_window("code-editor", session: "dev", name: "custom-name")

    new_window_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-window") }
    assert_includes new_window_cmd, "custom-name"
    assert_equal "custom-name", result
  end

  def test_add_window_name_explicit_overrides_root
    result = @manager.add_window("code-editor", session: "dev", root: "/home/mc/project", name: "my-win")

    new_window_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-window") }
    assert_includes new_window_cmd, "my-win"
    refute new_window_cmd.include?("project"), "Should use explicit name, not root basename"
    assert_equal "my-win", result
  end

  def test_add_window_name_falls_back_to_preset
    result = @manager.add_window("code-editor", session: "dev")

    new_window_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-window") }
    assert_includes new_window_cmd, "code-editor"
    assert_equal "code-editor", result
  end

  def test_add_window_uses_window_id_for_targeting
    @manager.add_window("code-editor", session: "dev")

    # Pane commands should target the window ID, not a name-based target
    send_keys_cmds = @executor.run_commands.select { |cmd| cmd.include?("send-keys") }
    send_keys_cmds.each do |cmd|
      target_idx = cmd.index("-t")
      target = cmd[target_idx + 1]
      assert_match(/\A@\d+/, target, "Expected window ID target, got: #{target}")
    end
  end

  # --- Nested layout tests ---

  def test_add_window_nested_layout
    write_preset(@temp_dir, "windows", "nested-editor", {
      "name" => "nested-editor",
      "direction" => "horizontal",
      "panes" => [
        {"commands" => ["claude"], "size" => "40%"},
        {"direction" => "vertical", "panes" => [
          {"commands" => ["bash"]},
          {"commands" => ["htop"]}
        ]},
        {"commands" => ["nvim ."], "focus" => true}
      ]
    })

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)

    executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        "tmux display-message -p #S" => mock_result(stdout: "my-session"),
        :default => mock_result(stdout: "@1"),
        "tmux list-panes -t @1 -F \#{pane_index}" => mock_result(stdout: "0\n1\n2\n3"),
        "tmux display-message -t @1.0 -p \#{window_width}x\#{window_height}" => mock_result(stdout: "200x50")
      }
    )

    manager = Ace::Tmux::Organisms::WindowManager.new(
      executor: executor,
      session_builder: builder
    )

    manager.add_window("nested-editor", session: "dev")

    # Should create window via capture (not run)
    new_window_cmds = executor.captured_commands.select { |cmd| cmd.include?("new-window") }
    assert_equal 1, new_window_cmds.length

    # Should create 3 flat splits (4 leaves - 1)
    split_cmds = executor.run_commands.select { |cmd| cmd.include?("split-window") }
    assert_equal 3, split_cmds.length

    # Should apply custom layout
    layout_cmds = executor.run_commands.select { |cmd| cmd.include?("select-layout") }
    assert_equal 1, layout_cmds.length
    layout_string = layout_cmds[0].last
    assert_match(/\A[0-9a-f]{4},/, layout_string)

    # Should send commands to all 4 panes
    send_keys_cmds = executor.run_commands.select { |cmd| cmd.include?("send-keys") }
    assert send_keys_cmds.any? { |cmd| cmd.include?("claude") }
    assert send_keys_cmds.any? { |cmd| cmd.include?("bash") }
    assert send_keys_cmds.any? { |cmd| cmd.include?("htop") }
    assert send_keys_cmds.any? { |cmd| cmd.include?("nvim .") }

    # Should focus the nvim pane
    focus_cmds = executor.run_commands.select { |cmd| cmd.include?("select-pane") }
    assert_equal 1, focus_cmds.length
  end

  def test_add_window_failure_includes_stderr_in_error
    executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        default: mock_result(stdout: "", stderr: "session not found: bad-session\n", success: false, exit_code: 1)
      }
    )

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)
    manager = Ace::Tmux::Organisms::WindowManager.new(
      executor: executor,
      session_builder: builder
    )

    error = assert_raises(RuntimeError) do
      manager.add_window("code-editor", session: "bad-session")
    end

    assert_includes error.message, "Failed to create window"
    assert_includes error.message, "session not found"
  end

  def test_add_window_flat_layout_unchanged
    # Existing flat presets should work identically
    @manager.add_window("code-editor", session: "dev")

    # Should use select-layout with named layout (not custom string)
    layout_cmds = @executor.run_commands.select { |cmd| cmd.include?("select-layout") }
    assert_equal 1, layout_cmds.length
    assert_includes layout_cmds[0], "main-vertical"
  end

  def test_add_window_nested_layout_respects_per_leaf_root
    write_preset(@temp_dir, "windows", "nested-roots", {
      "name" => "nested-roots",
      "root" => "~/projects",
      "direction" => "horizontal",
      "panes" => [
        {"commands" => ["vim"], "root" => "~/custom-root"},
        {"commands" => ["bash"]},
        {"commands" => ["htop"], "root" => "~/logs"}
      ]
    })

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)

    executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        "tmux display-message -p #S" => mock_result(stdout: "my-session"),
        :default => mock_result(stdout: "@1"),
        "tmux list-panes -t @1 -F \#{pane_index}" => mock_result(stdout: "0\n1\n2"),
        "tmux display-message -t @1.0 -p \#{window_width}x\#{window_height}" => mock_result(stdout: "200x50")
      }
    )

    manager = Ace::Tmux::Organisms::WindowManager.new(
      executor: executor,
      session_builder: builder
    )

    manager.add_window("nested-roots", session: "dev")

    # Second split should use window root (no pane root), third should use ~/logs
    split_cmds = executor.run_commands.select { |cmd| cmd.include?("split-window") }
    assert_equal 2, split_cmds.length
    assert_includes split_cmds[0].join(" "), File.expand_path("~/projects")
    assert_includes split_cmds[1].join(" "), File.expand_path("~/logs")

    # First leaf has custom root -> should cd to it
    send_keys_cmds = executor.run_commands.select { |cmd| cmd.include?("send-keys") }
    cd_cmd = send_keys_cmds.find { |cmd| cmd.include?("cd ~/custom-root") }
    assert cd_cmd, "Expected cd to first leaf's custom root"
  end
end
