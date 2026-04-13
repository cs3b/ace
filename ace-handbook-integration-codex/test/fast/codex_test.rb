# frozen_string_literal: true

require_relative "../test_helper"

class Ace::Handbook::Integration::CodexTest < Minitest::Test
  def test_loads_with_ace_handbook_runtime
    assert defined?(Ace::Handbook)
    assert_kind_of String, Ace::Handbook::Integration::Codex::VERSION
  end
end
