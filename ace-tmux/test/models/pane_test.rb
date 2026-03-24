# frozen_string_literal: true

require_relative "../test_helper"

class PaneModelTest < Minitest::Test
  def test_default_initialization
    pane = Ace::Tmux::Models::Pane.new

    assert_equal [], pane.commands
    assert_equal false, pane.focus
    assert_nil pane.root
    assert_nil pane.name
  end

  def test_initialization_with_values
    pane = Ace::Tmux::Models::Pane.new(
      commands: ["vim", "echo hello"],
      focus: true,
      root: "~/projects",
      name: "editor"
    )

    assert_equal ["vim", "echo hello"], pane.commands
    assert_equal true, pane.focus
    assert_equal "~/projects", pane.root
    assert_equal "editor", pane.name
  end

  def test_commands_coerces_to_array
    pane = Ace::Tmux::Models::Pane.new(commands: "vim")
    assert_equal ["vim"], pane.commands
  end

  def test_focus_predicate
    assert Ace::Tmux::Models::Pane.new(focus: true).focus?
    refute Ace::Tmux::Models::Pane.new(focus: false).focus?
    refute Ace::Tmux::Models::Pane.new.focus?
  end

  def test_to_h
    pane = Ace::Tmux::Models::Pane.new(
      commands: ["vim"],
      focus: true,
      root: "~/src",
      name: "editor"
    )

    expected = {
      "commands" => ["vim"],
      "focus" => true,
      "root" => "~/src",
      "name" => "editor"
    }
    assert_equal expected, pane.to_h
  end

  def test_to_h_omits_nil_optional_fields
    pane = Ace::Tmux::Models::Pane.new(commands: ["bash"])
    hash = pane.to_h

    assert_equal ["bash"], hash["commands"]
    refute hash.key?("root")
    refute hash.key?("name")
    refute hash.key?("options")
  end

  def test_options_default_empty
    pane = Ace::Tmux::Models::Pane.new
    assert_equal({}, pane.options)
  end

  def test_options_passthrough
    opts = {"remain-on-exit" => "on"}
    pane = Ace::Tmux::Models::Pane.new(options: opts)
    assert_equal opts, pane.options
  end
end
