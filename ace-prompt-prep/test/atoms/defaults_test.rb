# frozen_string_literal: true

require "test_helper"

class DefaultsTest < Minitest::Test
  def test_default_cache_dir_constant_exists
    assert_equal ".ace-local/prompt-prep", Ace::PromptPrep::Defaults::DEFAULT_CACHE_DIR
  end

  def test_default_cache_dir_value
    assert_equal ".ace-local/prompt-prep", Ace::PromptPrep::Defaults::DEFAULT_CACHE_DIR
  end

  def test_default_cache_dir_is_string
    assert_kind_of String, Ace::PromptPrep::Defaults::DEFAULT_CACHE_DIR
  end

  def test_default_cache_dir_is_frozen
    # Constants should be immutable
    assert Ace::PromptPrep::Defaults::DEFAULT_CACHE_DIR.frozen?
  end
end
