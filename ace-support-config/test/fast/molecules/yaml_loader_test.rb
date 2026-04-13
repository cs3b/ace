# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Molecules
        class YamlLoaderTest < TestCase
          def test_load_file_returns_config
            with_temp_config(
              "test.yml" => "key: value"
            ) do |tmpdir|
              path = File.join(tmpdir, "test.yml")

              config = YamlLoader.load_file(path)

              assert_instance_of Models::Config, config
              assert_equal "value", config.get("key")
            end
          end

          def test_load_file_raises_for_missing_file
            assert_raises(ConfigNotFoundError) do
              YamlLoader.load_file("/nonexistent/path.yml")
            end
          end

          def test_load_file_sets_source
            with_temp_config(
              "test.yml" => "key: value"
            ) do |tmpdir|
              path = File.join(tmpdir, "test.yml")

              config = YamlLoader.load_file(path)

              assert_equal path, config.source
            end
          end

          def test_load_file_safe_returns_config
            with_temp_config(
              "test.yml" => "key: value"
            ) do |tmpdir|
              path = File.join(tmpdir, "test.yml")

              config = YamlLoader.load_file_safe(path)

              assert_instance_of Models::Config, config
              assert_equal "value", config.get("key")
            end
          end

          def test_load_file_safe_returns_empty_for_missing
            config = YamlLoader.load_file_safe("/nonexistent/path.yml")

            assert_instance_of Models::Config, config
            assert_empty config.data
          end

          def test_save_file_creates_file
            with_temp_config({}) do |tmpdir|
              path = File.join(tmpdir, "output.yml")
              config = Models::Config.new({"key" => "value"})

              YamlLoader.save_file(config, path)

              assert File.exist?(path)
              content = File.read(path)
              assert content.include?("key")
            end
          end

          def test_save_file_creates_directories
            with_temp_config({}) do |tmpdir|
              path = File.join(tmpdir, "nested", "dir", "output.yml")

              YamlLoader.save_file({"key" => "value"}, path)

              assert File.exist?(path)
            end
          end

          def test_save_file_accepts_hash
            with_temp_config({}) do |tmpdir|
              path = File.join(tmpdir, "output.yml")

              YamlLoader.save_file({"key" => "value"}, path)

              assert File.exist?(path)
            end
          end

          def test_load_and_merge_combines_configs
            with_temp_config(
              "config1.yml" => "key1: value1\nshared: from1",
              "config2.yml" => "key2: value2\nshared: from2"
            ) do |tmpdir|
              path1 = File.join(tmpdir, "config1.yml")
              path2 = File.join(tmpdir, "config2.yml")

              config = YamlLoader.load_and_merge(path1, path2)

              assert_equal "value1", config.get("key1")
              assert_equal "value2", config.get("key2")
              # Later files override
              assert_equal "from2", config.get("shared")
            end
          end

          def test_load_and_merge_respects_strategy
            with_temp_config(
              "config1.yml" => "arr:\n  - a\n  - b",
              "config2.yml" => "arr:\n  - c\n  - d"
            ) do |tmpdir|
              path1 = File.join(tmpdir, "config1.yml")
              path2 = File.join(tmpdir, "config2.yml")

              config = YamlLoader.load_and_merge(path1, path2, merge_strategy: :concat)

              assert_equal %w[a b c d], config.get("arr")
            end
          end

          def test_load_and_merge_handles_missing_files
            with_temp_config(
              "exists.yml" => "key: value"
            ) do |tmpdir|
              existing = File.join(tmpdir, "exists.yml")
              missing = File.join(tmpdir, "missing.yml")

              config = YamlLoader.load_and_merge(existing, missing)

              assert_equal "value", config.get("key")
            end
          end

          def test_load_and_merge_returns_empty_for_no_files
            config = YamlLoader.load_and_merge

            assert_instance_of Models::Config, config
            assert_empty config.data
          end

          def test_load_file_handles_empty_file
            with_temp_config(
              "empty.yml" => ""
            ) do |tmpdir|
              path = File.join(tmpdir, "empty.yml")

              config = YamlLoader.load_file(path)

              assert_instance_of Models::Config, config
              assert_empty config.data
            end
          end

          def test_load_file_handles_nested_yaml
            yaml_content = <<~YAML
              level1:
                level2:
                  level3: deep
            YAML

            with_temp_config(
              "nested.yml" => yaml_content
            ) do |tmpdir|
              path = File.join(tmpdir, "nested.yml")

              config = YamlLoader.load_file(path)

              assert_equal "deep", config.get("level1", "level2", "level3")
            end
          end
        end
      end
    end
  end
end
