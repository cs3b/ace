# frozen_string_literal: true

require_relative "../test_helper"
require "ace/core/organisms/config_resolver"

class ConfigCascadeEdgeTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def setup
    @env = Ace::TestSupport::TestEnvironment.new("core")
    @env.setup
  end

  def teardown
    @env.teardown
  end

  def test_config_with_very_deep_nesting
    # Test that deeply nested configuration structures are handled correctly
    deep_config = {
      "ace" => {
        "level1" => {
          "level2" => {
            "level3" => {
              "level4" => {
                "level5" => {
                  "level6" => {
                    "level7" => {
                      "level8" => {
                        "level9" => {
                          "level10" => "deep_value"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    @env.write_config(:project, "config.yml", deep_config.to_yaml)
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    result = resolver.get("ace", "level1", "level2", "level3", "level4", "level5", "level6", "level7", "level8", "level9", "level10")
    assert_equal "deep_value", result
  end

  def test_config_with_conflicting_types_at_same_path
    # Test priority resolution when different levels provide different types
    project_config = {
      "ace" => {
        "feature" => ["array", "values"]
      }
    }

    home_config = {
      "ace" => {
        "feature" => "string_value"
      }
    }

    @env.write_config(:project, "config.yml", project_config.to_yaml)
    @env.write_config(:home, "config.yml", home_config.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project), @env.config_path(:home)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve
    # Project config should win (higher priority)
    result = config.get("ace", "feature")
    assert_equal ["array", "values"], result
  end

  def test_config_cascade_with_nil_values
    # Test that nil values are handled correctly in cascade
    project_config = {
      "ace" => {
        "setting" => nil
      }
    }

    home_config = {
      "ace" => {
        "setting" => "home_value"
      }
    }

    @env.write_config(:project, "config.yml", project_config.to_yaml)
    @env.write_config(:home, "config.yml", home_config.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project), @env.config_path(:home)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve
    # Project nil should override home value
    result = config.get("ace", "setting")
    assert_nil result
  end

  def test_config_with_empty_hashes_and_arrays
    # Test that empty collections are preserved
    config_data = {
      "ace" => {
        "empty_hash" => {},
        "empty_array" => [],
        "nested" => {
          "also_empty" => {}
        }
      }
    }

    @env.write_config(:project, "config.yml", config_data.to_yaml)
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve
    assert_equal({}, config.get("ace", "empty_hash"))
    assert_equal([], config.get("ace", "empty_array"))
    assert_equal({}, config.get("ace", "nested", "also_empty"))
  end

  def test_config_with_special_yaml_values
    # Test handling of special YAML values
    config_data = {
      "ace" => {
        "bool_true" => true,
        "bool_false" => false,
        "number_int" => 42,
        "number_float" => 3.14,
        "string_number" => "123",
        "string_bool" => "true"
      }
    }

    @env.write_config(:project, "config.yml", config_data.to_yaml)
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve
    assert_equal true, config.get("ace", "bool_true")
    assert_equal false, config.get("ace", "bool_false")
    assert_equal 42, config.get("ace", "number_int")
    assert_equal 3.14, config.get("ace", "number_float")
    assert_equal "123", config.get("ace", "string_number")
    assert_equal "true", config.get("ace", "string_bool")
  end

  def test_config_priority_with_multiple_files_same_level
    # Test that when multiple config files exist at same level, they merge correctly
    config1 = {
      "ace" => {
        "feature1" => "value1",
        "shared" => "from_config1"
      }
    }

    config2 = {
      "ace" => {
        "feature2" => "value2",
        "shared" => "from_config2"
      }
    }

    @env.write_config(:project, "config1.yml", config1.to_yaml)
    @env.write_config(:project, "config2.yml", config2.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config1.yml", "config2.yml"]
    )

    config = resolver.resolve
    # Both features should be present
    assert_equal "value1", config.get("ace", "feature1")
    assert_equal "value2", config.get("ace", "feature2")
  end

  def test_config_with_very_long_keys
    # Test that very long key paths are handled
    long_key = "very_long_key_name_" * 10
    config_data = {
      "ace" => {
        long_key => "long_key_value"
      }
    }

    @env.write_config(:project, "config.yml", config_data.to_yaml)
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve
    result = config.get("ace", long_key)
    assert_equal "long_key_value", result
  end

  def test_config_with_unicode_keys_and_values
    # Test that unicode in config works correctly
    config_data = {
      "ace" => {
        "café" => "résumé",
        "nested" => {
          "ключ" => "значение"
        }
      }
    }

    @env.write_config(:project, "config.yml", config_data.to_yaml)
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve
    assert_equal "résumé", config.get("ace", "café")
    assert_equal "значение", config.get("ace", "nested", "ключ")
  end

  def test_config_cascade_with_array_merging_strategies
    # Test different array merging behaviors
    project_config = {
      "ace" => {
        "features" => ["project_feature"]
      }
    }

    home_config = {
      "ace" => {
        "features" => ["home_feature1", "home_feature2"]
      }
    }

    @env.write_config(:project, "config.yml", project_config.to_yaml)
    @env.write_config(:home, "config.yml", home_config.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project), @env.config_path(:home)],
      file_patterns: ["config.yml"],
      merge_strategy: :union
    )

    config = resolver.resolve
    result = config.get("ace", "features")
    assert_kind_of Array, result
    assert result.include?("project_feature")
  end

  def test_config_with_large_values
    # Test handling of large config values
    large_string = "x" * 10_000
    large_array = Array.new(1000) { |i| "item_#{i}" }

    config_data = {
      "ace" => {
        "large_string" => large_string,
        "large_array" => large_array
      }
    }

    @env.write_config(:project, "config.yml", config_data.to_yaml)
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve
    assert_equal large_string, config.get("ace", "large_string")
    assert_equal large_array, config.get("ace", "large_array")
    assert_equal 1000, config.get("ace", "large_array").size
  end

  def test_config_resolution_with_missing_intermediate_paths
    # Test accessing deeply nested path when intermediate levels don't exist
    config_data = {
      "ace" => {
        "level1" => "value1"
      }
    }

    @env.write_config(:project, "config.yml", config_data.to_yaml)
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve
    # Accessing non-existent deep path should return nil
    result = config.get("ace", "level1", "level2", "level3")
    assert_nil result
  end

  def test_config_cascade_priority_order
    # Test that cascade priority is strictly enforced
    project_config = { "ace" => { "level" => "project", "value" => 3 } }
    home_config = { "ace" => { "level" => "home", "value" => 2 } }
    gem_config = { "ace" => { "level" => "gem", "value" => 1 } }

    @env.write_config(:project, "config.yml", project_config.to_yaml)
    @env.write_config(:home, "config.yml", home_config.to_yaml)
    @env.write_config(:gem, "config.yml", gem_config.to_yaml)

    # Create resolver with explicit priority order
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project), @env.config_path(:home), @env.config_path(:gem)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve
    # Project should always win
    assert_equal "project", config.get("ace", "level")
    assert_equal 3, config.get("ace", "value")
  end
end
