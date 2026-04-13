# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/bundle/atoms/line_counter"

class LineCounterTest < AceTestCase
  def test_empty_string_returns_zero
    assert_equal 0, Ace::Bundle::Atoms::LineCounter.count("")
  end

  def test_nil_returns_zero
    assert_equal 0, Ace::Bundle::Atoms::LineCounter.count(nil)
  end

  def test_single_line_without_newline
    assert_equal 1, Ace::Bundle::Atoms::LineCounter.count("hello")
  end

  def test_single_line_with_newline
    assert_equal 1, Ace::Bundle::Atoms::LineCounter.count("hello\n")
  end

  def test_multiple_lines_without_trailing_newline
    assert_equal 3, Ace::Bundle::Atoms::LineCounter.count("a\nb\nc")
  end

  def test_multiple_lines_with_trailing_newline
    assert_equal 2, Ace::Bundle::Atoms::LineCounter.count("a\nb\n")
  end

  def test_exactly_500_lines
    content = (1..500).map { |i| "line #{i}" }.join("\n")
    assert_equal 500, Ace::Bundle::Atoms::LineCounter.count(content)
  end

  def test_exactly_500_lines_with_trailing_newline
    content = (1..500).map { |i| "line #{i}" }.join("\n") + "\n"
    assert_equal 500, Ace::Bundle::Atoms::LineCounter.count(content)
  end

  def test_blank_lines_are_counted
    assert_equal 3, Ace::Bundle::Atoms::LineCounter.count("a\n\nb")
  end

  def test_only_newlines
    assert_equal 3, Ace::Bundle::Atoms::LineCounter.count("\n\n\n")
  end

  def test_whitespace_only_line
    assert_equal 1, Ace::Bundle::Atoms::LineCounter.count("   ")
  end
end
