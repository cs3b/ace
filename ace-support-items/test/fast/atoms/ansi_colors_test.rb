# frozen_string_literal: true

require "test_helper"

class AnsiColorsTest < AceSupportItemsTestCase
  def test_colorize_wraps_text_when_tty
    Ace::Support::Items::Atoms::AnsiColors.stub(:tty?, true) do
      result = Ace::Support::Items::Atoms::AnsiColors.colorize("hello", "\e[32m")
      assert_equal "\e[32mhello\e[0m", result
    end
  end

  def test_colorize_returns_plain_text_when_not_tty
    Ace::Support::Items::Atoms::AnsiColors.stub(:tty?, false) do
      result = Ace::Support::Items::Atoms::AnsiColors.colorize("hello", "\e[32m")
      assert_equal "hello", result
    end
  end

  def test_constants_defined
    assert_equal "\e[31m", Ace::Support::Items::Atoms::AnsiColors::RED
    assert_equal "\e[32m", Ace::Support::Items::Atoms::AnsiColors::GREEN
    assert_equal "\e[33m", Ace::Support::Items::Atoms::AnsiColors::YELLOW
    assert_equal "\e[36m", Ace::Support::Items::Atoms::AnsiColors::CYAN
    assert_equal "\e[2m", Ace::Support::Items::Atoms::AnsiColors::DIM
    assert_equal "\e[1m", Ace::Support::Items::Atoms::AnsiColors::BOLD
    assert_equal "\e[0m", Ace::Support::Items::Atoms::AnsiColors::RESET
  end
end
