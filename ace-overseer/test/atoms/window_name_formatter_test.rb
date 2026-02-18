# frozen_string_literal: true

require_relative "../test_helper"

class WindowNameFormatterTest < AceOverseerTestCase
  def test_formats_window_name_using_task_id_token
    name = Ace::Overseer::Atoms::WindowNameFormatter.format("230", format: "t{task_id}")

    assert_equal "t230", name
  end

  def test_raises_when_task_id_missing
    assert_raises(ArgumentError) do
      Ace::Overseer::Atoms::WindowNameFormatter.format("", format: "t{task_id}")
    end
  end

  def test_raises_when_format_missing
    assert_raises(ArgumentError) do
      Ace::Overseer::Atoms::WindowNameFormatter.format("230", format: "")
    end
  end
end
