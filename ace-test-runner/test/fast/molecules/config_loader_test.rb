# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/molecules/config_loader"
require "tempfile"
require "yaml"

class ConfigLoaderTest < Minitest::Test
  def setup
    @loader = Ace::TestRunner::Molecules::ConfigLoader.new
    # Reset cached defaults to ensure clean state
    Ace::TestRunner::Molecules::ConfigLoader.reset_gem_defaults!
  end

  def teardown
    # Reset after each test
    Ace::TestRunner::Molecules::ConfigLoader.reset_gem_defaults!
  end

  def test_load_gem_defaults
    defaults = Ace::TestRunner::Molecules::ConfigLoader.load_gem_defaults

    assert_equal 1, defaults[:version]
    assert defaults[:patterns].is_a?(Hash)
    assert defaults[:targets].is_a?(Hash)
    assert defaults[:defaults].is_a?(Hash)
    assert defaults[:failure_limits].is_a?(Hash)
  end

  def test_load_default_config_when_no_file_exists
    # With Ace::Support::Config.create() API, cascade is handled internally
    # This test verifies that load() returns valid config from gem defaults
    config = @loader.load
    assert_equal 1, config[:version]
    assert config[:patterns].is_a?(Hash)
    assert config[:targets].is_a?(Hash)
    assert config[:defaults].is_a?(Hash)
  end

  def test_load_from_specific_file
    Tempfile.create(["test-runner", ".yml"]) do |file|
      # Use string keys to match YAML file format (symbolize_names converts on load)
      config_content = <<~YAML
        version: 1
        patterns:
          custom: "test/custom/**/*_test.rb"
        targets:
          custom_group:
            - custom
        defaults:
          reporter: markdown
      YAML
      file.write(config_content)
      file.rewind

      config = @loader.load(file.path)
      assert_equal "test/custom/**/*_test.rb", config[:patterns][:custom]
      assert_equal ["custom"], config[:targets][:custom_group]
      assert_equal "markdown", config[:defaults][:reporter]
    end
  end

  def test_merge_with_default_config
    Tempfile.create(["test-runner", ".yml"]) do |file|
      # Use string keys to match YAML file format (symbolize_names converts on load)
      config_content = <<~YAML
        version: 1
        patterns:
          custom: "test/custom/**/*_test.rb"
      YAML
      file.write(config_content)
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
      targets: {},
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
    config = {patterns: {}, targets: {}}
    validated = @loader.send(:validate_config, config)
    assert_equal 1, validated[:version]
  end

  def test_normalize_config_ensures_all_sections
    config = {version: 1}
    normalized = @loader.send(:normalize_config, config)
    assert normalized[:patterns]
    assert normalized[:targets]
    assert normalized[:defaults]
    assert normalized[:failure_limits]
  end

  def test_gem_defaults_include_expected_patterns
    defaults = Ace::TestRunner::Molecules::ConfigLoader.load_gem_defaults

    assert_equal "test/{fast/,}atoms/**/*_test.rb", defaults[:patterns][:atoms]
    assert_equal "test/{fast/,}molecules/**/*_test.rb", defaults[:patterns][:molecules]
    assert_equal "test/{fast/,}organisms/**/*_test.rb", defaults[:patterns][:organisms]
  end

  def test_gem_defaults_include_expected_targets
    defaults = Ace::TestRunner::Molecules::ConfigLoader.load_gem_defaults

    assert_includes defaults[:targets][:fast], "atoms"
    assert_includes defaults[:targets][:fast], "molecules"
    refute_includes defaults[:targets].keys.map(&:to_s), "unit"
    refute_includes defaults[:targets].keys.map(&:to_s), "integration"
    assert_includes defaults[:targets][:quick], "atoms"
  end

  def test_gem_defaults_include_expected_defaults
    defaults = Ace::TestRunner::Molecules::ConfigLoader.load_gem_defaults

    assert_equal "progress", defaults[:defaults][:reporter]
    assert_equal "auto", defaults[:defaults][:color]
    assert_equal false, defaults[:defaults][:fail_fast]
    assert_equal true, defaults[:defaults][:save_reports]
    assert_equal ".ace-local/test/reports", defaults[:defaults][:report_dir]
  end

  def test_gem_defaults_include_failure_limits
    defaults = Ace::TestRunner::Molecules::ConfigLoader.load_gem_defaults

    assert_equal 7, defaults[:failure_limits][:max_display]
  end

  def test_reset_gem_defaults_clears_cache
    # Load defaults first
    defaults1 = Ace::TestRunner::Molecules::ConfigLoader.load_gem_defaults

    # Reset and load again - should still work
    Ace::TestRunner::Molecules::ConfigLoader.reset_gem_defaults!
    defaults2 = Ace::TestRunner::Molecules::ConfigLoader.load_gem_defaults

    assert_equal defaults1[:version], defaults2[:version]
  end
end
