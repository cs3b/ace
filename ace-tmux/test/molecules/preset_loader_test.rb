# frozen_string_literal: true

require_relative "../test_helper"

class PresetLoaderTest < Minitest::Test
  def setup
    @temp_dir = create_temp_preset_dir

    # Write test presets
    write_preset(@temp_dir, "sessions", "dev", {
      "name" => "dev",
      "root" => "~/projects",
      "windows" => [{"name" => "editor"}]
    })

    write_preset(@temp_dir, "windows", "code-editor", {
      "name" => "code-editor",
      "layout" => "main-vertical",
      "panes" => [{"commands" => ["vim"]}]
    })

    write_preset(@temp_dir, "panes", "vim-editor", {
      "commands" => ["vim"],
      "focus" => true
    })

    @loader = Ace::Tmux::Molecules::PresetLoader.new(
      gem_root: @temp_dir,
      start_path: @temp_dir
    )
  end

  def teardown
    cleanup_temp_dir(@temp_dir)
  end

  def test_load_session_preset
    result = @loader.load("sessions", "dev")

    assert_equal "dev", result["name"]
    assert_equal "~/projects", result["root"]
  end

  def test_load_window_preset
    result = @loader.load("windows", "code-editor")

    assert_equal "code-editor", result["name"]
    assert_equal "main-vertical", result["layout"]
  end

  def test_load_pane_preset
    result = @loader.load("panes", "vim-editor")

    assert_equal ["vim"], result["commands"]
    assert_equal true, result["focus"]
  end

  def test_load_returns_nil_for_missing_preset
    result = @loader.load("sessions", "nonexistent")
    assert_nil result
  end

  def test_list_session_presets
    presets = @loader.list("sessions")
    assert_includes presets, "dev"
  end

  def test_list_window_presets
    presets = @loader.list("windows")
    assert_includes presets, "code-editor"
  end

  def test_list_pane_presets
    presets = @loader.list("panes")
    assert_includes presets, "vim-editor"
  end

  def test_list_all
    all = @loader.list_all

    assert all.key?("sessions")
    assert all.key?("windows")
    assert all.key?("panes")
    assert_includes all["sessions"], "dev"
    assert_includes all["windows"], "code-editor"
    assert_includes all["panes"], "vim-editor"
  end

  def test_to_lookup_returns_callable
    lookup = @loader.to_lookup("windows")
    assert_respond_to lookup, :call

    result = lookup.call("code-editor")
    assert_equal "code-editor", result["name"]
  end

  def test_to_lookup_returns_nil_for_missing
    lookup = @loader.to_lookup("windows")
    assert_nil lookup.call("nonexistent")
  end
end
