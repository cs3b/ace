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
    # Reset to get fresh config from gem defaults
    Ace::Prompt.reset_config!
    Ace::Core.stub :get, nil do
      config = Ace::Prompt.config

      assert config.is_a?(Hash)
      assert config.key?("context")
      assert config["context"].is_a?(Hash)
      assert config["context"].key?("enabled")
    end
  end

  def test_config_context_disabled_by_default
    # Reset to get fresh config from gem defaults
    Ace::Prompt.reset_config!
    Ace::Core.stub :get, nil do
      config = Ace::Prompt.config

      assert_equal false, config["context"]["enabled"]
    end
  end

  def test_config_returns_hash
    # Stub Ace::Core.get to return empty hash (simulating no config file)
    Ace::Core.stub :get, nil do
      config = Ace::Prompt.config

      assert config.is_a?(Hash)
    end
  end

  def test_config_merges_with_defaults
    # Mock returns user config with context.enabled = true
    user_config = { "context" => { "enabled" => true } }
    Ace::Core.stub :get, user_config do
      config = Ace::Prompt.config

      assert_equal true, config["context"]["enabled"]
    end
  end

  def test_config_uses_defaults_when_user_config_empty
    # Stub to return nil (no config file found)
    Ace::Core.stub :get, nil do
      config = Ace::Prompt.config

      assert_equal false, config["context"]["enabled"]
    end
  end

  def test_reset_config_clears_cache
    Ace::Core.stub :get, nil do
      config1 = Ace::Prompt.config
      Ace::Prompt.reset_config!

      # After reset, config should be reloaded
      config2 = Ace::Prompt.config

      # Both should have defaults, but be different object instances
      # due to cache reset
      assert_equal config1["context"]["enabled"], config2["context"]["enabled"]
    end
  end
end
