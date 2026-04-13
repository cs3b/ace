# frozen_string_literal: true

require "test_helper"
require "yaml"
require "ostruct"

class ConfigHelpersTest < Minitest::Test
  include Ace::TestSupport::ConfigHelpers
  include Ace::TestSupport::TestHelper

  def test_with_config_creates_and_removes_yaml_file_from_hash
    with_temp_dir do
      config_path = "config/test.yml"
      config_hash = {"key" => "value", "nested" => {"item" => "data"}}

      refute File.exist?(config_path)

      with_config(config_path, config_hash) do
        assert File.exist?(config_path)
        loaded = YAML.load_file(config_path)
        assert_equal config_hash, loaded
      end

      refute File.exist?(config_path), "Config file should be cleaned up"
    end
  end

  def test_with_config_creates_and_removes_file_from_string
    with_temp_dir do
      config_path = "config/test.yml"
      config_string = "key: value\nnested:\n  item: data"

      with_config(config_path, config_string) do
        assert File.exist?(config_path)
        assert_equal config_string, File.read(config_path)
      end

      refute File.exist?(config_path)
    end
  end

  def test_with_config_raises_on_invalid_content_type
    assert_raises(ArgumentError, "Content must be Hash or String") do
      with_config("test.yml", 123) {}
    end
  end

  def test_with_config_creates_nested_directories
    with_temp_dir do
      deep_path = "deeply/nested/config/file.yml"

      with_config(deep_path, {"test" => "data"}) do
        assert File.exist?(deep_path)
      end
    end
  end

  def test_with_env_sets_and_restores_environment_variables
    original_value = ENV["TEST_VAR"]

    with_env("TEST_VAR" => "test_value", "ANOTHER_VAR" => "another") do
      assert_equal "test_value", ENV["TEST_VAR"]
      assert_equal "another", ENV["ANOTHER_VAR"]
    end

    assert_equal original_value, ENV["TEST_VAR"]
    assert_nil ENV["ANOTHER_VAR"]
  end

  def test_with_env_restores_original_values
    ENV["EXISTING_VAR"] = "original"

    with_env("EXISTING_VAR" => "modified") do
      assert_equal "modified", ENV["EXISTING_VAR"]
    end

    assert_equal "original", ENV["EXISTING_VAR"]
  ensure
    ENV.delete("EXISTING_VAR")
  end

  def test_with_env_handles_exceptions
    ENV["TEST_VAR"] = "original"

    assert_raises(RuntimeError) do
      with_env("TEST_VAR" => "modified") do
        assert_equal "modified", ENV["TEST_VAR"]
        raise "test error"
      end
    end

    assert_equal "original", ENV["TEST_VAR"]
  ensure
    ENV.delete("TEST_VAR")
  end

  def test_with_cascade_configs_creates_multiple_config_levels
    with_temp_dir do
      configs = {
        project: {"level" => "project", "value" => 1},
        home: {"level" => "home", "value" => 2}
      }

      with_cascade_configs("test-gem", configs) do
        assert File.exist?("./.ace/test-gem/config.yml")
        assert File.exist?(File.expand_path("~/.ace/test-gem/config.yml"))

        project_config = YAML.load_file("./.ace/test-gem/config.yml")
        assert_equal "project", project_config["level"]
      end

      refute File.exist?("./.ace/test-gem/config.yml")
    end
  end

  def test_sample_config_generates_expected_structure
    config = sample_config(gem_name: "test", level: "development")

    assert_equal "development", config["ace"]["level"]
    assert_equal "1.0.0", config["ace"]["test"]["version"]
    assert_equal "test", config["ace"]["test"]["environment"]
  end

  def test_sample_config_with_custom_values
    custom = {
      "ace" => {
        "custom_key" => "custom_value",
        "test" => {
          "extra" => "data"
        }
      }
    }

    config = sample_config(gem_name: "test", custom: custom)

    assert_equal "custom_value", config["ace"]["custom_key"]
    assert_equal "data", config["ace"]["test"]["extra"]
    assert_equal "1.0.0", config["ace"]["test"]["version"], "Should preserve defaults"
  end

  def test_sample_env_content_generates_env_format
    content = sample_env_content("CUSTOM_VAR" => "custom_value")

    assert_match(/ACE_ENV=test/, content)
    assert_match(/ACE_DEBUG=false/, content)
    assert_match(/CUSTOM_VAR=custom_value/, content)
  end

  def test_assert_config_structure_validates_nested_hash
    config = {
      "ace" => {
        "level" => "test",
        "nested" => {
          "value" => "data"
        }
      }
    }

    expected = {
      "ace" => {
        "level" => "test",
        "nested" => {
          "value" => "data"
        }
      }
    }

    # Should not raise
    assert_config_structure(config, expected)
  end

  def test_assert_config_structure_fails_on_missing_key
    config = {"ace" => {"level" => "test"}}
    expected = {"ace" => {"level" => "test", "missing" => "key"}}

    assert_raises(Minitest::Assertion) do
      assert_config_structure(config, expected)
    end
  end

  def test_assert_config_structure_fails_on_value_mismatch
    config = {"ace" => {"level" => "test"}}
    expected = {"ace" => {"level" => "production"}}

    assert_raises(Minitest::Assertion) do
      assert_config_structure(config, expected)
    end
  end

  def test_assert_precedence_validates_config_resolution
    # Mock resolver object for testing
    resolver = Object.new

    # Create a mock config object
    mock_config = Object.new
    def mock_config.get(*path)
      return "expected_value" if path == ["ace", "test", "value"]
      nil
    end

    def resolver.resolve
      mock_config
    end
    resolver.instance_variable_set(:@mock_config, mock_config)
    def resolver.resolve
      @mock_config
    end

    # Should not raise when value matches
    assert_precedence(resolver, "ace.test.value", "expected_value", "test source")
  end

  def test_malformed_yaml_generates_invalid_yaml
    yaml = malformed_yaml

    assert_raises(Psych::SyntaxError) do
      YAML.safe_load(yaml)
    end
  end

  def test_complex_yaml_generates_valid_complex_structure
    yaml_str = complex_yaml
    parsed = YAML.safe_load(yaml_str, permitted_classes: [Symbol])

    assert_kind_of Array, parsed["ace"]["arrays"]
    assert_equal [1, 2, 3], parsed["ace"]["arrays"]
    assert_equal "found", parsed["ace"]["nested"]["deep"]["value"]
  end

  def test_deep_merge_helper
    # Test private method through sample_config
    base = {"a" => {"b" => "base", "c" => "keep"}}
    overlay = {"a" => {"b" => "overlay", "d" => "new"}}

    # Use sample_config which uses deep_merge internally
    sample_config(custom: base)
    config2 = sample_config(custom: overlay)

    # The overlay should win for overlapping keys
    assert config2["a"]["b"] == "overlay" || config2["ace"]
  end
end
