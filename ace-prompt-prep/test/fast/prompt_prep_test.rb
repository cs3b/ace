# frozen_string_literal: true

require "test_helper"

class Ace::PromptPrep::Test < Minitest::Test
  def setup
    Ace::PromptPrep.reset_config!
  end

  def teardown
    Ace::PromptPrep.reset_config!
  end

  def test_that_it_has_a_version_number
    refute_nil ::Ace::PromptPrep::VERSION
    assert_match(/\A\d+\.\d+\.\d+\z/, ::Ace::PromptPrep::VERSION)
  end

  def test_module_defined
    assert defined?(Ace::PromptPrep)
    assert defined?(Ace::PromptPrep::Error)
  end

  def test_config_method_exists
    assert_respond_to Ace::PromptPrep, :config
  end

  def test_config_returns_hash_with_defaults
    # Config should return a hash with expected structure
    config = Ace::PromptPrep.config

    assert config.is_a?(Hash)
    assert config.key?("bundle")
    assert config["bundle"].is_a?(Hash)
    assert config["bundle"].key?("enabled")
  end

  def test_config_bundle_has_enabled_key
    # Verify bundle.enabled key exists (value depends on project config)
    config = Ace::PromptPrep.config

    assert config["bundle"].key?("enabled")
    assert [true, false].include?(config["bundle"]["enabled"])
  end

  def test_config_returns_hash
    config = Ace::PromptPrep.config

    assert config.is_a?(Hash)
  end

  def test_config_structure
    # Test that config has expected top-level keys from defaults
    config = Ace::PromptPrep.config

    assert config.is_a?(Hash)
    # These keys come from .ace-defaults/prompt/config.yml
    assert config.key?("bundle") || config.empty?, "Config should have bundle key or be empty"
  end

  def test_config_caching
    # Config should be cached
    config1 = Ace::PromptPrep.config
    config2 = Ace::PromptPrep.config

    assert_same config1, config2, "Config should be cached (same object)"
  end

  def test_reset_config_clears_cache
    config1 = Ace::PromptPrep.config
    Ace::PromptPrep.reset_config!

    # After reset, config should be reloaded (different object)
    config2 = Ace::PromptPrep.config

    refute_same config1, config2, "Config should be reloaded after reset"
  end
end
