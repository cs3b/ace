# frozen_string_literal: true

require_relative "../../test_helper"
require "stringio"
require "tmpdir"

class ProviderSyncOrchestratorTest < AceModelsTestCase
  def setup
    @output = StringIO.new
    @cache_manager = Minitest::Mock.new
    @orchestrator = Ace::Support::Models::Organisms::ProviderSyncOrchestrator.new(
      cache_manager: @cache_manager,
      output: @output
    )
  end

  def test_sync_raises_error_when_no_cache
    @cache_manager.expect :exists?, false

    assert_raises(Ace::Support::Models::CacheError) do
      @orchestrator.sync(config_dir: "/nonexistent")
    end

    @cache_manager.verify
  end

  def test_sync_returns_error_when_no_configs_found
    @cache_manager.expect :exists?, true
    @cache_manager.expect :fresh?, true do |max_age:|
      max_age == 604_800
    end

    result = @orchestrator.sync(config_dir: "/nonexistent")

    assert_equal :error, result[:status]
    assert_match(/No provider configs found/, result[:message])
    @cache_manager.verify
  end

  def test_sync_generates_diff_for_providers
    with_temp_config_and_cache do |config_dir|
      result = @orchestrator.sync(config_dir: config_dir, show_all: true)

      assert_equal :ok, result[:status]
      assert result[:diff].key?("anthropic")
      assert result[:summary][:providers_synced] > 0
    end
  end

  def test_sync_detects_new_models
    with_temp_config_and_cache do |config_dir|
      result = @orchestrator.sync(config_dir: config_dir, show_all: true)

      assert result[:changes_detected]
      assert_includes result[:diff]["anthropic"][:added], "claude-4-opus"
    end
  end

  def test_sync_applies_changes_when_requested
    with_temp_config_and_cache do |config_dir|
      result = @orchestrator.sync(config_dir: config_dir, apply: true, show_all: true)

      assert result[:applied]

      # Verify file was updated
      config = YAML.safe_load_file(File.join(config_dir, "anthropic.yml"), permitted_classes: [Date])
      assert_includes config["models"], "claude-4-opus"
    end
  end

  def test_sync_does_not_apply_when_no_changes
    with_temp_config_and_cache(no_changes: true, synced_limits: true) do |config_dir|
      result = @orchestrator.sync(config_dir: config_dir, apply: true)

      refute result[:changes_detected]
      refute result[:applied]
    end
  end

  def test_sync_detects_limit_only_changes
    with_temp_config_and_cache(no_changes: true, stale_limits: true) do |config_dir|
      result = @orchestrator.sync(config_dir: config_dir, show_all: true)

      assert result[:changes_detected]
      assert result[:diff]["anthropic"][:limits_changed]
    end
  end

  def test_sync_applies_limit_only_changes
    with_temp_config_and_cache(no_changes: true, stale_limits: true) do |config_dir|
      result = @orchestrator.sync(config_dir: config_dir, apply: true, show_all: true)

      assert result[:applied]
      config = YAML.safe_load_file(File.join(config_dir, "anthropic.yml"), permitted_classes: [Date])
      assert_equal({"context" => 1_000_000, "output" => 128_000}, config.dig("limits", "default"))
      assert_equal({"output" => 64_000}, config.dig("limits", "models", "claude-3-sonnet"))
    end
  end

  def test_format_result_shows_added_models
    result = {
      diff: {
        "anthropic" => {
          status: :ok,
          added: ["claude-4-opus"],
          removed: [],
          unchanged: ["claude-3-sonnet"],
          deprecated: []
        }
      },
      summary: {added: 1, removed: 0, unchanged: 1, deprecated: 0, providers_synced: 1, providers_skipped: 0},
      changes_detected: true,
      applied: false,
      committed: false
    }

    output = @orchestrator.format_result(result)

    assert_match(/\+ claude-4-opus/, output)
    assert_match(/Summary: 1 added, 0 removed/, output)
    assert_match(/Run with --apply/, output)
  end

  def test_format_result_shows_removed_models
    result = {
      diff: {
        "anthropic" => {
          status: :ok,
          added: [],
          removed: ["old-model"],
          unchanged: ["claude-3-sonnet"],
          deprecated: []
        }
      },
      summary: {added: 0, removed: 1, unchanged: 1, deprecated: 0, providers_synced: 1, providers_skipped: 0},
      changes_detected: true,
      applied: false,
      committed: false
    }

    output = @orchestrator.format_result(result)

    assert_match(/- old-model/, output)
  end

  def test_format_result_shows_deprecated_models
    result = {
      diff: {
        "anthropic" => {
          status: :ok,
          added: [],
          removed: [],
          unchanged: [],
          deprecated: ["deprecated-model"]
        }
      },
      summary: {added: 0, removed: 0, unchanged: 0, deprecated: 1, providers_synced: 1, providers_skipped: 0},
      changes_detected: false,
      applied: false,
      committed: false
    }

    output = @orchestrator.format_result(result)

    assert_match(/! deprecated-model.*deprecated/, output)
    assert_match(/1 deprecated models flagged/, output)
  end

  def test_format_result_shows_provider_not_found
    result = {
      diff: {
        "unknown" => {
          status: :not_found,
          message: "Not found"
        }
      },
      summary: {added: 0, removed: 0, unchanged: 0, deprecated: 0, providers_synced: 0, providers_skipped: 1},
      changes_detected: false,
      applied: false,
      committed: false
    }

    output = @orchestrator.format_result(result)

    assert_match(/not found in models\.dev/, output)
    assert_match(/1 providers not found/, output)
  end

  def test_format_result_shows_limit_updates
    result = {
      diff: {
        "anthropic" => {
          status: :ok,
          added: [],
          removed: [],
          unchanged: ["claude-3-sonnet"],
          deprecated: [],
          limits_changed: true,
          desired_limits: {
            "default" => {"context" => 1_000_000, "output" => 128_000},
            "models" => {"claude-3-sonnet" => {"output" => 64_000}}
          }
        }
      },
      summary: {added: 0, removed: 0, unchanged: 1, deprecated: 0, limit_updates: 1, providers_synced: 1, providers_skipped: 0},
      changes_detected: true,
      applied: false,
      committed: false
    }

    output = @orchestrator.format_result(result)

    assert_match(/provider limit configs need updates/, output)
    assert_match(/default limits -> context=1,000,000, output=128,000/, output)
    assert_match(/per-model limit overrides: claude-3-sonnet/, output)
  end

  private

  def with_temp_config_and_cache(no_changes: false, stale_limits: false, synced_limits: false)
    Dir.mktmpdir("ace-llm-provider-sync-test") do |dir|
      # Create provider config
      config = {
        "name" => "anthropic",
        "models" => no_changes ? ["claude-3-sonnet", "claude-4-opus"] : ["claude-3-sonnet"]
      }
      if stale_limits
        config["limits"] = {
          "default" => {"context" => 200_000, "output" => 64_000}
        }
      elsif synced_limits
        config["limits"] = {
          "default" => {"context" => 1_000_000, "output" => 128_000},
          "models" => {"claude-3-sonnet" => {"output" => 64_000}}
        }
      end
      File.write(File.join(dir, "anthropic.yml"), YAML.dump(config))

      # Setup mock cache manager
      models_dev_data = {
        "anthropic" => {
          "id" => "anthropic",
          "models" => {
            "claude-3-sonnet" => {
              "name" => "Claude 3 Sonnet",
              "limit" => {"context" => 1_000_000, "output" => 64_000}
            },
            "claude-4-opus" => {
              "name" => "Claude 4 Opus",
              "limit" => {"context" => 1_000_000, "output" => 128_000}
            }
          }
        }
      }

      @cache_manager.expect :exists?, true
      @cache_manager.expect :fresh?, true do |max_age:|
        max_age == 604_800
      end
      @cache_manager.expect :read, models_dev_data

      yield dir
    end
  end
end
