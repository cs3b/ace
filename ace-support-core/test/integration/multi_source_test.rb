# frozen_string_literal: true

require_relative "../test_helper"
require "ace/core/organisms/config_resolver"
require "ace/core/organisms/environment_manager"
require "ace/core/molecules/yaml_loader"
require "yaml"
require "date"

class MultiSourceTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def setup
    @env = Ace::TestSupport::TestEnvironment.new("core")
    @env.setup
  end

  def teardown
    @env.teardown
  end

  def test_combines_env_and_config
    # Create YAML config
    yaml_config = {
      "ace" => {
        "core" => {
          "version" => "1.0.0",
          "from_yaml" => "yaml_value"
        }
      }
    }

    @env.write_config(:project, "config.yml", yaml_config.to_yaml)

    # Create .env file
    env_content = <<~ENV
      ACE_CORE_VERSION=2.0.0
      ACE_CORE_FROM_ENV=env_value
      ACE_DEBUG=true
    ENV

    @env.write_env_file(".env", env_content)

    # Load environment first
    env_manager = Ace::Core::Organisms::EnvironmentManager.new(
      root_path: @env.project_dir
    )
    env_manager.load

    # Then resolve config
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve

    # YAML config should be loaded
    assert_equal "1.0.0", config.get("ace", "core", "version")
    assert_equal "yaml_value", config.get("ace", "core", "from_yaml")

    # Environment variables should also be available
    assert_equal "2.0.0", ENV["ACE_CORE_VERSION"]
    assert_equal "env_value", ENV["ACE_CORE_FROM_ENV"]
    assert_equal "true", ENV["ACE_DEBUG"]
  end

  def test_handles_partial_configs
    # Only some config sources exist
    home_config = {
      "ace" => {
        "partial" => true,
        "home_settings" => {
          "value" => "from_home"
        }
      }
    }

    @env.write_config(:home, "config.yml", home_config.to_yaml)
    # No project config, no gem config

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        @env.config_path(:project),  # Doesn't exist
        @env.config_path(:home),      # Exists
        @env.config_path(:gem)        # Doesn't exist
      ],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve

    # Should handle missing configs gracefully
    assert_equal true, config.get("ace", "partial")
    assert_equal "from_home", config.get("ace", "home_settings", "value")
  end

  def test_multiple_config_files_per_directory
    # Create multiple config files in same directory
    main_config = {
      "ace" => {
        "core" => {
          "main" => true,
          "version" => "1.0.0"
        }
      }
    }

    override_config = {
      "ace" => {
        "core" => {
          "override" => true,
          "version" => "2.0.0"
        }
      }
    }

    @env.write_config(:project, "config.yml", main_config.to_yaml)
    @env.write_config(:project, "config.override.yml", override_config.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml", "config.override.yml"]
    )

    config = resolver.resolve

    # Both files should be loaded and merged
    assert_equal true, config.get("ace", "core", "main")
    assert_equal true, config.get("ace", "core", "override")

    # First file in patterns has lower priority, so config.yml wins
    assert_equal "1.0.0", config.get("ace", "core", "version")
  end

  def test_handles_malformed_yaml
    # Write malformed YAML
    @env.write_config(:project, "config.yml", "ace:\n  invalid: [\n    unclosed")

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    # Should handle error gracefully
    assert_raises(Ace::Core::YamlParseError) do
      resolver.resolve
    end
  end

  def test_handles_missing_directories
    # Try to resolve with non-existent directories
    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        "/non/existent/path",
        "/another/missing/dir"
      ],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve

    # Should return default empty config
    assert_kind_of Ace::Core::Models::Config, config
    assert_equal({}, config.data)
    assert_equal "defaults", config.source
  end

  def test_complex_nested_merging
    base_config = {
      "ace" => {
        "database" => {
          "host" => "localhost",
          "port" => 5432,
          "options" => {
            "timeout" => 30,
            "pool" => 5
          }
        },
        "features" => ["base1", "base2"]
      }
    }

    override_config = {
      "ace" => {
        "database" => {
          "host" => "production.db",
          "options" => {
            "timeout" => 60,
            "ssl" => true
          }
        },
        "features" => ["override1"]
      }
    }

    @env.write_config(:home, "config.yml", base_config.to_yaml)
    @env.write_config(:project, "config.yml", override_config.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        @env.config_path(:project),
        @env.config_path(:home)
      ],
      file_patterns: ["config.yml"],
      merge_strategy: :replace
    )

    config = resolver.resolve

    # Check deep merge results
    assert_equal "production.db", config.get("ace", "database", "host")
    assert_equal 5432, config.get("ace", "database", "port")  # From base
    assert_equal 60, config.get("ace", "database", "options", "timeout")  # Override
    assert_equal 5, config.get("ace", "database", "options", "pool")  # From base
    assert_equal true, config.get("ace", "database", "options", "ssl")  # From override
  end

  def test_env_files_with_different_names
    # Create multiple .env files
    @env.write_env_file(".env", "BASE_VAR=base\nSHARED=from_base")
    @env.write_env_file(".env.local", "LOCAL_VAR=local\nSHARED=from_local")

    env_manager = Ace::Core::Organisms::EnvironmentManager.new(
      root_path: @env.project_dir
    )

    env_manager.load

    # All vars should be loaded
    assert_equal "base", ENV["BASE_VAR"]
    assert_equal "local", ENV["LOCAL_VAR"]

    # First file wins when using overwrite: false
    assert_equal "from_base", ENV["SHARED"]
  end

  def test_config_with_symbols_and_special_types
    config_with_symbols = {
      "ace" => {
        "string_key" => "string_value",
        :symbol_key => "symbol_value",
        "numeric" => 42,
        "float" => 3.14,
        "boolean" => true,
        "nil_value" => nil,
        "array" => [1, "two", :three],
        "date" => Date.today.to_s
      }
    }

    @env.write_config(:project, "config.yml", config_with_symbols.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [@env.config_path(:project)],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve

    # All types should be preserved
    assert_equal "string_value", config.get("ace", "string_key")
    assert_equal 42, config.get("ace", "numeric")
    assert_equal 3.14, config.get("ace", "float")
    assert_equal true, config.get("ace", "boolean")
    assert_nil config.get("ace", "nil_value")
    assert_kind_of Array, config.get("ace", "array")
  end

  def test_config_source_tracking
    @env.write_config(:project, "config.yml", {"ace" => {"level" => "project"}}.to_yaml)
    @env.write_config(:home, "config.yml", {"ace" => {"level" => "home"}}.to_yaml)

    resolver = Ace::Core::Organisms::ConfigResolver.new(
      search_paths: [
        @env.config_path(:project),
        @env.config_path(:home)
      ],
      file_patterns: ["config.yml"]
    )

    config = resolver.resolve

    # Source should show the cascade path
    assert_includes config.source, @env.config_path(:project)
    assert_includes config.source, @env.config_path(:home)
    assert_includes config.source, "->"  # Shows cascade
  end
end