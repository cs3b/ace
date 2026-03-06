# frozen_string_literal: true

require "test_helper"

class ProviderCatalogTest < AceReviewTest
  def setup
    super
    create_llm_catalog(<<~YAML)
      review-fast:
        - "codex:spark@review-fast"
      review-deep:
        - "codex:codex@review-deep"
    YAML
    create_tools_lint_catalog(<<~YAML)
      lint:
        - lint
    YAML
    @catalog = Ace::Review::Molecules::ProviderCatalog.new(project_root: @test_dir)
  end

  def test_resolves_llm_catalog_entry_by_name
    entries = @catalog.resolve(provider_class: "llm", names: ["review-fast"])
    assert_equal 1, entries.size
    assert_equal "review-fast", entries.first["name"]
    assert_equal "codex:spark@review-fast", entries.first["model"]
  end

  def test_resolves_multiple_llm_entries
    entries = @catalog.resolve(provider_class: "llm", names: ["review-fast", "review-deep"])
    assert_equal 2, entries.size
    assert_equal "review-fast", entries.first["name"]
    assert_equal "review-deep", entries.last["name"]
  end

  def test_resolves_llm_group_with_multiple_models
    create_llm_catalog(<<~YAML)
      review-fast:
        - "codex:spark@review-fast"
        - "claude:haiku@review-fast"
    YAML
    catalog = Ace::Review::Molecules::ProviderCatalog.new(project_root: @test_dir)
    entries = catalog.resolve(provider_class: "llm", names: ["review-fast"])
    assert_equal 2, entries.size
    assert_equal "review-fast", entries[0]["name"]
    assert_equal "codex:spark@review-fast", entries[0]["model"]
    assert_equal "review-fast", entries[1]["name"]
    assert_equal "claude:haiku@review-fast", entries[1]["model"]
  end

  def test_duplicate_models_produce_duplicate_entries
    create_llm_catalog(<<~YAML)
      review-fast:
        - "codex:spark@review-fast"
        - "codex:spark@review-fast"
    YAML
    catalog = Ace::Review::Molecules::ProviderCatalog.new(project_root: @test_dir)
    entries = catalog.resolve(provider_class: "llm", names: ["review-fast"])
    assert_equal 2, entries.size
    assert_equal entries[0]["model"], entries[1]["model"]
  end

  def test_tools_lint_group_with_multiple_tools
    create_tools_lint_catalog(<<~YAML)
      lint:
        - lint
        - rubocop
    YAML
    catalog = Ace::Review::Molecules::ProviderCatalog.new(project_root: @test_dir)
    entries = catalog.resolve(provider_class: "tools-lint", names: ["lint"])
    assert_equal 2, entries.size
    assert_equal "lint", entries[0]["tool"]
    assert_equal "rubocop", entries[1]["tool"]
    assert entries.all? { |e| e["name"] == "lint" }
  end

  def test_treats_unknown_llm_name_as_inline_model_id
    entries = @catalog.resolve(provider_class: "llm", names: ["codex:codex@review-deep"])
    assert_equal 1, entries.size
    assert_equal "codex:codex@review-deep", entries.first["name"]
    assert_equal "codex:codex@review-deep", entries.first["model"]
  end

  def test_resolves_tools_lint_catalog_entry
    entries = @catalog.resolve(provider_class: "tools-lint", names: ["lint"])
    assert_equal 1, entries.size
    assert_equal "lint", entries.first["name"]
    assert_equal "lint", entries.first["tool"]
  end

  def test_raises_for_unknown_tools_lint_name
    error = assert_raises(ArgumentError) do
      @catalog.resolve(provider_class: "tools-lint", names: ["unknown-tool"])
    end
    assert_includes error.message, "unknown-tool"
  end

  def test_entry_names_returns_catalog_keys
    names = @catalog.entry_names(provider_class: "llm")
    assert_includes names, "review-fast"
    assert_includes names, "review-deep"
  end

  def test_returns_empty_when_catalog_file_missing
    FileUtils.rm_f(File.join(@test_dir, ".ace/review/providers/llm.yml"))
    catalog = Ace::Review::Molecules::ProviderCatalog.new(project_root: @test_dir)
    entries = catalog.resolve(provider_class: "llm", names: ["codex:spark@review-fast"])
    # Inline model ID still resolves
    assert_equal 1, entries.size
    assert_equal "codex:spark@review-fast", entries.first["model"]
  end

  def test_catalog_caches_loaded_data
    # Call twice and ensure no error on second call (tests memoization)
    @catalog.resolve(provider_class: "llm", names: ["review-fast"])
    entries = @catalog.resolve(provider_class: "llm", names: ["review-fast"])
    assert_equal 1, entries.size
  end

  private

  def create_llm_catalog(content)
    FileUtils.mkdir_p(File.join(@test_dir, ".ace/review/providers"))
    File.write(File.join(@test_dir, ".ace/review/providers/llm.yml"), content)
  end

  def create_tools_lint_catalog(content)
    FileUtils.mkdir_p(File.join(@test_dir, ".ace/review/providers"))
    File.write(File.join(@test_dir, ".ace/review/providers/tools-lint.yml"), content)
  end
end
