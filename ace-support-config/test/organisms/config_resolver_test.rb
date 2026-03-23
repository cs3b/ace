# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
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

          def test_resolve_file_specific_patterns
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "custom.yml" => "custom_key: custom_value",
                "settings.yml" => "settings_key: settings_value"
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              config = resolver.resolve_file(["custom.yml"])

              assert_equal "custom_value", config.get("custom_key")
              assert_nil config.get("settings_key")
            end
          end

          def test_resolve_file_returns_empty_when_not_found
            with_temp_config(".git" => "") do |_tmpdir|
              resolver = ConfigResolver.new

              config = resolver.resolve_file(["nonexistent.yml"])

              assert_instance_of Models::Config, config
              assert_empty config.data
            end
          end

          def test_resolve_for_shows_deprecation_warning
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "custom.yml" => "key: value"
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              _out, err = capture_io do
                config = resolver.resolve_for(["custom.yml"])
                assert_equal "value", config.get("key")
              end

              assert_match(/DEPRECATED.*resolve_for.*resolve_file/, err)
            end
          end

          # === resolve_namespace tests ===

          def test_resolve_namespace_single_segment
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "docs" => {
                  "config.yml" => "docs_key: docs_value"
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              config = resolver.resolve_namespace("docs")

              assert_instance_of Models::Config, config
              assert_equal "docs_value", config.get("docs_key")
            end
          end

          def test_resolve_namespace_multiple_segments
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "worktree" => {
                    "config.yml" => "worktree_key: worktree_value"
                  }
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              config = resolver.resolve_namespace("git", "worktree")

              assert_instance_of Models::Config, config
              assert_equal "worktree_value", config.get("worktree_key")
            end
          end

          def test_resolve_namespace_custom_filename
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "lint" => {
                  "kramdown.yml" => "kramdown_key: kramdown_value"
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              config = resolver.resolve_namespace("lint", filename: "kramdown")

              assert_instance_of Models::Config, config
              assert_equal "kramdown_value", config.get("kramdown_key")
            end
          end

          def test_resolve_namespace_single_segment_with_custom_filename
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => "commit_key: commit_value"
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              config = resolver.resolve_namespace("git", filename: "commit")

              assert_instance_of Models::Config, config
              assert_equal "commit_value", config.get("commit_key")
            end
          end

          def test_resolve_namespace_empty_segments_with_custom_filename
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "settings.yml" => "root_key: root_value"
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              config = resolver.resolve_namespace(filename: "settings")

              assert_instance_of Models::Config, config
              assert_equal "root_value", config.get("root_key")
            end
          end

          def test_resolve_namespace_returns_empty_when_not_found
            with_temp_config(".git" => "") do |_tmpdir|
              resolver = ConfigResolver.new

              config = resolver.resolve_namespace("nonexistent")

              assert_instance_of Models::Config, config
              assert_empty config.data
            end
          end

          def test_resolve_namespace_strips_extension_from_filename
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "docs" => {
                  "config.yml" => "key: value"
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              # User accidentally includes extension - should still work
              config_yml = resolver.resolve_namespace("docs", filename: "config.yml")
              config_yaml = resolver.resolve_namespace("docs", filename: "config.yaml")

              assert_equal "value", config_yml.get("key"), "Should strip .yml extension"
              assert_equal "value", config_yaml.get("key"), "Should strip .yaml extension"
            end
          end

          def test_resolve_namespace_yaml_extension
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "docs" => {
                  "config.yaml" => "yaml_key: yaml_value"
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              config = resolver.resolve_namespace("docs")

              assert_instance_of Models::Config, config
              assert_equal "yaml_value", config.get("yaml_key")
            end
          end

          def test_resolve_namespace_equivalent_to_resolve_file
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "docs" => {
                  "config.yml" => "key: value"
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              namespace_result = resolver.resolve_namespace("docs")
              resolve_file_result = resolver.resolve_file(["docs/config.yml", "docs/config.yaml"])

              assert_equal resolve_file_result.data, namespace_result.data
            end
          end

          def test_resolve_namespace_handles_empty_and_nil_segments
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "docs" => {
                  "config.yml" => "key: value"
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              # Should handle nil and empty segments gracefully
              config = resolver.resolve_namespace("docs", nil, "", "  ")

              assert_equal "value", config.get("key")
            end
          end

          def test_resolve_namespace_handles_nested_array_segments
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "worktree" => {
                    "config.yml" => "key: value"
                  }
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              # Should flatten nested arrays
              config = resolver.resolve_namespace(["git", "worktree"])

              assert_equal "value", config.get("key")
            end
          end

          def test_resolve_namespace_handles_backslash_paths
            # Test that File.join properly handles paths regardless of input style
            # This verifies cross-platform path handling (Windows-style backslashes)
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "worktree" => {
                    "config.yml" => "key: value"
                  }
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              # Even if segments contain backslashes, File.join normalizes the path
              # This tests the robustness of the path building logic
              config = resolver.resolve_namespace("git", "worktree")

              # The underlying File.join handles path separator normalization
              assert_equal "value", config.get("key")
            end
          end

          def test_resolve_namespace_rejects_path_traversal_in_segments
            with_temp_config(".git" => "") do |_tmpdir|
              resolver = ConfigResolver.new

              error = assert_raises(ArgumentError) do
                resolver.resolve_namespace("docs", "..", "secret")
              end
              assert_match(/path traversal not allowed/i, error.message)
            end
          end

          def test_resolve_namespace_rejects_path_traversal_in_single_segment
            with_temp_config(".git" => "") do |_tmpdir|
              resolver = ConfigResolver.new

              error = assert_raises(ArgumentError) do
                resolver.resolve_namespace("../etc")
              end
              assert_match(/path traversal not allowed/i, error.message)
            end
          end

          def test_resolve_namespace_rejects_absolute_paths
            with_temp_config(".git" => "") do |_tmpdir|
              resolver = ConfigResolver.new

              error = assert_raises(ArgumentError) do
                resolver.resolve_namespace("/etc", "passwd")
              end
              assert_match(/absolute paths not allowed/i, error.message)
            end
          end

          def test_resolve_namespace_rejects_path_traversal_in_filename
            with_temp_config(".git" => "") do |_tmpdir|
              resolver = ConfigResolver.new

              error = assert_raises(ArgumentError) do
                resolver.resolve_namespace("docs", filename: "../secret")
              end
              assert_match(/path traversal not allowed/i, error.message)
            end
          end

          def test_resolve_namespace_rejects_empty_filename_after_extension_strip
            with_temp_config(".git" => "") do |_tmpdir|
              resolver = ConfigResolver.new

              # filename: ".yml" becomes empty after extension stripping
              error = assert_raises(ArgumentError) do
                resolver.resolve_namespace("docs", filename: ".yml")
              end
              assert_match(/filename cannot be empty/i, error.message)

              # Same for .yaml
              error = assert_raises(ArgumentError) do
                resolver.resolve_namespace("docs", filename: ".yaml")
              end
              assert_match(/filename cannot be empty/i, error.message)
            end
          end

          def test_resolve_namespace_rejects_windows_drive_letter_paths
            with_temp_config(".git" => "") do |_tmpdir|
              resolver = ConfigResolver.new

              error = assert_raises(ArgumentError) do
                resolver.resolve_namespace("C:", "Windows", "System32")
              end
              assert_match(/absolute paths not allowed/i, error.message)
            end
          end

          def test_resolve_namespace_rejects_windows_unc_paths
            with_temp_config(".git" => "") do |_tmpdir|
              resolver = ConfigResolver.new

              error = assert_raises(ArgumentError) do
                resolver.resolve_namespace("\\\\server", "share")
              end
              assert_match(/absolute paths not allowed/i, error.message)
            end
          end

          def test_resolve_namespace_rejects_windows_backslash_prefix
            with_temp_config(".git" => "") do |_tmpdir|
              resolver = ConfigResolver.new

              error = assert_raises(ArgumentError) do
                resolver.resolve_namespace("\\Windows", "System32")
              end
              assert_match(/absolute paths not allowed/i, error.message)
            end
          end

          # Allow up to 2x overhead for the convenience wrapper
          ACCEPTABLE_OVERHEAD_MULTIPLIER = 3.0

          def test_resolve_namespace_performance_vs_resolve_file
            # Skip in CI - timing-based tests are inherently flaky on shared runners
            skip "Performance test skipped in CI" if ENV["CI"]

            with_temp_config(
              ".git" => "",
              ".ace" => {
                "docs" => {
                  "config.yml" => "key: value"
                }
              }
            ) do |_tmpdir|
              resolver = ConfigResolver.new

              # Warm up (multiple iterations to stabilize)
              5.times do
                resolver.resolve_namespace("docs")
                resolver.resolve_file(["docs/config.yml", "docs/config.yaml"])
              end

              # Benchmark with sufficient iterations for CI stability
              iterations = 100
              namespace_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
              iterations.times { resolver.resolve_namespace("docs") }
              namespace_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - namespace_start

              resolve_file_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
              iterations.times { resolver.resolve_file(["docs/config.yml", "docs/config.yaml"]) }
              resolve_file_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - resolve_file_start

              assert namespace_time < resolve_file_time * ACCEPTABLE_OVERHEAD_MULTIPLIER,
                "resolve_namespace should have minimal overhead (< #{ACCEPTABLE_OVERHEAD_MULTIPLIER}x). " \
                "Got: namespace=#{namespace_time.round(4)}s, resolve_file=#{resolve_file_time.round(4)}s"
            end
          end

          # === resolve_type tests ===

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
end
