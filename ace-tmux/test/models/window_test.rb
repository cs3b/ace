# frozen_string_literal: true

require_relative "../test_helper"

class WindowModelTest < Minitest::Test
  def test_default_initialization
    window = Ace::Tmux::Models::Window.new

    assert_nil window.name
    assert_nil window.layout
    assert_nil window.root
    assert_equal [], window.panes
    assert_nil window.pre_window
    assert_equal false, window.focus
  end

  def test_initialization_with_values
    pane = Ace::Tmux::Models::Pane.new(commands: ["vim"])
    window = Ace::Tmux::Models::Window.new(
      name: "editor",
      layout: "main-vertical",
      root: "~/src",
      panes: [pane],
      pre_window: "nvm use default",
      focus: true
    )

    assert_equal "editor", window.name
    assert_equal "main-vertical", window.layout
    assert_equal "~/src", window.root
    assert_equal 1, window.panes.length
    assert_equal "nvm use default", window.pre_window
    assert window.focus?
  end

  def test_focus_predicate
    assert Ace::Tmux::Models::Window.new(focus: true).focus?
    refute Ace::Tmux::Models::Window.new(focus: false).focus?
    refute Ace::Tmux::Models::Window.new.focus?
  end

  def test_to_h
    pane = Ace::Tmux::Models::Pane.new(commands: ["vim"])
    window = Ace::Tmux::Models::Window.new(
      name: "editor",
      layout: "main-vertical",
      panes: [pane]
    )

    hash = window.to_h
    assert_equal "editor", hash["name"]
    assert_equal "main-vertical", hash["layout"]
    assert_equal 1, hash["panes"].length
    assert_equal ["vim"], hash["panes"][0]["commands"]
  end

  def test_to_h_omits_nil_optional_fields
    window = Ace::Tmux::Models::Window.new(name: "shell")
    hash = window.to_h

    assert_equal "shell", hash["name"]
    refute hash.key?("layout")
    refute hash.key?("root")
    refute hash.key?("pre_window")
    refute hash.key?("options")
  end

  def test_options_default_empty
    window = Ace::Tmux::Models::Window.new
    assert_equal({}, window.options)
  end

  def test_options_passthrough
    opts = {"main-pane-width" => "40%"}
    window = Ace::Tmux::Models::Window.new(options: opts)
    assert_equal opts, window.options
  end

  def test_to_h_includes_options
    opts = {"main-pane-width" => "40%"}
    window = Ace::Tmux::Models::Window.new(name: "main", options: opts)
    assert_equal opts, window.to_h["options"]
  end

  def test_nested_layout_default_nil
    window = Ace::Tmux::Models::Window.new
    assert_nil window.layout_tree
    refute window.nested_layout?
  end

  def test_nested_layout_with_tree
    pane = Ace::Tmux::Models::Pane.new(commands: ["vim"])
    tree = Ace::Tmux::Models::LayoutNode.new(
      direction: :horizontal,
      children: [Ace::Tmux::Models::LayoutNode.new(pane: pane)]
    )
    window = Ace::Tmux::Models::Window.new(layout_tree: tree, panes: [pane])

    assert window.nested_layout?
    assert_equal tree, window.layout_tree
  end
end
