# frozen_string_literal: true

require "test_helper"

module Ace
  module Config
    module Organisms
      class ConfigResolverTest < TestCase
        def test_resolve_returns_config
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |_tmpdir|
            resolver = ConfigResolver.new

            config = resolver.resolve

            assert_instance_of Models::Config, config
            assert_equal "value", config.get("key")
          end
        end

        def test_resolve_is_memoized
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |_tmpdir|
            resolver = ConfigResolver.new

            first = resolver.resolve
            second = resolver.resolve

            assert_same first, second
          end
        end

        def test_reset_clears_memoized_config
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |_tmpdir|
            resolver = ConfigResolver.new

            first = resolver.resolve
            resolver.reset!
            second = resolver.resolve

            refute_same first, second
          end
        end

        def test_get_returns_value
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |_tmpdir|
            resolver = ConfigResolver.new

            result = resolver.get("key")

            assert_equal "value", result
          end
        end

        def test_get_returns_nested_value
          yaml = <<~YAML
            level1:
              level2:
                key: deep
          YAML

          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => yaml
            }
          ) do |_tmpdir|
            resolver = ConfigResolver.new

            result = resolver.get("level1", "level2", "key")

            assert_equal "deep", result
          end
        end

        def test_resolve_merges_cascade
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "base_key: base\noverride: from_root"
            },
            "subdir" => {
              ".ace" => {
                "settings.yml" => "subdir_key: subdir\noverride: from_subdir"
              }
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir")) do
              resolver = ConfigResolver.new

              config = resolver.resolve

              assert_equal "base", config.get("base_key")
              assert_equal "subdir", config.get("subdir_key")
              assert_equal "from_subdir", config.get("override")
            end
          end
        end

        def test_resolve_for_specific_patterns
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "custom.yml" => "custom_key: custom_value",
              "settings.yml" => "settings_key: settings_value"
            }
          ) do |_tmpdir|
            resolver = ConfigResolver.new

            config = resolver.resolve_for(["custom.yml"])

            assert_equal "custom_value", config.get("custom_key")
            assert_nil config.get("settings_key")
          end
        end

        def test_resolve_for_returns_empty_when_not_found
          with_temp_config(".git" => "") do |_tmpdir|
            resolver = ConfigResolver.new

            config = resolver.resolve_for(["nonexistent.yml"])

            assert_instance_of Models::Config, config
            assert_empty config.data
          end
        end

        def test_resolve_type_returns_local_configs
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |_tmpdir|
            resolver = ConfigResolver.new

            config = resolver.resolve_type(:local)

            assert_instance_of Models::Config, config
            assert_equal "value", config.get("key")
          end
        end

        def test_resolve_type_returns_nil_for_missing_type
          with_temp_config(".git" => "") do |_tmpdir|
            resolver = ConfigResolver.new

            config = resolver.resolve_type(:gem)

            assert_nil config
          end
        end

        def test_find_configs_returns_cascade_paths
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |_tmpdir|
            resolver = ConfigResolver.new

            paths = resolver.find_configs

            assert paths.is_a?(Array)
            assert paths.any? { |p| p.path.include?("settings.yml") }
          end
        end

        def test_custom_config_dir
          with_temp_config(
            ".git" => "",
            ".my-app" => {
              "settings.yml" => "key: value"
            }
          ) do |_tmpdir|
            resolver = ConfigResolver.new(config_dir: ".my-app")

            config = resolver.resolve

            assert_equal "value", config.get("key")
          end
        end

        def test_gem_defaults_merged
          with_temp_config(
            ".git" => "",
            ".my-defaults" => {
              "config.yml" => "default_key: default\noverride: default"
            },
            ".my-app" => {
              "config.yml" => "override: user"
            }
          ) do |tmpdir|
            resolver = ConfigResolver.new(
              config_dir: ".my-app",
              defaults_dir: ".my-defaults",
              gem_path: tmpdir,
              file_patterns: ["config.yml"]
            )

            config = resolver.resolve

            assert_equal "default", config.get("default_key")
            assert_equal "user", config.get("override")
          end
        end

        def test_merge_strategy_replace
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "arr:\n  - a\n  - b"
            },
            "subdir" => {
              ".ace" => {
                "settings.yml" => "arr:\n  - c\n  - d"
              }
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir")) do
              resolver = ConfigResolver.new(merge_strategy: :replace)

              config = resolver.resolve

              assert_equal %w[c d], config.get("arr")
            end
          end
        end

        def test_merge_strategy_concat
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "arr:\n  - a\n  - b"
            },
            "subdir" => {
              ".ace" => {
                "settings.yml" => "arr:\n  - c\n  - d"
              }
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir")) do
              resolver = ConfigResolver.new(merge_strategy: :concat)

              config = resolver.resolve

              assert_equal %w[a b c d], config.get("arr")
            end
          end
        end

        def test_accessors
          resolver = ConfigResolver.new(
            config_dir: ".custom",
            defaults_dir: ".custom-defaults",
            gem_path: "/gem/path",
            merge_strategy: :union
          )

          assert_equal ".custom", resolver.config_dir
          assert_equal ".custom-defaults", resolver.defaults_dir
          assert_equal "/gem/path", resolver.gem_path
          assert_equal :union, resolver.merge_strategy
        end

        def test_create_default_creates_config_file
          with_temp_config({}) do |tmpdir|
            path = File.join(tmpdir, ".ace", "settings.yml")

            config = ConfigResolver.create_default(path)

            assert File.exist?(path)
            assert_instance_of Models::Config, config
            assert config.get("config", "version")
          end
        end
      end
    end
  end
end
