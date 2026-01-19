# frozen_string_literal: true

require "test_helper"

class Ace::TestLint < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ace::Lint::VERSION
  end

  def test_config_loading_works
    # Should not crash and should return a hash
    config = Ace::Lint.config
    assert_kind_of Hash, config
  end

  def test_kramdown_config_loading_works
    # Should not crash and should return a hash
    kramdown_config = Ace::Lint.kramdown_config
    assert_kind_of Hash, kramdown_config
  end

  def test_kramdown_config_has_expected_keys
    # Should have expected configuration (from gem defaults)
    # Reset to ensure we get fresh config
    Ace::Lint.reset_config!
    config = Ace::Lint.kramdown_config
    assert_equal "GFM", config["input"]
    assert_equal 120, config["line_width"]
    assert_equal false, config["auto_ids"]
  end

  def test_module_loading
    # Should be able to access required components
    assert_respond_to Ace::Lint, :config
    assert_respond_to Ace::Lint, :kramdown_config
    assert_respond_to Ace::Lint, :reset_config!
  end
end
