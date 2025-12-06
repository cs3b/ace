# frozen_string_literal: true

require_relative "../test_helper"

class ProviderSyncDiffTest < ModelsDevTestCase
  def setup
    @cache_manager = Minitest::Mock.new
    @diff = Ace::LLM::ModelsDev::Molecules::ProviderSyncDiff.new(cache_manager: @cache_manager)
  end

  def test_diff_provider_identifies_added_models
    config = { "models" => ["model-1", "model-2"] }
    provider_data = {
      "models" => {
        "model-1" => { "name" => "Model 1" },
        "model-2" => { "name" => "Model 2" },
        "model-3" => { "name" => "Model 3" },
        "model-4" => { "name" => "Model 4" }
      }
    }

    result = @diff.diff_provider(config, provider_data)

    assert_equal :ok, result[:status]
    assert_equal ["model-3", "model-4"], result[:added]
  end

  def test_diff_provider_identifies_removed_models
    config = { "models" => ["model-1", "model-2", "old-model"] }
    provider_data = {
      "models" => {
        "model-1" => { "name" => "Model 1" },
        "model-2" => { "name" => "Model 2" }
      }
    }

    result = @diff.diff_provider(config, provider_data)

    assert_equal :ok, result[:status]
    assert_equal ["old-model"], result[:removed]
  end

  def test_diff_provider_identifies_unchanged_models
    config = { "models" => ["model-1", "model-2"] }
    provider_data = {
      "models" => {
        "model-1" => { "name" => "Model 1" },
        "model-2" => { "name" => "Model 2" }
      }
    }

    result = @diff.diff_provider(config, provider_data)

    assert_equal :ok, result[:status]
    assert_equal ["model-1", "model-2"], result[:unchanged]
    assert_empty result[:added]
    assert_empty result[:removed]
  end

  def test_diff_provider_identifies_deprecated_models
    config = { "models" => ["model-1", "deprecated-model"] }
    provider_data = {
      "models" => {
        "model-1" => { "name" => "Model 1" },
        "deprecated-model" => { "name" => "Deprecated", "status" => "deprecated" }
      }
    }

    result = @diff.diff_provider(config, provider_data)

    assert_equal :ok, result[:status]
    assert_equal ["deprecated-model"], result[:deprecated]
    assert_equal ["model-1"], result[:unchanged]
  end

  def test_diff_provider_does_not_suggest_adding_deprecated_models
    config = { "models" => ["model-1"] }
    provider_data = {
      "models" => {
        "model-1" => { "name" => "Model 1" },
        "deprecated-model" => { "name" => "Deprecated", "status" => "deprecated" }
      }
    }

    result = @diff.diff_provider(config, provider_data)

    assert_equal :ok, result[:status]
    refute_includes result[:added], "deprecated-model"
  end

  def test_generate_with_provider_filter
    models_dev_data = {
      "anthropic" => {
        "models" => { "claude-1" => {} }
      },
      "openai" => {
        "models" => { "gpt-4" => {} }
      }
    }
    @cache_manager.expect :read, models_dev_data

    current_configs = {
      "anthropic" => { "models" => [] },
      "openai" => { "models" => [] }
    }

    result = @diff.generate(current_configs, provider_filter: "anthropic")

    assert result.key?("anthropic")
    refute result.key?("openai")
    @cache_manager.verify
  end

  def test_generate_marks_unknown_provider_as_not_found
    models_dev_data = {
      "anthropic" => { "models" => {} }
    }
    @cache_manager.expect :read, models_dev_data

    current_configs = {
      "unknown-provider" => { "models" => ["model-1"] }
    }

    result = @diff.generate(current_configs)

    assert_equal :not_found, result["unknown-provider"][:status]
    @cache_manager.verify
  end

  def test_summary_calculates_totals
    results = {
      "provider1" => {
        status: :ok,
        added: ["a", "b"],
        removed: ["c"],
        unchanged: ["d", "e", "f"],
        deprecated: ["g"]
      },
      "provider2" => {
        status: :ok,
        added: ["h"],
        removed: [],
        unchanged: ["i"],
        deprecated: []
      },
      "provider3" => {
        status: :not_found,
        message: "Not found"
      }
    }

    summary = @diff.summary(results)

    assert_equal 3, summary[:added]
    assert_equal 1, summary[:removed]
    assert_equal 4, summary[:unchanged]
    assert_equal 1, summary[:deprecated]
    assert_equal 2, summary[:providers_synced]
    assert_equal 1, summary[:providers_skipped]
  end

  def test_any_changes_returns_true_when_models_added
    results = {
      "provider" => {
        status: :ok,
        added: ["model-1"],
        removed: [],
        unchanged: []
      }
    }

    assert @diff.any_changes?(results)
  end

  def test_any_changes_returns_true_when_models_removed
    results = {
      "provider" => {
        status: :ok,
        added: [],
        removed: ["model-1"],
        unchanged: []
      }
    }

    assert @diff.any_changes?(results)
  end

  def test_any_changes_returns_false_when_no_changes
    results = {
      "provider" => {
        status: :ok,
        added: [],
        removed: [],
        unchanged: ["model-1"]
      }
    }

    refute @diff.any_changes?(results)
  end

  def test_any_changes_ignores_not_found_providers
    results = {
      "provider" => {
        status: :not_found,
        message: "Not found"
      }
    }

    refute @diff.any_changes?(results)
  end

  # Date filtering tests
  def test_diff_provider_filters_by_release_date
    config = { "models" => [] }
    provider_data = {
      "models" => {
        "old-model" => { "name" => "Old", "release_date" => "2025-10-01" },
        "new-model" => { "name" => "New", "release_date" => "2025-12-01" }
      }
    }

    result = @diff.diff_provider(config, provider_data, since_date: Date.new(2025, 11, 1))

    assert_equal ["new-model"], result[:added]
    refute_includes result[:added], "old-model"
  end

  def test_diff_provider_includes_all_models_when_no_date_filter
    config = { "models" => [] }
    provider_data = {
      "models" => {
        "old-model" => { "name" => "Old", "release_date" => "2025-10-01" },
        "new-model" => { "name" => "New", "release_date" => "2025-12-01" }
      }
    }

    result = @diff.diff_provider(config, provider_data)

    assert_includes result[:added], "new-model"
    assert_includes result[:added], "old-model"
  end

  def test_diff_provider_includes_release_dates_in_result
    config = { "models" => [] }
    provider_data = {
      "models" => {
        "new-model" => { "name" => "New", "release_date" => "2025-12-01" }
      }
    }

    result = @diff.diff_provider(config, provider_data)

    assert_equal Date.new(2025, 12, 1), result[:added_with_dates]["new-model"]
  end

  # models_dev_id mapping tests
  def test_generate_uses_models_dev_id_for_lookup
    models_dev_data = {
      "anthropic" => {
        "models" => { "claude-4" => { "name" => "Claude 4" } }
      }
    }
    @cache_manager.expect :read, models_dev_data

    current_configs = {
      "claude" => { "name" => "claude", "models_dev_id" => "anthropic", "models" => [] }
    }

    result = @diff.generate(current_configs, show_all: true)

    assert_equal :ok, result["claude"][:status]
    assert_includes result["claude"][:added], "claude-4"
    @cache_manager.verify
  end

  def test_generate_provides_hint_for_unmapped_providers
    models_dev_data = {
      "anthropic" => { "models" => {} }
    }
    @cache_manager.expect :read, models_dev_data

    current_configs = {
      "claude" => { "name" => "claude", "models" => [] }
    }

    result = @diff.generate(current_configs)

    assert_equal :not_found, result["claude"][:status]
    assert_match(/models_dev_id: anthropic/, result["claude"][:hint])
    @cache_manager.verify
  end

  def test_generate_includes_last_synced_in_result
    models_dev_data = {
      "anthropic" => { "models" => {} }
    }
    @cache_manager.expect :read, models_dev_data

    current_configs = {
      "anthropic" => { "name" => "anthropic", "last_synced" => "2025-12-01", "models" => [] }
    }

    result = @diff.generate(current_configs, show_all: true)

    assert_equal Date.new(2025, 12, 1), result["anthropic"][:last_synced]
    @cache_manager.verify
  end

  def test_generate_with_show_all_ignores_date_filter
    models_dev_data = {
      "anthropic" => {
        "models" => {
          "old-model" => { "release_date" => "2025-01-01" },
          "new-model" => { "release_date" => "2025-12-01" }
        }
      }
    }
    @cache_manager.expect :read, models_dev_data

    current_configs = {
      "anthropic" => { "name" => "anthropic", "last_synced" => "2025-11-01", "models" => [] }
    }

    result = @diff.generate(current_configs, show_all: true)

    assert_includes result["anthropic"][:added], "old-model"
    assert_includes result["anthropic"][:added], "new-model"
    @cache_manager.verify
  end

  def test_generate_with_explicit_since_date
    models_dev_data = {
      "anthropic" => {
        "models" => {
          "old-model" => { "release_date" => "2025-10-01" },
          "new-model" => { "release_date" => "2025-12-01" }
        }
      }
    }
    @cache_manager.expect :read, models_dev_data

    current_configs = {
      "anthropic" => { "name" => "anthropic", "models" => [] }
    }

    result = @diff.generate(current_configs, since_date: Date.new(2025, 11, 1))

    assert_equal ["new-model"], result["anthropic"][:added]
    @cache_manager.verify
  end
end
