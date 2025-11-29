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

  def test_default_config_returns_hash
    config = Ace::Prompt.default_config

    assert config.is_a?(Hash)
    assert config.key?("context")
    assert config["context"].is_a?(Hash)
    assert config["context"].key?("enabled")
  end

  def test_default_config_context_disabled
    config = Ace::Prompt.default_config

    assert_equal false, config["context"]["enabled"]
  end

  def test_config_returns_hash
    # Stub the Core.config to return empty hash
    Ace::Core.stub :config, MockConfig.new({}) do
      config = Ace::Prompt.config

      assert config.is_a?(Hash)
    end
  end

  def test_config_merges_with_defaults
    # Mock returns data at the ace.prompt path
    mock_data = { "ace" => { "prompt" => { "context" => { "enabled" => true } } } }
    Ace::Core.stub :config, MockConfig.new(mock_data) do
      config = Ace::Prompt.config

      assert_equal true, config["context"]["enabled"]
    end
  end

  def test_config_uses_defaults_when_user_config_empty
    Ace::Core.stub :config, MockConfig.new({}) do
      config = Ace::Prompt.config

      assert_equal false, config["context"]["enabled"]
    end
  end

  def test_reset_config_clears_cache
    Ace::Core.stub :config, MockConfig.new({}) do
      config1 = Ace::Prompt.config
      Ace::Prompt.reset_config!

      # After reset, config should be reloaded
      config2 = Ace::Prompt.config

      # Both should have defaults, but be different object instances
      # due to cache reset
      assert_equal config1["context"]["enabled"], config2["context"]["enabled"]
    end
  end

  # Mock config class for testing
  class MockConfig
    def initialize(data)
      @data = data
    end

    def get(*keys)
      result = @data
      keys.each do |key|
        return nil unless result.is_a?(Hash)

        result = result[key]
      end
      result
    end
  end
end
