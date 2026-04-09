# frozen_string_literal: true

require "minitest/autorun"

class ToolCheckerTest < Minitest::Test
  def test_fixture_is_executable
    assert_equal 2, 1 + 1
  end
end
