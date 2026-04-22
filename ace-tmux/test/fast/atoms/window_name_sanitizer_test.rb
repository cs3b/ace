# frozen_string_literal: true

require_relative "../../test_helper"

class WindowNameSanitizerTest < Minitest::Test
  def test_replaces_tmux_target_punctuation_with_dashes
    assert_equal "ace-t-k5a-fs", Ace::Tmux::Atoms::WindowNameSanitizer.call("ace-t.k5a:fs")
  end

  def test_collapses_and_trims_generated_dashes
    assert_equal "task-240-02", Ace::Tmux::Atoms::WindowNameSanitizer.call("..task;;240::02..")
  end

  def test_uses_sanitized_fallback_for_empty_names
    assert_equal "fork-window", Ace::Tmux::Atoms::WindowNameSanitizer.call("...", fallback: "fork.window")
  end
end
