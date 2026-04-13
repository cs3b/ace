# frozen_string_literal: true

require "test_helper"

class Ace::TestSearch < AceSearchTestCase
  # Config tests need real config access
  def setup
    super
    Ace::Support::Config.test_mode = false
    Ace::Search.reset_config! # Clear cache after mode change
  end

  def teardown
    Ace::Support::Config.test_mode = true
    super
  end

  def test_that_it_has_a_version_number
    refute_nil ::Ace::Search::VERSION
    assert_match(/\A\d+\.\d+\.\d+\z/, ::Ace::Search::VERSION)
  end

  def test_module_defined
    assert defined?(Ace::Search)
    assert defined?(Ace::Search::Error)
  end

  def test_config_method_exists
    assert_respond_to Ace::Search, :config
  end

  def test_config_returns_hash_with_defaults
    # Config now loads from gem defaults (via load_gem_defaults)
    config = Ace::Search.config

    assert config.is_a?(Hash)
    assert config.key?("case_insensitive")
    assert config.key?("max_results")
    assert config.key?("exclude")
  end

  def test_reset_config_clears_cached_config
    # Load config to cache it
    original_config = Ace::Search.config
    assert_same original_config, Ace::Search.config, "Config should be cached"

    # Reset the config
    Ace::Search.reset_config!

    # Next call should return a new instance (even if equal)
    new_config = Ace::Search.config
    refute_same original_config, new_config, "Config should be a new instance after reset"
  end
end
