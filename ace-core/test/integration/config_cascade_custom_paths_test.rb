# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"
require "fileutils"

module Ace
  module Core
    class ConfigCascadeCustomPathsTest < AceTestCase
      include TestSupport::ConfigHelpers

      def setup
        @env = TestSupport::TestEnvironment.new
        @env.setup
      end

      def teardown
        @env.teardown
      end

      def test_config_resolver_with_custom_search_paths
        # Create configs in both .ace/context and ~/.ace/context
        local_config = {
          "context" => {
            "presets" => {
              "test" => {
                "include" => ["local.md"],
                "description" => "Local test preset"
              }
            }
          }
        }

        home_config = {
          "context" => {
            "presets" => {
              "test" => {
                "include" => ["home.md"],
                "exclude" => ["*.log"],
                "description" => "Home test preset"
              },
              "home_only" => {
                "include" => ["home_only.md"]
              }
            }
          }
        }

        # Write configs to test environment
        # Need to manually create the directories and files since TestEnvironment
        # expects configs to be in .ace/core, but we need them in .ace/context
        local_path = File.join(@env.project_dir, ".ace", "context", "config.yml")
        FileUtils.mkdir_p(File.dirname(local_path))
        File.write(local_path, YAML.dump(local_config))

        home_path = File.join(@env.home_dir, ".ace", "context", "config.yml")
        FileUtils.mkdir_p(File.dirname(home_path))
        File.write(home_path, YAML.dump(home_config))

        # Create resolver with custom search paths (like ace-context does)
        resolver = Organisms::ConfigResolver.new(
          search_paths: [".ace/context", "~/.ace/context"],
          file_patterns: ["config.yml"]
        )

        config = resolver.resolve

        # Test that configs are properly merged
        presets = config.get("context", "presets")

        assert presets, "Should have presets section"

        # Local should override home for 'test' preset
        test_preset = presets["test"]
        assert_equal ["local.md"], test_preset["include"],
          "Local config should override home config for include"
        assert_equal ["*.log"], test_preset["exclude"],
          "Home config exclude should be preserved when not in local"
        assert_equal "Local test preset", test_preset["description"],
          "Local config should override home config for description"

        # Home-only preset should still exist
        assert presets["home_only"], "Home-only preset should be included"
        assert_equal ["home_only.md"], presets["home_only"]["include"]
      end

      def test_config_resolver_finds_configs_in_custom_paths
        # Create configs in custom paths
        local_path = File.join(@env.project_dir, ".ace", "context", "config.yml")
        FileUtils.mkdir_p(File.dirname(local_path))
        File.write(local_path, YAML.dump({ "source" => "local" }))

        home_path = File.join(@env.home_dir, ".ace", "context", "config.yml")
        FileUtils.mkdir_p(File.dirname(home_path))
        File.write(home_path, YAML.dump({ "source" => "home" }))

        resolver = Organisms::ConfigResolver.new(
          search_paths: [".ace/context", "~/.ace/context"],
          file_patterns: ["config.yml"]
        )

        # Find all config files
        configs = resolver.find_configs
        existing = configs.select(&:exists)

        # Should find both config files
        assert_equal 2, existing.size, "Should find configs in both paths"

        paths = existing.map(&:path)
        assert paths.any? { |p| p.include?(".ace/context/config.yml") },
          "Should find local context config"
        assert paths.any? { |p| p.include?("/.ace/context/config.yml") && !p.include?("./.ace") },
          "Should find home context config"
      end

      def test_config_cascade_priority_with_custom_paths
        # Test that local overrides home, home overrides gem defaults
        local_config = { "context" => { "setting" => "local" } }
        home_config = { "context" => { "setting" => "home", "home_only" => true } }

        local_path = File.join(@env.project_dir, ".ace", "context", "config.yml")
        FileUtils.mkdir_p(File.dirname(local_path))
        File.write(local_path, YAML.dump(local_config))

        home_path = File.join(@env.home_dir, ".ace", "context", "config.yml")
        FileUtils.mkdir_p(File.dirname(home_path))
        File.write(home_path, YAML.dump(home_config))

        resolver = Organisms::ConfigResolver.new(
          search_paths: [".ace/context", "~/.ace/context"],
          file_patterns: ["config.yml"]
        )

        config = resolver.resolve

        # Local should override home
        assert_equal "local", config.get("context", "setting"),
          "Local config should have highest priority"

        # Home-only settings should be preserved
        assert_equal true, config.get("context", "home_only"),
          "Settings only in home config should be preserved"
      end
    end
  end
end