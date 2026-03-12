# frozen_string_literal: true

require_relative "test_helper"

class Ace::Handbook::Integration::OpencodeTest < Minitest::Test
  def test_loads_with_ace_handbook_runtime
    assert defined?(Ace::Handbook)
    assert_kind_of String, Ace::Handbook::Integration::Opencode::VERSION
  end
end
