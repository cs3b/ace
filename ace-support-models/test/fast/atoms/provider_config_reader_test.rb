# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"

class ProviderConfigReaderTest < AceModelsTestCase
  def setup
    @reader = Ace::Support::Models::Atoms::ProviderConfigReader
  end

  def test_read_file_returns_parsed_yaml
    with_temp_config_dir do |dir|
      config = {
        "name" => "test-provider",
        "models" => ["model-1", "model-2"]
      }
      write_config(dir, "test.yml", config)

      result = @reader.read_file(File.join(dir, "test.yml"))

      assert_equal "test-provider", result["name"]
      assert_equal ["model-1", "model-2"], result["models"]
    end
  end

  def test_read_file_returns_nil_for_missing_file
    result = @reader.read_file("/nonexistent/path/file.yml")

    assert_nil result
  end

  def test_read_file_raises_on_invalid_yaml
    with_temp_config_dir do |dir|
      File.write(File.join(dir, "invalid.yml"), "invalid: yaml: content:")

      assert_raises(Ace::Support::Models::ConfigError) do
        @reader.read_file(File.join(dir, "invalid.yml"))
      end
    end
  end

  def test_read_directory_returns_all_configs
    with_temp_config_dir do |dir|
      write_config(dir, "provider1.yml", {"name" => "provider1", "models" => ["m1"]})
      write_config(dir, "provider2.yml", {"name" => "provider2", "models" => ["m2"]})

      result = @reader.read_directory(dir)

      assert_equal 2, result.size
      assert result.key?("provider1")
      assert result.key?("provider2")
      assert_equal "provider1", result["provider1"]["name"]
      assert_equal "provider2", result["provider2"]["name"]
    end
  end

  def test_read_directory_skips_template_files
    with_temp_config_dir do |dir|
      write_config(dir, "provider.yml", {"name" => "provider"})
      write_config(dir, "template.yml", {"name" => "template"})
      write_config(dir, "example.yml.example", {"name" => "example"})

      result = @reader.read_directory(dir)

      assert_equal 1, result.size
      assert result.key?("provider")
      refute result.key?("template")
    end
  end

  def test_read_directory_adds_source_file_metadata
    with_temp_config_dir do |dir|
      write_config(dir, "provider.yml", {"name" => "provider"})

      result = @reader.read_directory(dir)

      assert_equal File.join(dir, "provider.yml"), result["provider"]["_source_file"]
    end
  end

  def test_extract_models_from_array
    config = {"models" => ["model-1", "model-2", "model-3"]}

    result = @reader.extract_models(config)

    assert_equal ["model-1", "model-2", "model-3"], result
  end

  def test_extract_models_from_hash
    config = {"models" => {"model-1" => {}, "model-2" => {}}}

    result = @reader.extract_models(config)

    assert_equal ["model-1", "model-2"], result
  end

  def test_extract_models_returns_empty_for_nil
    config = {"name" => "provider"}

    result = @reader.extract_models(config)

    assert_equal [], result
  end

  def test_extract_models_returns_empty_for_invalid_type
    config = {"models" => "invalid"}

    result = @reader.extract_models(config)

    assert_equal [], result
  end

  def test_config_directories_with_override
    with_temp_config_dir do |dir|
      result = @reader.config_directories(config_dir: dir)

      assert_equal [dir], result
    end
  end

  def test_config_directories_skips_nonexistent_override
    result = @reader.config_directories(config_dir: "/nonexistent/path")

    assert_equal [], result
  end

  def test_read_all_merges_configs
    with_temp_config_dir do |dir1|
      with_temp_config_dir do |dir2|
        write_config(dir1, "provider.yml", {"name" => "provider", "version" => "1"})
        write_config(dir2, "provider.yml", {"name" => "provider", "version" => "2"})

        # When using config_dir override, only that dir is used
        result = @reader.read_all(config_dir: dir1)

        assert_equal 1, result.size
        assert_equal "1", result["provider"]["version"]
      end
    end
  end

  # models_dev_id extraction tests
  def test_extract_models_dev_id_returns_explicit_value
    config = {"name" => "claude", "models_dev_id" => "anthropic"}

    result = @reader.extract_models_dev_id(config)

    assert_equal "anthropic", result
  end

  def test_extract_models_dev_id_falls_back_to_name
    config = {"name" => "anthropic"}

    result = @reader.extract_models_dev_id(config)

    assert_equal "anthropic", result
  end

  def test_extract_models_dev_id_returns_nil_when_no_name
    config = {}

    result = @reader.extract_models_dev_id(config)

    assert_nil result
  end

  # last_synced extraction tests
  def test_extract_last_synced_from_string
    config = {"last_synced" => "2025-12-01"}

    result = @reader.extract_last_synced(config)

    assert_equal Date.new(2025, 12, 1), result
  end

  def test_extract_last_synced_from_date
    config = {"last_synced" => Date.new(2025, 11, 15)}

    result = @reader.extract_last_synced(config)

    assert_equal Date.new(2025, 11, 15), result
  end

  def test_extract_last_synced_returns_nil_when_missing
    config = {"name" => "provider"}

    result = @reader.extract_last_synced(config)

    assert_nil result
  end

  def test_extract_last_synced_returns_nil_for_invalid_date
    config = {"last_synced" => "not-a-date"}

    result = @reader.extract_last_synced(config)

    assert_nil result
  end

  def test_extract_last_synced_returns_nil_for_invalid_type
    config = {"last_synced" => 12345}

    result = @reader.extract_last_synced(config)

    assert_nil result
  end

  private

  def with_temp_config_dir
    Dir.mktmpdir("ace-llm-provider-config-test") do |dir|
      yield dir
    end
  end

  def write_config(dir, filename, config)
    File.write(File.join(dir, filename), YAML.dump(config))
  end
end
