# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/molecules/config_loader"
require "tempfile"
require "yaml"

class ConfigLoaderTest < Minitest::Test
  def setup
    @loader = Ace::TestRunner::Molecules::ConfigLoader.new
  end

  def test_load_default_config_when_no_file_exists
    File.stub :exist?, false do
      config = @loader.load
      assert_equal 1, config[:version]
      assert config[:patterns].is_a?(Hash)
      assert config[:groups].is_a?(Hash)
      assert config[:defaults].is_a?(Hash)
    end
  end

  def test_load_from_specific_file
    Tempfile.create(["test-runner", ".yml"]) do |file|
      config_data = {
        version: 1,
        patterns: {
          custom: "test/custom/**/*_test.rb"
        },
        groups: {
          custom_group: ["custom"]
        },
        defaults: {
          reporter: "markdown"
        }
      }
      file.write(YAML.dump(config_data))
      file.rewind

      config = @loader.load(file.path)
      assert_equal "test/custom/**/*_test.rb", config[:patterns][:custom]
      assert_equal ["custom"], config[:groups][:custom_group]
      assert_equal "markdown", config[:defaults][:reporter]
    end
  end

  def test_merge_with_default_config
    Tempfile.create(["test-runner", ".yml"]) do |file|
      config_data = {
        version: 1,
        patterns: {
          custom: "test/custom/**/*_test.rb"
        }
      }
      file.write(YAML.dump(config_data))
      file.rewind

      config = @loader.load(file.path)
      # Should have both custom and default patterns
      assert config[:patterns][:custom]
      assert config[:patterns][:atoms]
      assert config[:patterns][:molecules]
    end
  end

  def test_merge_with_options
    config = {
      version: 1,
      patterns: {},
      groups: {},
      defaults: {
        reporter: "progress",
        color: "auto",
        fail_fast: false
      }
    }

    options = {
      format: "markdown",
      color: false,
      fail_fast: true,
      report_dir: "custom-reports"
    }

    merged = @loader.merge_with_options(config, options)
    assert_equal "markdown", merged.defaults[:reporter]
    assert_equal false, merged.defaults[:color]
    assert_equal true, merged.defaults[:fail_fast]
    assert_equal "custom-reports", merged.defaults[:report_dir]
  end

  def test_handle_invalid_yaml
    Tempfile.create(["test-runner", ".yml"]) do |file|
      file.write("invalid: yaml: content: [")
      file.rewind

      # Should fall back to default config with warning
      config = @loader.load(file.path)
      assert_equal 1, config[:version]
    end
  end

  def test_validate_config_version
    config = { patterns: {}, groups: {} }
    validated = @loader.send(:validate_config, config)
    assert_equal 1, validated[:version]
  end

  def test_normalize_config_ensures_all_sections
    config = { version: 1 }
    normalized = @loader.send(:normalize_config, config)
    assert normalized[:patterns]
    assert normalized[:groups]
    assert normalized[:defaults]
  end

  def test_find_config_in_default_paths
    # Test that it searches for config in default locations
    Ace::TestRunner::Molecules::ConfigLoader::DEFAULT_CONFIG_PATHS.each do |path|
      File.stub :exist?, ->(p) { p == path } do
        File.stub :read, "version: 1\npatterns: {}" do
          YAML.stub :safe_load, { version: 1, patterns: {} } do
            config = @loader.send(:find_and_load_config)
            assert config
            break
          end
        end
      end
    end
  end
end