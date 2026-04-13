# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"

class ProviderConfigWriterTest < AceModelsTestCase
  def setup
    @writer = Ace::Support::Models::Atoms::ProviderConfigWriter
  end

  def test_update_models_replaces_model_list
    with_temp_config_dir do |dir|
      path = File.join(dir, "provider.yml")
      original = <<~YAML
        name: test-provider
        models:
          - old-model-1
          - old-model-2
        aliases:
          global:
            test: model
      YAML
      File.write(path, original)

      @writer.update_models(path, ["new-model-1", "new-model-2", "new-model-3"])

      result = YAML.safe_load_file(path)
      assert_equal ["new-model-1", "new-model-2", "new-model-3"], result["models"]
      assert_equal "test-provider", result["name"]
      assert_equal({"global" => {"test" => "model"}}, result["aliases"])
    end
  end

  def test_update_models_preserves_other_fields
    with_temp_config_dir do |dir|
      path = File.join(dir, "provider.yml")
      original = <<~YAML
        name: anthropic
        class: Ace::LLM::Organisms::AnthropicClient
        gem: ace-llm
        models:
          - claude-3-5-sonnet-20241022
        aliases:
          global:
            opus: anthropic:o
          model:
            s: claude-3-5-sonnet-20241022
        api_key:
          env: ANTHROPIC_API_KEY
          required: true
        capabilities:
          - text_generation
          - streaming
        default_options:
          temperature: 0.7
          max_tokens: 4096
      YAML
      File.write(path, original)

      @writer.update_models(path, ["claude-4-opus", "claude-4-sonnet"])

      result = YAML.safe_load_file(path)
      assert_equal ["claude-4-opus", "claude-4-sonnet"], result["models"]
      assert_equal "anthropic", result["name"]
      assert_equal "Ace::LLM::Organisms::AnthropicClient", result["class"]
      assert_equal "ANTHROPIC_API_KEY", result["api_key"]["env"]
      assert_includes result["capabilities"], "text_generation"
      assert_equal 0.7, result["default_options"]["temperature"]
    end
  end

  def test_update_models_raises_for_missing_file
    assert_raises(Ace::Support::Models::ConfigError) do
      @writer.update_models("/nonexistent/path.yml", ["model"])
    end
  end

  def test_update_models_raises_for_inline_comment
    with_temp_config_dir do |dir|
      path = File.join(dir, "provider.yml")
      original = <<~YAML
        name: test-provider
        models: # my models list
          - model-1
      YAML
      File.write(path, original)

      error = assert_raises(Ace::Support::Models::ConfigError) do
        @writer.update_models(path, ["new-model"])
      end
      assert_match(/inline comment/i, error.message)
      assert_match(/models:/i, error.message)
    end
  end

  def test_update_models_raises_for_flow_style_array
    with_temp_config_dir do |dir|
      path = File.join(dir, "provider.yml")
      original = <<~YAML
        name: test-provider
        models: [model-1, model-2]
      YAML
      File.write(path, original)

      error = assert_raises(Ace::Support::Models::ConfigError) do
        @writer.update_models(path, ["new-model"])
      end
      assert_match(/flow-style/i, error.message)
    end
  end

  def test_write_creates_new_file
    with_temp_config_dir do |dir|
      path = File.join(dir, "new_provider.yml")
      config = {
        "name" => "new-provider",
        "models" => ["model-1", "model-2"]
      }

      @writer.write(path, config)

      assert File.exist?(path)
      result = YAML.safe_load_file(path)
      assert_equal "new-provider", result["name"]
      assert_equal ["model-1", "model-2"], result["models"]
    end
  end

  def test_write_creates_parent_directory
    with_temp_config_dir do |dir|
      path = File.join(dir, "subdir", "nested", "provider.yml")
      config = {"name" => "provider"}

      @writer.write(path, config)

      assert File.exist?(path)
    end
  end

  def test_backup_creates_timestamped_copy
    with_temp_config_dir do |dir|
      path = File.join(dir, "provider.yml")
      File.write(path, "name: test")

      backup_path = @writer.backup(path)

      assert_match(/provider\.yml\.backup\.\d{8}_\d{6}$/, backup_path)
      assert File.exist?(backup_path)
      assert_equal "name: test", File.read(backup_path)
    end
  end

  def test_backup_returns_nil_for_missing_file
    result = @writer.backup("/nonexistent/file.yml")

    assert_nil result
  end

  # last_synced tests
  def test_update_last_synced_replaces_existing_field
    with_temp_config_dir do |dir|
      path = File.join(dir, "provider.yml")
      original = <<~YAML
        name: anthropic
        last_synced: 2025-11-01
        models:
          - model-1
      YAML
      File.write(path, original)

      @writer.update_last_synced(path, Date.new(2025, 12, 5))

      result = YAML.safe_load_file(path, permitted_classes: [Date])
      assert_equal Date.new(2025, 12, 5), result["last_synced"]
      assert_equal "anthropic", result["name"]
    end
  end

  def test_update_last_synced_adds_field_if_missing
    with_temp_config_dir do |dir|
      path = File.join(dir, "provider.yml")
      original = <<~YAML
        name: anthropic
        models:
          - model-1
      YAML
      File.write(path, original)

      @writer.update_last_synced(path, Date.new(2025, 12, 5))

      result = YAML.safe_load_file(path, permitted_classes: [Date])
      assert_equal Date.new(2025, 12, 5), result["last_synced"]
      assert_equal "anthropic", result["name"]
    end
  end

  def test_update_last_synced_raises_for_missing_file
    assert_raises(Ace::Support::Models::ConfigError) do
      @writer.update_last_synced("/nonexistent/path.yml")
    end
  end

  def test_update_models_and_sync_date_updates_both
    with_temp_config_dir do |dir|
      path = File.join(dir, "provider.yml")
      original = <<~YAML
        name: anthropic
        models:
          - old-model
      YAML
      File.write(path, original)

      @writer.update_models_and_sync_date(path, ["new-model-1", "new-model-2"], Date.new(2025, 12, 5))

      result = YAML.safe_load_file(path, permitted_classes: [Date])
      assert_equal ["new-model-1", "new-model-2"], result["models"]
      assert_equal Date.new(2025, 12, 5), result["last_synced"]
    end
  end

  def test_update_models_and_sync_date_preserves_other_fields
    with_temp_config_dir do |dir|
      path = File.join(dir, "provider.yml")
      original = <<~YAML
        name: anthropic
        models_dev_id: anthropic
        last_synced: 2025-11-01
        models:
          - old-model
        aliases:
          model:
            s: sonnet
      YAML
      File.write(path, original)

      @writer.update_models_and_sync_date(path, ["claude-4"], Date.new(2025, 12, 5))

      result = YAML.safe_load_file(path, permitted_classes: [Date])
      assert_equal ["claude-4"], result["models"]
      assert_equal Date.new(2025, 12, 5), result["last_synced"]
      assert_equal "anthropic", result["models_dev_id"]
      assert_equal({"model" => {"s" => "sonnet"}}, result["aliases"])
    end
  end

  private

  def with_temp_config_dir
    Dir.mktmpdir("ace-llm-provider-config-test") do |dir|
      yield dir
    end
  end
end
