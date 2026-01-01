# frozen_string_literal: true

require "test_helper"

class Ace::TestPrompt < Minitest::Test
  def setup
    Ace::Prompt.reset_config!
  end

  def teardown
    Ace::Prompt.reset_config!
  end

  def test_that_it_has_a_version_number
    refute_nil ::Ace::Prompt::VERSION
    assert_match(/\d+\.\d+\.\d+/, ::Ace::Prompt::VERSION)
  end

  def test_module_defined
    assert defined?(Ace::Prompt)
    assert defined?(Ace::Prompt::Error)
  end

  def test_config_method_exists
    assert_respond_to Ace::Prompt, :config
  end

  def test_config_returns_hash_with_defaults
    # Config should return a hash with expected structure
    config = Ace::Prompt.config

    assert config.is_a?(Hash)
    assert config.key?("context")
    assert config["context"].is_a?(Hash)
    assert config["context"].key?("enabled")
  end

  def test_config_context_has_enabled_key
    # Verify context.enabled key exists (value depends on project config)
    config = Ace::Prompt.config

    assert config["context"].key?("enabled")
    assert [true, false].include?(config["context"]["enabled"])
  end

  def test_config_returns_hash
    config = Ace::Prompt.config

    assert config.is_a?(Hash)
  end

  def test_config_structure
    # Test that config has expected top-level keys from defaults
    config = Ace::Prompt.config

    assert config.is_a?(Hash)
    # These keys come from .ace-defaults/prompt/config.yml
    assert config.key?("context") || config.empty?, "Config should have context key or be empty"
  end

  def test_config_caching
    # Config should be cached
    config1 = Ace::Prompt.config
    config2 = Ace::Prompt.config

    assert_same config1, config2, "Config should be cached (same object)"
  end

  def test_reset_config_clears_cache
    config1 = Ace::Prompt.config
    Ace::Prompt.reset_config!

    # After reset, config should be reloaded (different object)
    config2 = Ace::Prompt.config

    refute_same config1, config2, "Config should be reloaded after reset"
  end
end
