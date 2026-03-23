# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      class ConfigCascadeEdgeTest < TestCase
        def test_config_with_very_deep_nesting
          # Test that deeply nested configuration structures are handled correctly
          deep_yaml = <<~YAML
            ace:
              level1:
                level2:
                  level3:
                    level4:
                      level5:
                        level6:
                          level7:
                            level8:
                              level9:
                                level10: deep_value
          YAML

          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => deep_yaml
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            result = resolver.get(
              "ace", "level1", "level2", "level3", "level4",
              "level5", "level6", "level7", "level8", "level9", "level10"
            )

            assert_equal "deep_value", result
          end
        end

        def test_config_with_conflicting_types_at_same_path
          # Test priority resolution when different levels provide different types
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "feature:\n  - array\n  - values"
            },
            "subdir" => {
              ".ace" => {
                "settings.yml" => "feature: string_value"
              }
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir")) do
              resolver = Ace::Support::Config.create

              config = resolver.resolve

              # Subdir config should win (higher priority)
              result = config.get("feature")
              assert_equal "string_value", result
            end
          end
        end

        def test_config_cascade_with_nil_values
          # Test that nil values are handled correctly in cascade
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "setting: home_value"
            },
            "subdir" => {
              ".ace" => {
                "settings.yml" => "setting: ~"
              }
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir")) do
              resolver = Ace::Support::Config.create

              config = resolver.resolve

              # Subdir nil should override root value
              result = config.get("setting")
              assert_nil result
            end
          end
        end

        def test_config_with_empty_hashes_and_arrays
          # Test that empty collections are preserved
          yaml = <<~YAML
            ace:
              empty_hash: {}
              empty_array: []
              nested:
                also_empty: {}
          YAML

          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => yaml
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            config = resolver.resolve

            assert_equal({}, config.get("ace", "empty_hash"))
            assert_equal([], config.get("ace", "empty_array"))
            assert_equal({}, config.get("ace", "nested", "also_empty"))
          end
        end

        def test_config_with_special_yaml_values
          # Test handling of special YAML values
          yaml = <<~YAML
            ace:
              bool_true: true
              bool_false: false
              number_int: 42
              number_float: 3.14
              string_number: "123"
              string_bool: "true"
          YAML

          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => yaml
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            config = resolver.resolve

            assert_equal true, config.get("ace", "bool_true")
            assert_equal false, config.get("ace", "bool_false")
            assert_equal 42, config.get("ace", "number_int")
            assert_equal 3.14, config.get("ace", "number_float")
            assert_equal "123", config.get("ace", "string_number")
            assert_equal "true", config.get("ace", "string_bool")
          end
        end

        def test_config_priority_with_multiple_files_same_level
          # Test that when multiple config files exist at same level, they merge correctly
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "config1.yml" => "feature1: value1\nshared: from_config1",
              "config2.yml" => "feature2: value2\nshared: from_config2"
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            # Request both config files
            config = resolver.resolve_file(["config1.yml", "config2.yml"])

            # Both features should be present
            assert_equal "value1", config.get("feature1")
            assert_equal "value2", config.get("feature2")
          end
        end

        def test_config_with_very_long_keys
          # Test that very long key paths are handled
          long_key = "very_long_key_name_" * 10
          yaml = <<~YAML
            ace:
              #{long_key}: long_key_value
          YAML

          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => yaml
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            config = resolver.resolve

            result = config.get("ace", long_key)
            assert_equal "long_key_value", result
          end
        end

        def test_config_with_unicode_keys_and_values
          # Test that unicode in config works correctly
          yaml = <<~YAML
            ace:
              café: résumé
              nested:
                ключ: значение
          YAML

          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => yaml
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            config = resolver.resolve

            assert_equal "résumé", config.get("ace", "café")
            assert_equal "значение", config.get("ace", "nested", "ключ")
          end
        end

        def test_config_cascade_with_array_merging_strategies
          # Test different array merging behaviors
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "features:\n  - home_feature1\n  - home_feature2"
            },
            "subdir" => {
              ".ace" => {
                "settings.yml" => "features:\n  - project_feature"
              }
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir")) do
              resolver = Ace::Support::Config.create(merge_strategy: :union)

              config = resolver.resolve

              result = config.get("features")
              assert_kind_of Array, result
              assert result.include?("project_feature")
              assert result.include?("home_feature1")
            end
          end
        end

        def test_config_with_large_values
          # Test handling of large config values
          # Reduced from 10_000/1000 to 1_000/100 for faster test execution
          # while still validating handling of moderately large values
          large_string = "x" * 1_000
          large_array = Array.new(100) { |i| "item_#{i}" }

          yaml = <<~YAML
            ace:
              large_string: "#{large_string}"
              large_array:
          YAML

          # Add array items
          large_array.each { |item| yaml += "      - #{item}\n" }

          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => yaml
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            config = resolver.resolve

            assert_equal large_string, config.get("ace", "large_string")
            assert_equal 100, config.get("ace", "large_array").size
          end
        end

        def test_config_resolution_with_missing_intermediate_paths
          # Test accessing deeply nested path when intermediate levels don't exist
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "ace:\n  level1: value1"
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            config = resolver.resolve

            # Accessing non-existent deep path should return nil
            result = config.get("ace", "level1", "level2", "level3")
            assert_nil result
          end
        end

        def test_config_cascade_priority_order
          # Test that cascade priority is strictly enforced
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "level: root\nvalue: 1"
            },
            "subdir" => {
              ".ace" => {
                "settings.yml" => "level: subdir\nvalue: 2"
              },
              "subsubdir" => {
                ".ace" => {
                  "settings.yml" => "level: subsubdir\nvalue: 3"
                }
              }
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir", "subsubdir")) do
              resolver = Ace::Support::Config.create

              config = resolver.resolve

              # Nearest config should always win
              assert_equal "subsubdir", config.get("level")
              assert_equal 3, config.get("value")
            end
          end
        end

        def test_cascade_with_empty_configs
          # Create empty config files
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "",
              "empty.yml" => "{}"
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            config = resolver.resolve

            # Should return empty config without error
            assert_kind_of Models::Config, config
          end
        end

        def test_cascade_with_no_configs
          # No config files exist
          with_temp_config(
            ".git" => ""
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            config = resolver.resolve

            # Should return default empty config
            assert_kind_of Models::Config, config
            assert_equal({}, config.data)
          end
        end

        def test_partial_cascade_missing_intermediate_level
          # Only root and subsubdir configs, no subdir config
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "level: root\nroot_only: root_value"
            },
            "subdir" => {
              "subsubdir" => {
                ".ace" => {
                  "settings.yml" => "level: subsubdir\nsubsubdir_only: subsubdir_value"
                }
              }
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir", "subsubdir")) do
              resolver = Ace::Support::Config.create

              config = resolver.resolve

              # Nearest config should win for level
              assert_equal "subsubdir", config.get("level")
              # Values from root should still be accessible
              assert_equal "root_value", config.get("root_only")
              # Values from subsubdir should be present
              assert_equal "subsubdir_value", config.get("subsubdir_only")
            end
          end
        end

        # === Edge Cases: Filesystem Failures ===

        def test_invalid_yaml_in_cascade_raises_error
          # Test that invalid YAML in any cascade level raises a clear error
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "valid: true"
            },
            "subdir" => {
              ".ace" => {
                "settings.yml" => "invalid:\n  - list\n  bad: indent"
              }
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir")) do
              resolver = Ace::Support::Config.create

              error = assert_raises(YamlParseError) do
                resolver.resolve
              end

              assert_match(/Failed to parse YAML/, error.message)
            end
          end
        end

        def test_invalid_yaml_in_specific_file_raises_error
          # Test resolve_file with invalid YAML
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "broken.yml" => "key: [\nunfinished array"
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            error = assert_raises(YamlParseError) do
              resolver.resolve_file(["broken.yml"])
            end

            assert_match(/Failed to parse YAML/, error.message)
          end
        end

        def test_permission_denied_on_config_file
          skip "Cannot test permission denial on Windows" if Gem.win_platform?

          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |tmpdir|
            config_path = File.join(tmpdir, ".ace", "settings.yml")

            # Remove read permission
            File.chmod(0o000, config_path)

            begin
              resolver = Ace::Support::Config.create

              error = assert_raises(ConfigNotFoundError) do
                resolver.resolve
              end

              assert_match(/Failed to read file/, error.message)
            ensure
              # Restore permission for cleanup
              File.chmod(0o644, config_path)
            end
          end
        end

        def test_permission_denied_on_config_directory
          skip "Cannot test permission denial on Windows" if Gem.win_platform?

          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |tmpdir|
            config_dir = File.join(tmpdir, ".ace")

            # Remove read and execute permission from directory
            File.chmod(0o000, config_dir)

            begin
              resolver = Ace::Support::Config.create

              # Should gracefully handle inaccessible directory
              # (finder won't find files, cascade returns empty)
              config = resolver.resolve
              assert_kind_of Models::Config, config
            ensure
              # Restore permission for cleanup
              File.chmod(0o755, config_dir)
            end
          end
        end

        def test_symlink_loop_in_config_path
          skip "Cannot test symlinks on Windows" if Gem.win_platform?

          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |tmpdir|
            # Create a symlink loop
            loop_dir = File.join(tmpdir, "loop")
            FileUtils.mkdir_p(loop_dir)
            File.symlink(loop_dir, File.join(loop_dir, "self"))

            Dir.chdir(loop_dir) do
              resolver = Ace::Support::Config.create

              # Should not hang or crash on symlink loop
              # The finder should skip or limit traversal
              config = resolver.resolve
              assert_kind_of Models::Config, config
            end
          end
        end

        def test_config_file_is_directory
          # Edge case: config file path is actually a directory
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => {} # Create as directory instead of file
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create

            # Should gracefully skip directories named like config files
            config = resolver.resolve
            assert_kind_of Models::Config, config
            assert_equal({}, config.data)
          end
        end

        def test_binary_content_in_yaml_file
          # Edge case: YAML file contains binary/non-UTF8 content
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: valid\n"
            }
          ) do |tmpdir|
            # Append binary content to the YAML file
            config_path = File.join(tmpdir, ".ace", "settings.yml")
            File.open(config_path, "ab") do |f|
              f.write("\xFF\xFE\x00\x00".b) # BOM-like binary
            end

            resolver = Ace::Support::Config.create

            # Should handle gracefully - either parse what's valid or raise clear error
            begin
              config = resolver.resolve
              # If it parsed, check the valid part was captured
              assert_equal "valid", config.get("key") if config.data.any?
            rescue YamlParseError => e
              assert_match(/Failed to parse/, e.message)
            end
          end
        end
      end
    end
  end
end
