# frozen_string_literal: true

require_relative "../test_helper"
require "ace/core/organisms/config_resolver"

class ConfigResolverTest < AceTestCase
  def test_resolve_with_cascade
    with_temp_dir do |dir|
      # Create local config
      local_config = {
        "ace" => {
          "local" => "value",
          "override" => "local"
        }
      }
      create_config_file(".ace/config.yml", local_config.to_yaml)

      # Create home config (simulated)
      home_config = {
        "ace" => {
          "home" => "value",
          "override" => "home"
        }
      }
      home_dir = File.join(dir, "home")
      create_config_file("#{home_dir}/.ace/config.yml", home_config.to_yaml)

      # Mock home directory
      original_home = ENV["HOME"]
      ENV["HOME"] = home_dir

      resolver = Ace::Core::Organisms::ConfigResolver.new
      config = resolver.resolve

      assert_equal "value", config.get("ace", "local")
      assert_equal "value", config.get("ace", "home")
      assert_equal "local", config.get("ace", "override") # Local wins
    ensure
      ENV["HOME"] = original_home if original_home
    end
  end

  def test_resolve_empty_when_no_configs
    with_temp_dir do
      resolver = Ace::Core::Organisms::ConfigResolver.new
      config = resolver.resolve

      assert config.empty?
      assert_equal "defaults", config.source
    end
  end

  def test_get_value_by_path
    with_temp_dir do
      config_data = {
        "ace" => {
          "nested" => {
            "deep" => "value"
          }
        }
      }
      create_config_file(".ace/config.yml", config_data.to_yaml)

      resolver = Ace::Core::Organisms::ConfigResolver.new
      value = resolver.get("ace", "nested", "deep")

      assert_equal "value", value
    end
  end

  def test_resolve_type_local
    with_temp_dir do
      local_config = { "ace" => { "type" => "local" } }
      create_config_file(".ace/config.yml", local_config.to_yaml)

      resolver = Ace::Core::Organisms::ConfigResolver.new
      config = resolver.resolve_type(:local)

      assert_equal "local", config.get("ace", "type")
    end
  end

  def test_create_default
    with_temp_dir do
      config_path = ".ace/core/config.yml"
      config = Ace::Core::Organisms::ConfigResolver.create_default(config_path)

      assert File.exist?(config_path)
      assert_equal "0.9.0", config.get("ace", "version")
      assert config.get("ace", "config_cascade", "enabled")
    end
  end
end