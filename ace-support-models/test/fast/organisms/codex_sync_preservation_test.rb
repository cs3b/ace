# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "stringio"

class CodexSyncPreservationTest < AceModelsTestCase
  MODELS = %w[gpt-5.6-terra gpt-6-astra gpt-5.6-sol gpt-5.6-luna gpt-5.4 gpt-5.3-codex].freeze

  def test_known_removals_survive_all_and_since_filters
    with_catalog(MODELS) do
      apply
      removed = MODELS - ["gpt-5.4"]
      edit { |config| config["models"] -= removed }
      result = apply(show_all: true, since: "2099-01-01")
      assert_equal ["gpt-5.4"], read["models"]
      assert_equal removed.sort, result[:diff]["codex"][:preserved_removals].sort
      refute result[:diff]["codex"][:added].any?
    end
  end

  def test_direct_diff_never_treats_native_upstream_absence_as_retirement
    diff = Ace::Support::Models::Molecules::ProviderSyncDiff.new.diff_provider(
      {"name" => "codex", "models" => ["gpt-6-astra", "native-local"]}, {"models" => {}}
    )
    assert_empty diff[:removed]
    assert_empty diff[:added]
    assert_equal ["gpt-6-astra", "native-local"], diff[:unchanged]
  end

  def test_unknown_source_catalog_ids_remain_unknown_on_first_apply
    with_catalog(["gpt-5.4"], offered: MODELS + ["gpt-unknown-new"]) do
      result = apply
      assert_equal ["gpt-5.4"], read["models"]
      assert_includes result[:diff]["codex"][:offered], "gpt-unknown-new"
      assert_equal 0, result[:summary][:providers_synced]
      assert_equal 1, result[:summary][:providers_unresolved]
    end
  end

  def test_malformed_history_is_not_adoption_evidence
    with_catalog(["gpt-5.4"]) do
      edit { |config| config["sync_state"] = {"catalog" => []} }
      apply
      assert_equal ["gpt-5.4"], read["models"]
    end
  end

  def test_apply_refuses_a_bundled_destination
    with_catalog(["gpt-5.4"]) do
      original = File.binread(@path)
      Ace::Support::Models::Atoms::ProviderConfigReader.stub(:bundled_config_directories, [@dir]) do
        result = @sync.sync(config_dir: @dir, provider: "codex", apply: true)
        refute result[:applied]
        assert_match(/Cannot write bundled/, result[:apply_errors].first)
      end
      assert_equal original, File.binread(@path)
    end
  end

  def test_explicit_configuration_adopts_unknown_then_preserves_subsequent_removal
    with_catalog(["gpt-5.4"]) do
      apply
      assert_includes read.dig("sync_state", "unknown"), "gpt-6-astra"
      edit { |config| config["models"] << "gpt-6-astra" }
      apply
      assert_includes read.dig("sync_state", "accepted"), "gpt-6-astra"
      refute_includes read.dig("sync_state", "unknown"), "gpt-6-astra"
      edit { |config| config["models"].delete("gpt-6-astra") }
      apply
      refute_includes read["models"], "gpt-6-astra"
      assert_includes read.dig("sync_state", "removed"), "gpt-6-astra"
    end
  end

  def test_genuine_new_catalog_addition_requires_observed_baseline
    with_catalog(["gpt-5.4"], offered: ["gpt-5.4"]) do
      apply
      @catalog["models"] += ["gpt-6-astra", "gpt-unknown-new"]
      result = apply
      assert_equal ["gpt-6-astra", "gpt-unknown-new"], result[:diff]["codex"][:added]
      assert_equal ["gpt-5.4", "gpt-6-astra", "gpt-unknown-new"], read["models"]
      edit { |config| config["models"].delete("gpt-unknown-new") }
      apply
      refute_includes read["models"], "gpt-unknown-new"
    end
  end

  def test_repeat_sync_preserves_bytes_and_reports_unknown_offers_truthfully
    with_catalog(["gpt-5.4"]) do
      first = apply
      assert first[:applied]
      original = File.binread(@path)
      backups = Dir.glob("#{@path}.backup.*")
      result = apply
      refute result[:changes_detected]
      refute result[:applied]
      assert_equal original, File.binread(@path)
      assert_equal backups, Dir.glob("#{@path}.backup.*")
      assert_match(/Unresolved catalog offers/, @sync.format_result(result))
      refute_match(/All providers are up to date/, @sync.format_result(result))
    end
  end

  def test_preview_does_not_authorize_later_additions_or_write_anything
    with_catalog(["gpt-5.4"], offered: ["gpt-5.4"]) do
      original = File.binread(@path)
      @sync.sync(config_dir: @dir, provider: "codex")
      assert_equal original, File.binread(@path)
      assert_empty Dir.glob("#{@path}.backup.*")
      @catalog["models"] << "gpt-6-astra"
      apply
      assert_equal ["gpt-5.4"], read["models"]
    end
  end

  def test_native_models_limits_aliases_default_and_unrelated_provider_survive
    with_catalog(["gpt-5.6-terra", "native-local", "gpt-6-astra"]) do
      edit do |config|
        config["aliases"] = {"model" => {"gpt" => "gpt-5.4", "local" => "native-local"}}
        config["limits"] = {"models" => {"gpt-6-astra" => {"context" => 12345}}}
        config["operator_note"] = "keep"
      end
      before = read
      other = File.join(@dir, "anthropic.yml")
      File.write(other, "name: anthropic\nmodels: [local]\n")
      original_other = File.binread(other)
      apply
      %w[models aliases limits operator_note].each { |key| assert_equal before[key], read[key] }
      assert_equal "gpt-5.6-terra", read["models"].first
      assert_equal original_other, File.binread(other)
    end
  end

  def test_unknown_and_removed_ids_are_not_readopted_after_catalog_disappears_and_returns
    with_catalog(["gpt-5.4"]) do
      apply
      @catalog["models"] = ["gpt-5.4"]
      apply
      @catalog["models"] = MODELS.dup
      apply
      assert_equal ["gpt-5.4"], read["models"]
    end
  end

  def test_no_history_apply_preserves_missing_old_new_and_unknown_models
    Dir.mktmpdir("codex-sync") do |dir|
      path = File.join(dir, "codex.yml")
      config = {
        "name" => "codex", "models_dev_id" => "openai",
        "models" => ["gpt-5.4", "native-local"],
        "aliases" => {"model" => {"gpt" => "gpt-5.4"}},
        "limits" => {"default" => {"context" => 12345}}
      }
      File.write(path, YAML.dump(config))
      cache = Object.new
      cache.define_singleton_method(:exists?) { true }
      cache.define_singleton_method(:fresh?) { |**| true }
      cache.define_singleton_method(:read) do
        {"openai" => {"models" => (MODELS + ["gpt-unknown-new"]).to_h { |id| [id, {}] }}}
      end
      sync = Ace::Support::Models::Organisms::ProviderSyncOrchestrator.new(
        cache_manager: cache, output: StringIO.new
      )
      original = File.binread(path)
      sync.sync(config_dir: dir, provider: "codex", show_all: true)
      assert_equal original, File.binread(path), "preview must not record provenance"
      sync.sync(config_dir: dir, provider: "codex", apply: true, show_all: true)
      actual = YAML.safe_load_file(path, permitted_classes: [Date])
      assert_equal config["models"], actual["models"], "blanket apply must preserve UNKNOWN absences and native models"
      assert_equal config["aliases"], actual["aliases"]
      assert_equal config["limits"], actual["limits"]
    end
  end

  private

  def with_catalog(models, offered: MODELS)
    Dir.mktmpdir("codex-sync-history") do |dir|
      @dir = dir
      @path = File.join(dir, "codex.yml")
      @catalog = {"name" => "codex", "models" => offered.dup}
      File.write(@path, YAML.dump({"name" => "codex", "models" => models.dup}))
      # Empty cache deliberately proves native catalog sync has no API dependency.
      cache = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: File.join(dir, "cache"))
      @sync = Ace::Support::Models::Organisms::ProviderSyncOrchestrator.new(
        cache_manager: cache, output: StringIO.new
      )
      Ace::Support::Models::Atoms::ProviderConfigReader.stub(:bundled_config, ->(_) { @catalog }) { yield }
    end
  end

  def apply(**options)
    result = @sync.sync(config_dir: @dir, provider: "codex", apply: true, **options)
    assert_nil result[:apply_errors]
    result
  end

  def read
    YAML.safe_load_file(@path, permitted_classes: [Date])
  end

  def edit
    config = read
    yield config
    File.write(@path, YAML.dump(config))
  end
end
