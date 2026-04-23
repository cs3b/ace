# frozen_string_literal: true

require_relative "../../test_helper"

class NamedKeyRegistryTest < Minitest::Test
  def test_normalize_enter
    assert_equal "Enter", Ace::Tmux::Atoms::NamedKeyRegistry.normalize("Enter")
  end

  def test_normalize_ctrl_c_alias
    assert_equal "C-c", Ace::Tmux::Atoms::NamedKeyRegistry.normalize("c-c")
  end

  def test_rejects_unknown_key
    error = assert_raises(Ace::Tmux::ValidationError) do
      Ace::Tmux::Atoms::NamedKeyRegistry.normalize("PasteBuffer")
    end

    assert_includes error.message, "Unsupported named key"
  end
end
