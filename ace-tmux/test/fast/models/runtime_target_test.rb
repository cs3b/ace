# frozen_string_literal: true

require_relative "../../test_helper"

class RuntimeTargetTest < Minitest::Test
  def test_window_target_requires_session_and_window
    target = Ace::Tmux::Models::RuntimeTarget.new(session: "dev", window: "work", source: "explicit")

    assert_equal "dev:work", target.window_target
  end

  def test_pane_target_builds_from_session_window_and_index
    target = Ace::Tmux::Models::RuntimeTarget.new(session: "dev", window: "work", pane: "1", source: "explicit")

    assert_equal "dev:work.1", target.pane_target
  end

  def test_pane_target_uses_raw_window_target_when_present
    target = Ace::Tmux::Models::RuntimeTarget.new(
      session: "dev",
      window: "ace.t.n1d",
      pane: "3",
      raw_window_target: "@2",
      source: "live"
    )

    assert_equal "@2", target.window_target
    assert_equal "@2.3", target.pane_target
  end

  def test_pane_target_preserves_full_pane_id
    target = Ace::Tmux::Models::RuntimeTarget.new(pane: "%12", source: "live")

    assert_equal "%12", target.pane_target
  end

  def test_pane_target_preserves_raw_window_id_pane_target
    target = Ace::Tmux::Models::RuntimeTarget.new(pane: "@2.3", source: "live")

    assert_equal "@2.3", target.pane_target
  end
end
