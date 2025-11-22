# frozen_string_literal: true

require "test_helper"

class ConfigLoaderTest < AceTestCase
  def test_load_returns_default_config
    config = Ace::Prompt::Molecules::ConfigLoader.load

    # Test default values exist
    assert_equal ".cache/ace-prompt/prompts", config["default_dir"]
    assert_equal "the-prompt.md", config["default_file"]
    assert_equal "archive", config["archive_subdir"]
    assert_equal false, config["context"]["enabled"]
    assert_equal false, config["enhancement"]["enabled"]
    assert_equal "glite", config["enhancement"]["model"]
    assert_equal 0.3, config["enhancement"]["temperature"]
    assert_equal "prompt://ace-prompt/base/enhance", config["enhancement"]["system_prompt"]
  end

  def test_load_with_ace_core_config_override
    # Mock Ace::Core.config to return override values
    mock_config = {
      "default_dir" => "/custom/dir",
      "enhancement" => {
        "model" => "custom-model",
        "temperature" => 0.8
      }
    }

    Ace::Core.stub(:config, OpenStruct.new(get: mock_config)) do
      config = Ace::Prompt::Molecules::ConfigLoader.load

      # Should merge defaults with overrides
      assert_equal "/custom/dir", config["default_dir"]
      assert_equal "custom-model", config["enhancement"]["model"]
      assert_equal 0.8, config["enhancement"]["temperature"]
      # Default values should be preserved for non-overridden keys
      assert_equal "the-prompt.md", config["default_file"]
      assert_equal 0.3, config["enhancement"]["temperature"] # Note: this gets overridden
    end
  end

  def test_load_with_nil_ace_core_config
    # Mock Ace::Core.config to return nil
    Ace::Core.stub(:config, OpenStruct.new(get: nil)) do
      config = Ace::Prompt::Molecules::ConfigLoader.load

      # Should return default config
      assert_equal Ace::Prompt::Molecules::ConfigLoader::DEFAULT_CONFIG, config
    end
  end

  def test_deep_merge_with_simple_hashes
    base = { "a" => 1, "b" => 2 }
    override = { "b" => 3, "c" => 4 }

    result = Ace::Prompt::Molecules::ConfigLoader.deep_merge(base, override)

    expected = { "a" => 1, "b" => 3, "c" => 4 }
    assert_equal expected, result
  end

  def test_deep_merge_with_nested_hashes
    base = {
      "enhancement" => {
        "model" => "base-model",
        "temperature" => 0.3,
        "nested" => {
          "deep" => "base-value"
        }
      },
      "other" => "base-other"
    }

    override = {
      "enhancement" => {
        "temperature" => 0.7,
        "max_tokens" => 1000
      },
      "new_key" => "new-value"
    }

    result = Ace::Prompt::Molecules::ConfigLoader.deep_merge(base, override)

    expected = {
      "enhancement" => {
        "model" => "base-model",  # Kept from base
        "temperature" => 0.7,      # Overridden
        "nested" => {
          "deep" => "base-value"  # Kept from base nested hash
        },
        "max_tokens" => 1000       # Added from override
      },
      "other" => "base-other",     # Kept from base
      "new_key" => "new-value"     # Added from override
    }

    assert_equal expected, result
  end

  def test_deep_merge_with_different_types
    base = { "key" => { "nested" => "value" } }
    override = { "key" => "string_value" }

    result = Ace::Prompt::Molecules::ConfigLoader.deep_merge(base, override)

    # Non-hash values should override completely
    expected = { "key" => "string_value" }
    assert_equal expected, result
  end

  def test_deep_merge_with_nil_override
    base = { "key" => "value" }
    override = { "key" => nil }

    result = Ace::Prompt::Molecules::ConfigLoader.deep_merge(base, override)

    # nil should override the base value
    expected = { "key" => nil }
    assert_equal expected, result
  end

  def test_default_config_is_frozen
    # Ensure DEFAULT_CONFIG is immutable
    assert_raises(FrozenError) do
      Ace::Prompt::Molecules::ConfigLoader::DEFAULT_CONFIG["new_key"] = "value"
    end
  end

  def test_load_returns_new_hash_each_time
    # Ensure that config is not shared between calls
    config1 = Ace::Prompt::Molecules::ConfigLoader.load
    config2 = Ace::Prompt::Molecules::ConfigLoader.load

    # Should be equal but not the same object
    assert_equal config1, config2
    refute_same config1, config2
  end
end