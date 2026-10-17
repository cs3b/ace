# frozen_string_literal: true

require_relative "../../test_helper"

class TextTruncatorTest < Minitest::Test
  def truncator
    Ace::Git::Worktree::Atoms::TextTruncator
  end

  def test_middle_keeps_prefix_and_suffix
    result = truncator.middle("codex/ei9-campaign-composition-join", 25)
    assert_equal 25, result.length
    assert_equal "codex/ei9-ca…osition-join", result
    assert result.start_with?("codex")
    assert result.end_with?("join")
  end

  def test_middle_exact_fit_unchanged
    assert_equal "feature-branch", truncator.middle("feature-branch", 14)
    assert_equal "feature-branch", truncator.middle("feature-branch", 40)
  end

  def test_right_truncation
    result = truncator.right("spec(8xf.t.ei9-wave-3): campaign", 24)
    assert_equal 24, result.length
    assert result.start_with?("spec(8xf")
    assert result.end_with?("…")
  end

  def test_left_elision
    result = truncator.left("/Users/mc/Ps/ace/.ace-wt/ei9-campaign-composition", 32)
    assert_equal 32, result.length
    assert result.start_with?("…")
    assert result.end_with?("composition")
  end

  def test_tiny_widths
    assert_equal "", truncator.middle("abcdef", 0)
    assert_equal "", truncator.middle("abcdef", -2)
    assert_equal "…", truncator.middle("abcdef", 1)
    assert_equal "…", truncator.right("abcdef", 1)
    assert_equal "…", truncator.left("abcdef", 1)
  end

  def test_nil_text_renders_empty
    assert_equal "", truncator.middle(nil, 10)
    assert_equal "", truncator.left(nil, 10)
  end

  def test_width_two
    assert_equal "a…", truncator.right("abcdef", 2)
    assert_equal "…f", truncator.left("abcdef", 2)
  end
end
