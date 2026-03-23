# frozen_string_literal: true

require "test_helper"
require "ace/support/config"

class YamlLoaderTest < AceTestCase
  def test_loads_valid_yaml
    with_temp_dir do
      yaml_content = {
        "ace" => {
          "test" => "value",
          "nested" => {
            "key" => "data"
          }
        }
      }.to_yaml

      create_config_file("test.yml", yaml_content)

      config = Ace::Support::Config::Molecules::YamlLoader.load_file("test.yml")

      assert_equal "value", config.get("ace", "test")
      assert_equal "data", config.get("ace", "nested", "key")
      assert_equal "test.yml", config.source
    end
  end

  def test_handles_missing_file
    assert_raises(Ace::Support::Config::ConfigNotFoundError) do
      Ace::Support::Config::Molecules::YamlLoader.load_file("nonexistent.yml")
    end
  end

  def test_handles_missing_file_safe
    config = Ace::Support::Config::Molecules::YamlLoader.load_file_safe("nonexistent.yml")

    assert config.empty?
    assert_includes config.source, "not found"
  end

  def test_saves_config_to_file
    with_temp_dir do
      config = Ace::Support::Config::Models::Config.new(
        {
          "ace" => {
            "saved" => true,
            "version" => "1.0.0"
          }
        }
      )

      Ace::Support::Config::Molecules::YamlLoader.save_file(config, "output.yml")

      assert File.exist?("output.yml")

      loaded = Ace::Support::Config::Molecules::YamlLoader.load_file("output.yml")
      assert_equal true, loaded.get("ace", "saved")
      assert_equal "1.0.0", loaded.get("ace", "version")
    end
  end

  def test_saves_hash_to_file
    with_temp_dir do
      data = {
        "ace" => {
          "test" => "value"
        }
      }

      Ace::Support::Config::Molecules::YamlLoader.save_file(data, "hash_output.yml")

      assert File.exist?("hash_output.yml")

      loaded = Ace::Support::Config::Molecules::YamlLoader.load_file("hash_output.yml")
      assert_equal "value", loaded.get("ace", "test")
    end
  end

  def test_creates_directory_when_saving
    with_temp_dir do
      config = Ace::Support::Config::Models::Config.new({"test" => "data"})

      Ace::Support::Config::Molecules::YamlLoader.save_file(config, "deep/nested/path/file.yml")

      assert File.exist?("deep/nested/path/file.yml")
      assert File.directory?("deep/nested/path")
    end
  end

  def test_load_and_merge_multiple_files
    with_temp_dir do
      config1 = {
        "ace" => {
          "file1" => "value1",
          "shared" => "override1"
        }
      }

      config2 = {
        "ace" => {
          "file2" => "value2",
          "shared" => "override2"
        }
      }

      create_config_file("config1.yml", config1.to_yaml)
      create_config_file("config2.yml", config2.to_yaml)

      merged = Ace::Support::Config::Molecules::YamlLoader.load_and_merge(
        "config1.yml",
        "config2.yml"
      )

      assert_equal "value1", merged.get("ace", "file1")
      assert_equal "value2", merged.get("ace", "file2")
      assert_equal "override2", merged.get("ace", "shared") # Later file wins
      assert_includes merged.source, "merged"
    end
  end

  def test_load_and_merge_with_missing_files
    with_temp_dir do
      config1 = {"ace" => {"exists" => true}}
      create_config_file("exists.yml", config1.to_yaml)

      merged = Ace::Support::Config::Molecules::YamlLoader.load_and_merge(
        "exists.yml",
        "missing.yml"
      )

      assert_equal true, merged.get("ace", "exists")
      refute merged.empty?
    end
  end

  def test_load_and_merge_empty_list
    merged = Ace::Support::Config::Molecules::YamlLoader.load_and_merge([])

    assert merged.empty?
    assert_equal "empty", merged.source
  end

  def test_handles_invalid_yaml_gracefully
    with_temp_dir do
      # Create invalid YAML file
      File.write("invalid.yml", "this is not: valid: yaml: ::::")

      assert_raises(Ace::Support::Config::YamlParseError) do
        Ace::Support::Config::Molecules::YamlLoader.load_file("invalid.yml")
      end
    end
  end

  def test_handles_io_errors_on_save
    with_temp_dir do
      # Create a file and make it read-only to cause an IO error
      FileUtils.mkdir_p("readonly")
      FileUtils.chmod(0o444, "readonly")

      config = Ace::Support::Config::Models::Config.new({"test" => "data"})

      assert_raises(IOError) do
        Ace::Support::Config::Molecules::YamlLoader.save_file(config, "readonly/subdir/file.yml")
      end
    ensure
      FileUtils.chmod(0o755, "readonly") if File.exist?("readonly")
    end
  end
end
