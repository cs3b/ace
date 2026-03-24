# frozen_string_literal: true

require_relative "../test_helper"

class SessionBuilderTest < Minitest::Test
  def setup
    @temp_dir = create_temp_preset_dir

    write_preset(@temp_dir, "sessions", "dev", {
      "name" => "dev",
      "root" => "~/projects/app",
      "startup_window" => "editor",
      "windows" => [
        {"name" => "editor", "preset" => "code-editor", "root" => "./src"},
        {"name" => "server", "preset" => "rails-server"},
        {"name" => "logs", "panes" => ["tail -f log/dev.log"]}
      ]
    })

    write_preset(@temp_dir, "windows", "code-editor", {
      "layout" => "main-vertical",
      "panes" => [
        {"preset" => "vim-editor"},
        {"commands" => ["bash"]}
      ]
    })

    write_preset(@temp_dir, "windows", "rails-server", {
      "panes" => [{"commands" => ["bundle exec rails server"]}]
    })

    write_preset(@temp_dir, "panes", "vim-editor", {
      "commands" => ["vim"],
      "focus" => true
    })

    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
    @builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)
  end

  def teardown
    cleanup_temp_dir(@temp_dir)
  end

  def test_build_returns_session_model
    session = @builder.build("dev")

    assert_instance_of Ace::Tmux::Models::Session, session
    assert_equal "dev", session.name
    assert_equal "~/projects/app", session.root
    assert_equal "editor", session.startup_window
  end

  def test_build_resolves_window_presets
    session = @builder.build("dev")

    assert_equal 3, session.windows.length
    editor = session.windows[0]
    assert_equal "editor", editor.name
    assert_equal "main-vertical", editor.layout
    assert_equal "./src", editor.root
  end

  def test_build_resolves_pane_presets_within_windows
    session = @builder.build("dev")

    editor = session.windows[0]
    assert_equal 2, editor.panes.length
    assert_equal ["vim"], editor.panes[0].commands
    assert editor.panes[0].focus?
    assert_equal ["bash"], editor.panes[1].commands
  end

  def test_build_handles_inline_windows
    session = @builder.build("dev")

    logs = session.windows[2]
    assert_equal "logs", logs.name
    assert_equal 1, logs.panes.length
    assert_equal ["tail -f log/dev.log"], logs.panes[0].commands
  end

  def test_build_raises_for_missing_preset
    assert_raises(Ace::Tmux::PresetNotFoundError) do
      @builder.build("nonexistent")
    end
  end

  def test_build_window_returns_window_model
    window = @builder.build_window("code-editor")

    assert_instance_of Ace::Tmux::Models::Window, window
    assert_equal "main-vertical", window.layout
    assert_equal 2, window.panes.length
  end

  def test_build_window_resolves_pane_presets
    window = @builder.build_window("code-editor")

    assert_equal ["vim"], window.panes[0].commands
    assert window.panes[0].focus?
  end

  def test_build_window_raises_for_missing_preset
    assert_raises(Ace::Tmux::PresetNotFoundError) do
      @builder.build_window("nonexistent")
    end
  end

  # --- Nested layout tests ---

  def nested_builder(temp_dir)
    loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: temp_dir,
      start_path: temp_dir
    )
    Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: loader)
  end

  def test_build_nested_window_from_preset
    write_preset(@temp_dir, "windows", "nested-layout", {
      "name" => "dev",
      "direction" => "horizontal",
      "panes" => [
        {"commands" => ["claude"], "size" => "40%"},
        {
          "direction" => "vertical",
          "panes" => [
            {"commands" => ["bash"]},
            {"commands" => ["htop"]}
          ]
        },
        {"commands" => ["nvim ."], "focus" => true}
      ]
    })

    window = nested_builder(@temp_dir).build_window("nested-layout")

    assert window.nested_layout?
    assert_equal "dev", window.name
    assert_nil window.layout  # No flat layout for nested

    # layout_tree structure
    tree = window.layout_tree
    assert tree.container?
    assert_equal :horizontal, tree.direction
    assert_equal 3, tree.children.length

    # First child: leaf with size
    assert tree.children[0].leaf?
    assert_equal ["claude"], tree.children[0].pane.commands
    assert_equal "40%", tree.children[0].size

    # Second child: vertical container
    assert tree.children[1].container?
    assert_equal :vertical, tree.children[1].direction
    assert_equal 2, tree.children[1].children.length
    assert_equal ["bash"], tree.children[1].children[0].pane.commands
    assert_equal ["htop"], tree.children[1].children[1].pane.commands

    # Third child: leaf with focus
    assert tree.children[2].leaf?
    assert_equal ["nvim ."], tree.children[2].pane.commands
    assert tree.children[2].pane.focus?

    # Flat panes still populated (all 4 leaves in DFS order)
    assert_equal 4, window.panes.length
    assert_equal ["claude"], window.panes[0].commands
    assert_equal ["bash"], window.panes[1].commands
    assert_equal ["htop"], window.panes[2].commands
    assert_equal ["nvim ."], window.panes[3].commands
  end

  def test_build_nested_session
    write_preset(@temp_dir, "sessions", "nested-dev", {
      "name" => "nested-dev",
      "windows" => [
        {
          "name" => "main",
          "direction" => "horizontal",
          "panes" => [
            {"commands" => ["claude"]},
            {"commands" => ["bash"]}
          ]
        }
      ]
    })

    session = nested_builder(@temp_dir).build("nested-dev")
    window = session.windows[0]

    assert window.nested_layout?
    assert_equal 2, window.panes.length
  end

  def test_build_flat_window_unchanged
    # Existing flat presets should still work identically
    window = @builder.build_window("code-editor")

    refute window.nested_layout?
    assert_nil window.layout_tree
    assert_equal "main-vertical", window.layout
    assert_equal 2, window.panes.length
  end

  def test_build_nested_detects_nested_panes_without_top_direction
    write_preset(@temp_dir, "windows", "implicit-nested", {
      "name" => "implicit",
      "panes" => [
        {"commands" => ["claude"]},
        {
          "direction" => "vertical",
          "panes" => [
            {"commands" => ["bash"]},
            {"commands" => ["htop"]}
          ]
        }
      ]
    })

    window = nested_builder(@temp_dir).build_window("implicit-nested")
    assert window.nested_layout?
    # Default direction is horizontal when not specified at top level
    assert_equal :horizontal, window.layout_tree.direction
  end

  def test_build_nested_with_pane_presets
    write_preset(@temp_dir, "windows", "nested-with-presets", {
      "name" => "editor",
      "direction" => "horizontal",
      "panes" => [
        {"preset" => "vim-editor", "size" => "50%"},
        {"commands" => ["bash"]}
      ]
    })

    window = nested_builder(@temp_dir).build_window("nested-with-presets")
    assert window.nested_layout?
    assert_equal ["vim"], window.panes[0].commands
    assert window.panes[0].focus?
  end
end
