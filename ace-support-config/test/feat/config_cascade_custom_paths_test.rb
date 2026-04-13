# frozen_string_literal: true

require "test_helper"
require "yaml"
require "fileutils"

module Ace
  module Support
    module Config
      class ConfigCascadeCustomPathsTest < TestCase
        def test_config_resolver_with_custom_config_dir
          # Create configs in custom .my-app directory
          with_temp_config(
            ".git" => "",
            ".my-app" => {
              "config.yml" => "source: my-app\nsetting: local"
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create(config_dir: ".my-app")

            config = resolver.resolve_file(["config.yml"])

            assert_equal "my-app", config.get("source")
            assert_equal "local", config.get("setting")
          end
        end

        def test_config_resolver_with_custom_defaults_dir
          # Create configs in custom defaults directory
          with_temp_config(
            ".git" => "",
            ".my-defaults" => {
              "config.yml" => "source: defaults\ndefault_key: default_value"
            }
          ) do |tmpdir|
            resolver = Ace::Support::Config.create(
              defaults_dir: ".my-defaults",
              gem_path: tmpdir
            )

            config = resolver.resolve_file(["config.yml"])

            assert_equal "defaults", config.get("source")
            assert_equal "default_value", config.get("default_key")
          end
        end

        def test_config_cascade_with_custom_dirs_priority
          # Test that user config in .my-app overrides defaults in .my-defaults
          with_temp_config(
            ".git" => "",
            ".my-app" => {
              "config.yml" => "level: user\noverride_key: user_value"
            },
            ".my-defaults" => {
              "config.yml" => "level: defaults\noverride_key: default_value\ndefaults_only: from_defaults"
            }
          ) do |tmpdir|
            resolver = Ace::Support::Config.create(
              config_dir: ".my-app",
              defaults_dir: ".my-defaults",
              gem_path: tmpdir
            )

            config = resolver.resolve_file(["config.yml"])

            # User config should win for shared keys
            assert_equal "user", config.get("level")
            assert_equal "user_value", config.get("override_key")
            # Defaults-only keys should be preserved
            assert_equal "from_defaults", config.get("defaults_only")
          end
        end

        def test_config_resolver_finds_configs_in_custom_paths
          # Create configs in custom paths
          with_temp_config(
            ".git" => "",
            ".custom" => {
              "config.yml" => "source: custom"
            }
          ) do |tmpdir|
            resolver = Ace::Support::Config.create(config_dir: ".custom")

            configs = resolver.find_configs
            existing = configs.select(&:exists)

            assert_operator existing.count, :>=, 1
            assert existing.any? { |c| c.path.include?(".custom") }
          end
        end

        def test_finder_with_custom_config_dir
          with_temp_config(
            ".git" => "",
            ".custom-config" => {
              "file.yml" => "key: value"
            }
          ) do |tmpdir|
            # ConfigFinder.new is used directly with start_path
            finder = Molecules::ConfigFinder.new(
              config_dir: ".custom-config",
              start_path: tmpdir
            )

            path = finder.find_file("file.yml")

            assert path
            assert path.include?(".custom-config")
          end
        end

        def test_virtual_resolver_with_custom_directories
          with_temp_config(
            ".git" => "",
            ".my-app" => {
              "presets" => {
                "default.yml" => "preset: default"
              }
            }
          ) do |tmpdir|
            resolver = Ace::Support::Config.virtual_resolver(
              config_dir: ".my-app",
              start_path: tmpdir
            )

            assert resolver.exists?("presets/default.yml")

            path = resolver.resolve_path("presets/default.yml")
            assert path.include?(".my-app")
          end
        end

        def test_nested_namespace_with_custom_config_dir
          with_temp_config(
            ".git" => "",
            ".my-app" => {
              "git" => {
                "worktree" => {
                  "config.yml" => "worktree_key: worktree_value"
                }
              }
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create(config_dir: ".my-app")

            config = resolver.resolve_namespace("git", "worktree")

            assert_equal "worktree_value", config.get("worktree_key")
          end
        end

        def test_full_cascade_with_custom_directories
          # Test full cascade: cwd > intermediate > project_root > home > gem_defaults
          with_temp_config(
            ".git" => "",
            ".my-app" => {
              "config.yml" => "level: project\nproject_only: true"
            },
            ".my-defaults" => {
              "config.yml" => "level: defaults\ndefaults_only: true\nshared: from_defaults"
            },
            "subdir" => {
              ".my-app" => {
                "config.yml" => "level: subdir\nshared: from_subdir"
              }
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir")) do
              resolver = Ace::Support::Config.create(
                config_dir: ".my-app",
                defaults_dir: ".my-defaults",
                gem_path: tmpdir
              )

              config = resolver.resolve_file(["config.yml"])

              # Subdir wins for level
              assert_equal "subdir", config.get("level")
              # Subdir wins for shared
              assert_equal "from_subdir", config.get("shared")
              # Project-only from root config preserved
              assert_equal true, config.get("project_only")
              # Defaults-only preserved
              assert_equal true, config.get("defaults_only")
            end
          end
        end

        def test_glob_with_custom_directories
          with_temp_config(
            ".git" => "",
            ".my-app" => {
              "presets" => {
                "a.yml" => "a: 1",
                "b.yml" => "b: 2"
              }
            },
            ".my-defaults" => {
              "presets" => {
                "c.yml" => "c: 3"
              }
            }
          ) do |tmpdir|
            resolver = Ace::Support::Config.virtual_resolver(
              config_dir: ".my-app",
              defaults_dir: ".my-defaults",
              gem_path: tmpdir,
              start_path: tmpdir
            )

            matches = resolver.glob("presets/*.yml")

            # Should find files from both user config and defaults
            assert_operator matches.size, :>=, 3
            assert matches.key?("presets/a.yml")
            assert matches.key?("presets/b.yml")
            assert matches.key?("presets/c.yml")
          end
        end

        def test_config_directories_order_with_custom_dirs
          with_temp_config(
            ".git" => "",
            ".my-app" => {
              "file.yml" => "user: value"
            },
            ".my-defaults" => {
              "file.yml" => "default: value"
            }
          ) do |tmpdir|
            resolver = Ace::Support::Config.virtual_resolver(
              config_dir: ".my-app",
              defaults_dir: ".my-defaults",
              gem_path: tmpdir,
              start_path: tmpdir
            )

            dirs = resolver.config_directories

            # User config dirs should come before defaults
            user_idx = dirs.find_index { |d| d.include?(".my-app") }
            defaults_idx = dirs.find_index { |d| d.include?(".my-defaults") }

            assert user_idx, "Should have user config dir"
            assert defaults_idx, "Should have defaults dir"
            assert user_idx < defaults_idx, "User config should have higher priority than defaults"
          end
        end
      end
    end
  end
end
