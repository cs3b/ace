# frozen_string_literal: true

require_relative "../test_helper"
require "ace/core/organisms/config_resolver"

class ConfigCascadeTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def setup
    @env = Ace::TestSupport::TestEnvironment.new("core")
    @env.setup
  end

  def teardown
    @env.teardown
  end

  def test_full_cascade_resolution
    # Create configs at all levels
    project_config = {
      "ace" => {
        "level" => "project",
        "project_only" => "project_value",
        "core" => {
          "version" => "2.0.0",
          "features" => ["project_feature"]
        }
      }
    }

    home_config = {
      "ace" => {
        "level" => "home",
        "home_only" => "home_value",
        "shared" => "from_home",
        "core" => {
          "version" => "1.5.0",
          "environment" => "development",
          "features" => ["home_feature"]
        }
      }
    }

    gem_config = {
      "ace" => {
        "level" => "gem",
        "gem_only" => "gem_value",
        "shared" => "from_gem",
        "core" => {
          "version" => "1.0.0",
          "environment" => "production",
          "features" => ["gem_feature"],
          "timeout" => 30
        }
      }
    }

    # Write configs
    @env.write_config(:project, "config.yml", project_config.to_yaml)
    @env.write_config(:home, "config.yml", home_config.to_yaml)
    @env.write_config(:gem, "config.yml", gem_config.to_yaml)

    # Create resolver with test paths
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        @env.config_path(:project),
        @env.config_path(:home),
        @env.config_path(:gem)
      ],
      file_patterns: ["config.yml"],
      merge_strategy: :replace
    )

    config = resolver.resolve

    # Verify precedence: project > home > gem
    assert_equal "project", config.get("ace", "level")
    assert_equal "2.0.0", config.get("ace", "core", "version")

    # Verify values from home level when not in project
    assert_equal "development", config.get("ace", "core", "environment")
    assert_equal "home_value", config.get("ace", "home_only")

    # Verify values from gem level when not in higher levels
    assert_equal 30, config.get("ace", "core", "timeout")
    assert_equal "gem_value", config.get("ace", "gem_only")

    # Verify shared value comes from home (not gem)
    assert_equal "from_home", config.get("ace", "shared")

    # Verify project-only values exist
    assert_equal "project_value", config.get("ace", "project_only")
  end

  def test_partial_cascade_missing_project
    # Only home and gem configs
    home_config = {
      "ace" => {
        "level" => "home",
        "core" => {
          "version" => "1.5.0"
        }
      }
    }

    gem_config = {
      "ace" => {
        "level" => "gem",
        "core" => {
          "version" => "1.0.0",
          "environment" => "production"
        }
      }
    }

    @env.write_config(:home, "config.yml", home_config.to_yaml)
    @env.write_config(:gem, "config.yml", gem_config.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        @env.config_path(:project),
        @env.config_path(:home),
        @env.config_path(:gem)
      ],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve

    # Home takes precedence over gem
    assert_equal "home", config.get("ace", "level")
    assert_equal "1.5.0", config.get("ace", "core", "version")

    # Gem values used when not in home
    assert_equal "production", config.get("ace", "core", "environment")
  end

  def test_cascade_with_array_merging
    project_config = {
      "ace" => {
        "features" => ["feature1", "feature2"]
      }
    }

    home_config = {
      "ace" => {
        "features" => ["feature3", "feature4"]
      }
    }

    @env.write_config(:project, "config.yml", project_config.to_yaml)
    @env.write_config(:home, "config.yml", home_config.to_yaml)

    # Test with union strategy
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        @env.config_path(:project),
        @env.config_path(:home)
      ],
      file_patterns: ["config.yml"],
      merge_strategy: :union
    )

    config = resolver.resolve
    features = config.get("ace", "features")

    # Union should combine unique values
    assert_includes features, "feature1"
    assert_includes features, "feature2"
    assert_includes features, "feature3"
    assert_includes features, "feature4"
  end

  def test_cascade_with_empty_configs
    # Create empty config files
    @env.write_config(:project, "config.yml", "")
    @env.write_config(:home, "config.yml", "{}")

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        @env.config_path(:project),
        @env.config_path(:home)
      ],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve

    # Should return empty config without error
    assert_kind_of Ace::Core::Models::Config, config
    assert_equal({}, config.data)
  end

  def test_cascade_with_no_configs
    # No config files exist
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        @env.config_path(:project),
        @env.config_path(:home)
      ],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve

    # Should return default empty config
    assert_kind_of Ace::Core::Models::Config, config
    assert_equal "defaults", config.source
    assert_equal({}, config.data)
  end

  def test_find_configs_method
    # Create some config files
    @env.write_config(:project, "config.yml", "ace: {}")
    @env.write_config(:home, "settings.yml", "ace: {}")

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        @env.config_path(:project),
        @env.config_path(:home)
      ],
      file_patterns: ["config.yml", "settings.yml"]
    )

    configs = resolver.find_configs

    # Should find all config paths
    assert_kind_of Array, configs
    assert configs.all? { |c| c.is_a?(Ace::Core::Models::CascadePath) }

    # Check that existing configs are marked as such
    existing = configs.select(&:exists)
    assert_equal 2, existing.count
  end

  def test_resolve_by_type
    # Create configs of different types
    home_config = {
      "ace" => {
        "level" => "home",
        "home_value" => "test"
      }
    }

    @env.write_config(:project, "config.yml", {"ace" => {"level" => "project"}}.to_yaml)
    @env.write_config(:home, "config.yml", home_config.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        @env.config_path(:project),
        @env.config_path(:home)
      ],
      file_patterns: ["config.yml"]
    )

    # Get only home config
    home_only = resolver.resolve_type(:home)

    assert_kind_of Ace::Core::Models::Config, home_only
    assert_equal "home", home_only.get("ace", "level")
    assert_equal "test", home_only.get("ace", "home_value")
  end

  def test_get_method_shortcut
    config_content = {
      "ace" => {
        "core" => {
          "deep" => {
            "value" => "found_it"
          }
        }
      }
    }

    @env.write_config(:project, "config.yml", config_content.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    # Use get shortcut method
    value = resolver.get("ace", "core", "deep", "value")
    assert_equal "found_it", value
  end
end