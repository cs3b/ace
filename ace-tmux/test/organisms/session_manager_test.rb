# frozen_string_literal: true

require_relative "../test_helper"

class SessionManagerTest < Minitest::Test
  def setup
    @temp_dir = create_temp_preset_dir

    write_preset(@temp_dir, "sessions", "dev", {
      "name" => "dev",
      "root" => "~/projects/app",
      "startup_window" => "editor",
      "windows" => [
        {"name" => "editor", "panes" => [{"commands" => ["vim"]}]},
        {"name" => "server", "panes" => [{"commands" => ["rails s"]}]}
      ]
    })

    write_preset(@temp_dir, "sessions", "with-options", {
      "name" => "opts",
      "windows" => [
        {
          "name" => "main",
          "layout" => "main-vertical",
          "options" => {"main-pane-width" => "40%"},
          "panes" => [
            {"commands" => ["claude"]},
            {"commands" => [], "options" => {"remain-on-exit" => "on"}},
            {"commands" => ["nvim ."], "focus" => true}
          ]
        }
      ]
    })

    write_preset(@temp_dir, "sessions", "with-hooks", {
      "name" => "hooked",
      "pre_window" => "nvm use 18",
      "windows" => [
        {"name" => "shell", "panes" => [{"commands" => ["bash"]}]}
      ]
    })

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)

    # Mock executor: has-session fails (session doesn't exist),
    # new-session/new-window return window IDs via capture
    @executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        "tmux has-session -t dev" => mock_result(success: false, exit_code: 1),
        "tmux has-session -t opts" => mock_result(success: false, exit_code: 1),
        "tmux has-session -t hooked" => mock_result(success: false, exit_code: 1),
        :default => mock_result(stdout: "@0")
      }
    )

    @manager = Ace::Tmux::Organisms::SessionManager.new(
      executor: @executor,
      session_builder: builder
    )
  end

  def teardown
    cleanup_temp_dir(@temp_dir)
  end

  def test_start_creates_session_detached
    @manager.start("dev", detach: true)

    # Should create session (via capture to get window ID)
    new_session_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-session") }
    assert new_session_cmd, "Expected new-session command"
    assert_includes new_session_cmd, "-s"
    assert_includes new_session_cmd, "dev"
    assert_includes new_session_cmd, "-d"
  end

  def test_start_creates_additional_windows
    @manager.start("dev", detach: true)

    # new-window now uses capture to get window ID
    new_window_cmds = @executor.captured_commands.select { |cmd| cmd.include?("new-window") }
    assert_equal 1, new_window_cmds.length
    assert_includes new_window_cmds[0], "server"
  end

  def test_start_sends_pane_commands
    @manager.start("dev", detach: true)

    send_keys_cmds = @executor.run_commands.select { |cmd| cmd.include?("send-keys") }
    vim_cmd = send_keys_cmds.find { |cmd| cmd.include?("vim") }
    rails_cmd = send_keys_cmds.find { |cmd| cmd.include?("rails s") }

    assert vim_cmd, "Expected send-keys with vim"
    assert rails_cmd, "Expected send-keys with rails s"
  end

  def test_start_selects_startup_window
    @manager.start("dev", detach: true)

    select_cmds = @executor.run_commands.select { |cmd| cmd.include?("select-window") }
    assert select_cmds.any? { |cmd| cmd.include?("dev:editor") }
  end

  def test_start_attaches_when_not_detached
    @manager.start("dev", detach: false)

    assert_equal 1, @executor.exec_commands.length
    attach_cmd = @executor.exec_commands[0]
    assert_includes attach_cmd, "attach-session"
    assert_includes attach_cmd, "dev"
  end

  def test_start_skips_attach_when_detached
    @manager.start("dev", detach: true)

    assert_empty @executor.exec_commands
  end

  def test_start_sends_pre_window_commands
    @manager.start("with-hooks", detach: true)

    send_keys_cmds = @executor.run_commands.select { |cmd| cmd.include?("send-keys") }
    nvm_cmd = send_keys_cmds.find { |cmd| cmd.include?("nvm use 18") }
    assert nvm_cmd, "Expected pre_window command"
  end

  def test_start_applies_window_options
    @manager.start("with-options", detach: true)

    option_cmds = @executor.run_commands.select { |cmd| cmd.include?("set-window-option") }
    assert_equal 1, option_cmds.length
    assert_includes option_cmds[0], "main-pane-width"
    assert_includes option_cmds[0], "40%"
  end

  def test_start_applies_pane_options
    @manager.start("with-options", detach: true)

    option_cmds = @executor.run_commands.select { |cmd| cmd.include?("set-option") && cmd.include?("-p") }
    assert_equal 1, option_cmds.length
    assert_includes option_cmds[0], "remain-on-exit"
    assert_includes option_cmds[0], "on"
  end

  def test_start_existing_session_attaches
    executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        "tmux has-session -t dev" => mock_result(success: true)
      }
    )

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)
    manager = Ace::Tmux::Organisms::SessionManager.new(
      executor: executor,
      session_builder: builder
    )

    manager.start("dev", detach: false)

    # Should not create session, just attach
    new_session_cmds = executor.run_commands.select { |cmd| cmd.include?("new-session") }
    assert_empty new_session_cmds

    assert_equal 1, executor.exec_commands.length
  end

  def test_start_force_kills_and_recreates
    executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        "tmux has-session -t dev" => mock_result(success: true),
        :default => mock_result(stdout: "@0")
      }
    )

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)
    manager = Ace::Tmux::Organisms::SessionManager.new(
      executor: executor,
      session_builder: builder
    )

    manager.start("dev", force: true, detach: true)

    kill_cmds = executor.run_commands.select { |cmd| cmd.include?("kill-session") }
    assert_equal 1, kill_cmds.length

    # new-session now uses capture
    new_session_cmds = executor.captured_commands.select { |cmd| cmd.include?("new-session") }
    assert_equal 1, new_session_cmds.length
  end

  def test_flat_panes_send_keys_after_select_layout
    @manager.start("with-options", detach: true)

    commands = @executor.run_commands
    layout_idx = commands.index { |cmd| cmd.include?("select-layout") }
    assert layout_idx, "Expected select-layout command"

    send_keys_indices = commands.each_with_index.filter_map { |cmd, i| i if cmd.include?("send-keys") }
    assert send_keys_indices.any?, "Expected send-keys commands"

    send_keys_indices.each do |idx|
      assert idx > layout_idx, "send-keys at index #{idx} should come after select-layout at index #{layout_idx}"
    end
  end

  # --- Nested layout tests ---

  def test_start_nested_layout_creates_flat_splits
    write_preset(@temp_dir, "sessions", "nested", {
      "name" => "nested",
      "windows" => [
        {
          "name" => "main",
          "direction" => "horizontal",
          "panes" => [
            {"commands" => ["claude"], "size" => "40%"},
            {"direction" => "vertical", "panes" => [
              {"commands" => ["bash"]},
              {"commands" => ["htop"]}
            ]},
            {"commands" => ["nvim ."], "focus" => true}
          ]
        }
      ]
    })

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)

    executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        "tmux has-session -t nested" => mock_result(success: false, exit_code: 1),
        # list-panes returns 4 pane indices
        "tmux list-panes -t @0 -F \#{pane_index}" => mock_result(stdout: "0\n1\n2\n3"),
        # display-message returns window dimensions
        "tmux display-message -t @0.0 -p \#{window_width}x\#{window_height}" => mock_result(stdout: "200x50"),
        :default => mock_result(stdout: "@0")
      }
    )

    manager = Ace::Tmux::Organisms::SessionManager.new(
      executor: executor,
      session_builder: builder
    )

    manager.start("nested", detach: true)

    # Should create 3 split-window commands (4 panes - 1 existing)
    split_cmds = executor.run_commands.select { |cmd| cmd.include?("split-window") }
    assert_equal 3, split_cmds.length

    # Should apply a custom layout via select-layout
    layout_cmds = executor.run_commands.select { |cmd| cmd.include?("select-layout") }
    assert_equal 1, layout_cmds.length
    layout_string = layout_cmds[0].last
    # Layout string should have checksum prefix and contain nested brackets
    assert_match(/\A[0-9a-f]{4},/, layout_string)

    # Should send commands to all 4 panes
    send_keys_cmds = executor.run_commands.select { |cmd| cmd.include?("send-keys") }
    assert send_keys_cmds.any? { |cmd| cmd.include?("claude") }
    assert send_keys_cmds.any? { |cmd| cmd.include?("bash") }
    assert send_keys_cmds.any? { |cmd| cmd.include?("htop") }
    assert send_keys_cmds.any? { |cmd| cmd.include?("nvim .") }

    # Should focus the pane with focus: true (nvim)
    focus_cmds = executor.run_commands.select { |cmd| cmd.include?("select-pane") }
    assert_equal 1, focus_cmds.length
  end

  def test_start_nested_layout_single_leaf_still_works
    write_preset(@temp_dir, "sessions", "single-nested", {
      "name" => "single-nested",
      "windows" => [
        {
          "name" => "main",
          "direction" => "horizontal",
          "panes" => [
            {"commands" => ["bash"]}
          ]
        }
      ]
    })

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)

    executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        "tmux has-session -t single-nested" => mock_result(success: false, exit_code: 1),
        "tmux list-panes -t @0 -F \#{pane_index}" => mock_result(stdout: "0"),
        "tmux display-message -t @0.0 -p \#{window_width}x\#{window_height}" => mock_result(stdout: "200x50"),
        :default => mock_result(stdout: "@0")
      }
    )

    manager = Ace::Tmux::Organisms::SessionManager.new(
      executor: executor,
      session_builder: builder
    )

    manager.start("single-nested", detach: true)

    # No splits needed for single pane
    split_cmds = executor.run_commands.select { |cmd| cmd.include?("split-window") }
    assert_equal 0, split_cmds.length

    # Should still apply layout and send commands
    send_keys_cmds = executor.run_commands.select { |cmd| cmd.include?("send-keys") }
    assert send_keys_cmds.any? { |cmd| cmd.include?("bash") }
  end

  def test_start_with_root_override
    @manager.start("dev", detach: true, root: "/tmp/override")

    new_session_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-session") }
    assert new_session_cmd, "Expected new-session command"
    # The root override should be passed through to the session creation
    assert_includes new_session_cmd.join(" "), "/tmp/override"
  end

  def test_start_with_root_override_names_first_window_from_basename
    @manager.start("dev", detach: true, root: "/home/mc/my-project")

    new_session_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-session") }
    assert new_session_cmd, "Expected new-session command"
    # First window should be named after the root directory basename, not the preset window name
    cmd_str = new_session_cmd.join(" ")
    assert_includes cmd_str, "my-project"
    refute_includes cmd_str, "-n editor", "Should not use preset window name when root override provided"
  end

  def test_start_without_root_names_first_window_from_preset_root
    @manager.start("dev", detach: true)

    new_session_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-session") }
    assert new_session_cmd, "Expected new-session command"
    # Without root override, should use basename of preset's root (~/projects/app → "app")
    cmd_str = new_session_cmd.join(" ")
    assert_includes cmd_str, "app"
    refute_includes cmd_str, "-n editor", "Should not use preset window name"
  end

  def test_start_without_root_or_preset_root_uses_cwd
    write_preset(@temp_dir, "sessions", "no-root", {
      "name" => "no-root",
      "windows" => [
        {"name" => "shell", "panes" => [{"commands" => ["bash"]}]}
      ]
    })

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)

    executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        "tmux has-session -t no-root" => mock_result(success: false, exit_code: 1),
        :default => mock_result(stdout: "@0")
      }
    )

    manager = Ace::Tmux::Organisms::SessionManager.new(
      executor: executor,
      session_builder: builder
    )

    manager.start("no-root", detach: true)

    new_session_cmd = executor.captured_commands.find { |cmd| cmd.include?("new-session") }
    assert new_session_cmd, "Expected new-session command"
    # Without root override or preset root, should use CWD basename
    cmd_str = new_session_cmd.join(" ")
    expected_name = File.basename(Dir.pwd)
    assert_includes cmd_str, expected_name,
      "First window should be named '#{expected_name}' (CWD basename), got: #{cmd_str}"
  end

  def test_start_without_root_uses_preset_root
    @manager.start("dev", detach: true)

    new_session_cmd = @executor.captured_commands.find { |cmd| cmd.include?("new-session") }
    assert new_session_cmd, "Expected new-session command"
    assert_includes new_session_cmd.join(" "), File.expand_path("~/projects/app")
  end

  def test_start_cleans_bundler_env_vars_from_session
    @manager.start("dev", detach: true)

    set_env_cmds = @executor.run_commands.select { |cmd| cmd.include?("set-environment") }
    assert_equal 4, set_env_cmds.length

    expected_vars = %w[BUNDLE_GEMFILE BUNDLE_BIN_PATH RUBYOPT RUBYLIB]
    expected_vars.each do |var|
      cmd = set_env_cmds.find { |c| c.include?(var) }
      assert cmd, "Expected set-environment -u for #{var}"
      assert_includes cmd, "-u"
    end

    # Verify clean_environment runs before setup_windows
    # The second window's send-keys ("rails s") comes from setup_windows
    all_cmds = @executor.run_commands
    last_set_env_idx = all_cmds.rindex { |cmd| cmd.include?("set-environment") }
    rails_send_keys_idx = all_cmds.index { |cmd| cmd.include?("send-keys") && cmd.include?("rails s") }
    assert last_set_env_idx < rails_send_keys_idx,
      "set-environment should run before setup_windows (rails s send-keys)"
  end

  def test_start_nested_layout_respects_per_leaf_root
    write_preset(@temp_dir, "sessions", "nested-roots", {
      "name" => "nested-roots",
      "root" => "~/projects",
      "windows" => [
        {
          "name" => "main",
          "direction" => "horizontal",
          "panes" => [
            {"commands" => ["vim"], "root" => "~/custom-root"},
            {"commands" => ["bash"]},
            {"commands" => ["htop"], "root" => "~/logs"}
          ]
        }
      ]
    })

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)

    executor = TmuxTestHelper::MockExecutor.new(
      capture_responses: {
        "tmux has-session -t nested-roots" => mock_result(success: false, exit_code: 1),
        "tmux list-panes -t @0 -F \#{pane_index}" => mock_result(stdout: "0\n1\n2"),
        "tmux display-message -t @0.0 -p \#{window_width}x\#{window_height}" => mock_result(stdout: "200x50"),
        :default => mock_result(stdout: "@0")
      }
    )

    manager = Ace::Tmux::Organisms::SessionManager.new(
      executor: executor,
      session_builder: builder
    )

    manager.start("nested-roots", detach: true)

    # Second split should use session root (no pane root), third should use ~/logs
    split_cmds = executor.run_commands.select { |cmd| cmd.include?("split-window") }
    assert_equal 2, split_cmds.length
    # Second pane has no custom root -> falls back to session root (expanded)
    assert_includes split_cmds[0].join(" "), File.expand_path("~/projects")
    # Third pane has custom root ~/logs (expanded)
    assert_includes split_cmds[1].join(" "), File.expand_path("~/logs")

    # First leaf has custom root -> should cd to it
    send_keys_cmds = executor.run_commands.select { |cmd| cmd.include?("send-keys") }
    cd_cmd = send_keys_cmds.find { |cmd| cmd.include?("cd ~/custom-root") }
    assert cd_cmd, "Expected cd to first leaf's custom root"
  end
end
