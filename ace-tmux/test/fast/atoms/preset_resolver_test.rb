# frozen_string_literal: true

require_relative "../../test_helper"

class PresetResolverTest < Minitest::Test
  Resolver = Ace::Tmux::Atoms::PresetResolver

  def test_resolve_preset_without_preset_key
    hash = {"name" => "editor", "layout" => "tiled"}
    result = Resolver.resolve_preset(hash, lookup: ->(_) {})
    assert_equal hash, result
  end

  def test_resolve_preset_merges_base_and_overlay
    base = {"layout" => "main-vertical", "panes" => [{"commands" => ["vim"]}]}
    overlay = {"preset" => "code-editor", "layout" => "tiled"}
    lookup = ->(name) { (name == "code-editor") ? base : nil }

    result = Resolver.resolve_preset(overlay, lookup: lookup)

    assert_equal "tiled", result["layout"]
    assert_equal [{"commands" => ["vim"]}], result["panes"]
    refute result.key?("preset")
  end

  def test_resolve_preset_returns_overlay_without_preset_key_when_not_found
    hash = {"preset" => "missing", "name" => "editor"}
    result = Resolver.resolve_preset(hash, lookup: ->(_) {})

    assert_equal({"name" => "editor"}, result)
    refute result.key?("preset")
  end

  def test_resolve_preset_handles_chained_presets
    base_base = {"layout" => "tiled", "panes" => [{"commands" => ["bash"]}]}
    base = {"preset" => "base-base", "name" => "mid"}
    overlay = {"preset" => "mid", "root" => "~/src"}

    lookup = lambda { |name|
      case name
      when "base-base" then base_base
      when "mid" then base
      end
    }

    result = Resolver.resolve_preset(overlay, lookup: lookup)

    assert_equal "tiled", result["layout"]
    assert_equal "mid", result["name"]
    assert_equal "~/src", result["root"]
  end

  def test_resolve_preset_guards_against_circular_references
    circular = {"preset" => "self"}
    lookup = ->(_) { circular.dup }

    assert_raises(Ace::Tmux::Atoms::CircularPresetError) do
      Resolver.resolve_preset(circular, lookup: lookup)
    end
  end

  def test_normalize_window_hash_passthrough
    hash = {"name" => "editor"}
    assert_equal hash, Resolver.normalize_window(hash)
  end

  def test_normalize_window_string_shorthand
    result = Resolver.normalize_window("tail -f log.txt")
    assert_equal({"panes" => ["tail -f log.txt"]}, result)
  end

  def test_normalize_pane_hash_passthrough
    hash = {"commands" => ["vim"]}
    assert_equal hash, Resolver.normalize_pane(hash)
  end

  def test_normalize_pane_string_shorthand
    result = Resolver.normalize_pane("vim .")
    assert_equal({"commands" => ["vim ."]}, result)
  end

  def test_resolve_session_resolves_window_presets
    window_preset = {"layout" => "main-vertical", "panes" => [{"commands" => ["vim"]}]}
    session_hash = {
      "name" => "dev",
      "windows" => [
        {"preset" => "code-editor", "name" => "editor"}
      ]
    }

    window_lookup = ->(name) { (name == "code-editor") ? window_preset : nil }
    pane_lookup = ->(_) {}

    result = Resolver.resolve_session(session_hash, window_lookup: window_lookup, pane_lookup: pane_lookup)

    assert_equal 1, result["windows"].length
    win = result["windows"][0]
    assert_equal "editor", win["name"]
    assert_equal "main-vertical", win["layout"]
  end

  def test_resolve_session_resolves_pane_presets_within_windows
    pane_preset = {"commands" => ["vim"], "focus" => true}
    session_hash = {
      "name" => "dev",
      "windows" => [
        {
          "name" => "editor",
          "panes" => [{"preset" => "vim-editor"}]
        }
      ]
    }

    window_lookup = ->(_) {}
    pane_lookup = ->(name) { (name == "vim-editor") ? pane_preset : nil }

    result = Resolver.resolve_session(session_hash, window_lookup: window_lookup, pane_lookup: pane_lookup)

    pane = result["windows"][0]["panes"][0]
    assert_equal ["vim"], pane["commands"]
    assert_equal true, pane["focus"]
  end

  def test_resolve_session_handles_string_pane_shorthand
    session_hash = {
      "name" => "dev",
      "windows" => [
        {"name" => "logs", "panes" => ["tail -f log/dev.log"]}
      ]
    }

    result = Resolver.resolve_session(session_hash, window_lookup: ->(_) {}, pane_lookup: ->(_) {})

    pane = result["windows"][0]["panes"][0]
    assert_equal ["tail -f log/dev.log"], pane["commands"]
  end

  def test_resolve_window_resolves_pane_presets
    pane_preset = {"commands" => ["vim"], "focus" => true}
    window_hash = {
      "name" => "editor",
      "layout" => "main-vertical",
      "panes" => [{"preset" => "vim-editor"}, {"commands" => ["bash"]}]
    }

    pane_lookup = ->(name) { (name == "vim-editor") ? pane_preset : nil }

    result = Resolver.resolve_window(window_hash, pane_lookup: pane_lookup)

    assert_equal 2, result["panes"].length
    assert_equal ["vim"], result["panes"][0]["commands"]
    assert_equal true, result["panes"][0]["focus"]
    assert_equal ["bash"], result["panes"][1]["commands"]
  end

  def test_resolve_window_panes_with_nested_containers
    pane_preset = {"commands" => ["vim"], "focus" => true}
    window_hash = {
      "name" => "dev",
      "direction" => "horizontal",
      "panes" => [
        {"preset" => "vim-editor"},
        {
          "direction" => "vertical",
          "panes" => [
            {"commands" => ["bash"]},
            {"preset" => "vim-editor"}
          ]
        }
      ]
    }

    pane_lookup = ->(name) { (name == "vim-editor") ? pane_preset : nil }

    result = Resolver.resolve_window(window_hash, pane_lookup: pane_lookup)

    # Top-level leaf resolved
    assert_equal ["vim"], result["panes"][0]["commands"]
    assert_equal true, result["panes"][0]["focus"]

    # Container preserved
    container = result["panes"][1]
    assert_equal "vertical", container["direction"]

    # Nested leaves resolved
    assert_equal ["bash"], container["panes"][0]["commands"]
    assert_equal ["vim"], container["panes"][1]["commands"]
    assert_equal true, container["panes"][1]["focus"]
  end

  def test_resolve_session_with_nested_containers
    pane_preset = {"commands" => ["vim"], "focus" => true}
    session_hash = {
      "name" => "dev",
      "windows" => [
        {
          "name" => "main",
          "direction" => "horizontal",
          "panes" => [
            {"preset" => "vim-editor"},
            {"direction" => "vertical", "panes" => [{"commands" => ["bash"]}]}
          ]
        }
      ]
    }

    window_lookup = ->(_) {}
    pane_lookup = ->(name) { (name == "vim-editor") ? pane_preset : nil }

    result = Resolver.resolve_session(session_hash, window_lookup: window_lookup, pane_lookup: pane_lookup)

    win = result["windows"][0]
    assert_equal ["vim"], win["panes"][0]["commands"]
    assert_equal "vertical", win["panes"][1]["direction"]
  end
end
