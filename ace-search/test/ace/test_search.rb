# frozen_string_literal: true

require "test_helper"

class Ace::TestSearch < AceSearchTestCase
  def test_that_it_has_a_version_number
    refute_nil ::Ace::Search::VERSION
    assert_match(/\d+\.\d+\.\d+/, ::Ace::Search::VERSION)
  end

  def test_module_defined
    assert defined?(Ace::Search)
    assert defined?(Ace::Search::Error)
  end

  def test_config_method_exists
    assert_respond_to Ace::Search, :config
  end

  def test_default_config_returns_hash
    config = Ace::Search.default_config

    assert config.is_a?(Hash)
    assert config.key?("case_insensitive")
    assert config.key?("max_results")
    assert config.key?("exclude")
  end
end
