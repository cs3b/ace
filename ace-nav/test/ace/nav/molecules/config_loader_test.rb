# frozen_string_literal: true

require "test_helper"
require "ace/nav/molecules/config_loader"

module Ace
  module Nav
    module Molecules
      class ConfigLoaderTest < Minitest::Test
        def setup
          @test_dir = setup_test_environment
          @config_loader = create_test_config_loader(@test_dir)
        end

        def teardown
          cleanup_temp_directory(@test_dir)
        end

        def test_loads_default_settings_when_no_config_file_exists
          settings = @config_loader.load_settings

          assert_equal false, settings["cache"]["enabled"]
          assert_equal ".cache/ace-nav", settings["cache"]["directory"]
          assert_equal 3600, settings["cache"]["ttl"]
          assert_equal true, settings["fuzzy"]["enabled"]
          assert_equal 0.6, settings["fuzzy"]["threshold"]
          assert_equal true, settings["output"]["color"]
          assert_equal false, settings["output"]["verbose"]
        end

        def test_loads_custom_settings_from_file
          # Create custom settings file
          nav_dir = File.join(@test_dir, ".ace", "nav")
          FileUtils.mkdir_p(nav_dir)

          custom_settings = {
            "cache" => {
              "enabled" => true,
              "ttl" => 7200
            },
            "fuzzy" => {
              "enabled" => false
            }
          }

          File.write(File.join(nav_dir, "settings.yml"), custom_settings.to_yaml)

          # Reload with custom settings
          config_loader = ConfigLoader.new(nav_dir)
          settings = config_loader.load_settings

          assert_equal true, settings["cache"]["enabled"]
          assert_equal 7200, settings["cache"]["ttl"]
          assert_equal ".cache/ace-nav", settings["cache"]["directory"] # Default preserved
          assert_equal false, settings["fuzzy"]["enabled"]
          assert_equal 0.6, settings["fuzzy"]["threshold"] # Default preserved
        end

        def test_discovers_protocols_from_directory
          protocols = @config_loader.discovered_protocols

          assert_includes protocols.keys, "test"
          assert_includes protocols.keys, "example"

          test_protocol = protocols["test"]
          assert_equal "test", test_protocol["protocol"]
          assert_equal "Test", test_protocol["name"]
          assert_equal [".test.md", ".tst.md"], test_protocol["extensions"]
        end

        def test_protocol_priority_project_overrides_user
          # Create user protocol
          user_protocols_dir = File.expand_path("~/.ace/protocols")
          FileUtils.mkdir_p(user_protocols_dir)

          user_protocol = {
            "protocol" => "override",
            "name" => "User Override",
            "extensions" => [".user.md"]
          }
          File.write(File.join(user_protocols_dir, "override.yml"), user_protocol.to_yaml)

          # Create project protocol with same name
          create_test_protocol(@test_dir, "override", {
            "name" => "Project Override",
            "extensions" => [".project.md"]
          })

          # Reload to pick up new protocols
          config_loader = create_test_config_loader(@test_dir)
          protocols = config_loader.discovered_protocols

          # Project should override user
          assert_equal "Project Override", protocols["override"]["name"]
          assert_equal [".project.md"], protocols["override"]["extensions"]
        ensure
          # Cleanup user directory
          FileUtils.rm_rf(user_protocols_dir) if Dir.exist?(user_protocols_dir)
        end

        def test_valid_protocol_check
          assert @config_loader.valid_protocol?("test")
          assert @config_loader.valid_protocol?("example")
          refute @config_loader.valid_protocol?("nonexistent")
        end

        def test_valid_protocols_list
          protocols = @config_loader.valid_protocols

          assert_includes protocols, "test"
          assert_includes protocols, "example"
          refute_includes protocols, "nonexistent"
        end

        def test_load_protocol_config_returns_full_config
          config = @config_loader.load_protocol_config("test")

          assert_equal "test", config["protocol"]
          assert_equal "Test", config["name"]
          assert_equal [".test.md", ".tst.md"], config["extensions"]
        end

        def test_load_protocol_config_returns_default_for_unknown
          config = @config_loader.load_protocol_config("wfi")

          # Should return default config since no protocol file exists
          assert config.key?("workflows")
          assert_equal [".wfi.md", ".workflow.md"], config["workflows"]["extensions"]
        end

        def test_available_configs_lists_yml_files
          # Create some config files
          nav_dir = File.join(@test_dir, ".ace", "nav")
          FileUtils.mkdir_p(nav_dir)

          File.write(File.join(nav_dir, "settings.yml"), {}.to_yaml)
          File.write(File.join(nav_dir, "custom.yml"), {}.to_yaml)

          config_loader = ConfigLoader.new(nav_dir)
          configs = config_loader.available_configs

          assert_includes configs, "settings"
          assert_includes configs, "custom"
        end

        def test_handles_malformed_yaml_gracefully
          protocols_dir = File.join(@test_dir, ".ace", "protocols")
          FileUtils.mkdir_p(protocols_dir)

          # Write malformed YAML
          File.write(File.join(protocols_dir, "bad.yml"), "not: valid: yaml: here")

          # Should not crash, just warn
          config_loader = create_test_config_loader(@test_dir)
          protocols = config_loader.discovered_protocols

          # Bad protocol should not be included
          refute protocols.key?("bad")
        end

        def test_discovers_protocols_from_hierarchy
          # Use fresh directory
          fresh_dir = create_temp_ace_directory

          # Create nested .ace directories to simulate hierarchy
          parent_dir = File.join(fresh_dir, "parent")
          child_dir = File.join(parent_dir, "child")
          FileUtils.mkdir_p(child_dir)

          # Create protocol in parent
          parent_protocols_dir = File.join(parent_dir, ".ace", "protocols")
          FileUtils.mkdir_p(parent_protocols_dir)
          File.write(File.join(parent_protocols_dir, "parent.yml"), {
            "protocol" => "parent",
            "name" => "Parent Protocol"
          }.to_yaml)

          # Create protocol in child (should override parent)
          child_protocols_dir = File.join(child_dir, ".ace", "protocols")
          FileUtils.mkdir_p(child_protocols_dir)
          File.write(File.join(child_protocols_dir, "parent.yml"), {
            "protocol" => "parent",
            "name" => "Child Override"
          }.to_yaml)

          # Change to child directory and create config loader
          Dir.chdir(child_dir) do
            # Create a config loader that will discover protocols from the child dir
            config_loader = create_test_config_loader(child_dir)
            protocols = config_loader.discovered_protocols

            # Child should override parent
            assert_equal "Child Override", protocols["parent"]["name"]
          end
        ensure
          cleanup_temp_directory(fresh_dir)
        end

        def test_deep_merge_preserves_nested_defaults
          nav_dir = File.join(@test_dir, ".ace", "nav")
          FileUtils.mkdir_p(nav_dir)

          # Partial override of nested config
          custom_settings = {
            "cache" => {
              "enabled" => true
              # ttl and directory not specified
            }
          }

          File.write(File.join(nav_dir, "settings.yml"), custom_settings.to_yaml)

          config_loader = ConfigLoader.new(nav_dir)
          settings = config_loader.load_settings

          # Should have merged values
          assert_equal true, settings["cache"]["enabled"] # Overridden
          assert_equal 3600, settings["cache"]["ttl"] # Default preserved
          assert_equal ".cache/ace-nav", settings["cache"]["directory"] # Default preserved
        end

        def test_sources_for_protocol_delegates_to_registry
          # Mock source registry should return sources for protocols
          sources = @config_loader.sources_for_protocol("test")

          # Sources are loaded by SourceRegistry (tested separately)
          assert_kind_of Array, sources
        end
      end
    end
  end
end