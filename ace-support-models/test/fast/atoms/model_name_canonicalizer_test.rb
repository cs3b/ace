# frozen_string_literal: true

require_relative "../../test_helper"

class ModelNameCanonicalizerTest < AceModelsTestCase
  def setup
    @canonicalizer = Ace::Support::Models::Atoms::ModelNameCanonicalizer
  end

  # canonicalize tests

  def test_canonicalize_strips_nitro_suffix_for_openrouter
    result = @canonicalizer.canonicalize("openai/gpt-4:nitro", provider: "openrouter")

    assert_equal "openai/gpt-4", result
  end

  def test_canonicalize_strips_floor_suffix_for_openrouter
    result = @canonicalizer.canonicalize("anthropic/claude-3:floor", provider: "openrouter")

    assert_equal "anthropic/claude-3", result
  end

  def test_canonicalize_strips_online_suffix_for_openrouter
    result = @canonicalizer.canonicalize("openai/o3-mini-high:online", provider: "openrouter")

    assert_equal "openai/o3-mini-high", result
  end

  def test_canonicalize_strips_free_suffix_for_openrouter
    result = @canonicalizer.canonicalize("meta/llama-3:free", provider: "openrouter")

    assert_equal "meta/llama-3", result
  end

  def test_canonicalize_strips_extended_suffix_for_openrouter
    result = @canonicalizer.canonicalize("anthropic/claude-3:extended", provider: "openrouter")

    assert_equal "anthropic/claude-3", result
  end

  def test_canonicalize_strips_exacto_suffix_for_openrouter
    result = @canonicalizer.canonicalize("openai/gpt-4o:exacto", provider: "openrouter")

    assert_equal "openai/gpt-4o", result
  end

  def test_canonicalize_strips_thinking_suffix_for_openrouter
    result = @canonicalizer.canonicalize("deepseek/deepseek-r1:thinking", provider: "openrouter")

    assert_equal "deepseek/deepseek-r1", result
  end

  def test_canonicalize_preserves_model_without_suffix
    result = @canonicalizer.canonicalize("openai/gpt-4", provider: "openrouter")

    assert_equal "openai/gpt-4", result
  end

  def test_canonicalize_preserves_suffix_for_non_openrouter_provider
    result = @canonicalizer.canonicalize("model:nitro", provider: "anthropic")

    assert_equal "model:nitro", result
  end

  def test_canonicalize_preserves_suffix_when_no_provider_specified
    result = @canonicalizer.canonicalize("model:nitro", provider: nil)

    assert_equal "model:nitro", result
  end

  def test_canonicalize_preserves_unknown_suffix_for_openrouter
    result = @canonicalizer.canonicalize("model:unknown", provider: "openrouter")

    assert_equal "model:unknown", result
  end

  def test_canonicalize_handles_complex_model_ids
    result = @canonicalizer.canonicalize("moonshotai/kimi-k2-0905:nitro", provider: "openrouter")

    assert_equal "moonshotai/kimi-k2-0905", result
  end

  def test_canonicalize_handles_model_with_numbers_in_suffix_position
    result = @canonicalizer.canonicalize("qwen/qwen3-235b-a22b-2507:nitro", provider: "openrouter")

    assert_equal "qwen/qwen3-235b-a22b-2507", result
  end

  def test_canonicalize_returns_nil_input_unchanged
    result = @canonicalizer.canonicalize(nil, provider: "openrouter")

    assert_nil result
  end

  def test_canonicalize_returns_empty_string_unchanged
    result = @canonicalizer.canonicalize("", provider: "openrouter")

    assert_equal "", result
  end

  # has_suffix? tests

  def test_has_suffix_returns_true_for_known_suffix
    result = @canonicalizer.has_suffix?("model:nitro", provider: "openrouter")

    assert result
  end

  def test_has_suffix_returns_false_for_unknown_suffix
    result = @canonicalizer.has_suffix?("model:unknown", provider: "openrouter")

    refute result
  end

  def test_has_suffix_returns_false_for_model_without_suffix
    result = @canonicalizer.has_suffix?("openai/gpt-4", provider: "openrouter")

    refute result
  end

  def test_has_suffix_returns_false_for_non_openrouter_provider
    result = @canonicalizer.has_suffix?("model:nitro", provider: "anthropic")

    refute result
  end

  def test_has_suffix_returns_false_for_nil_provider
    result = @canonicalizer.has_suffix?("model:nitro", provider: nil)

    refute result
  end

  def test_has_suffix_returns_false_for_nil_model
    result = @canonicalizer.has_suffix?(nil, provider: "openrouter")

    refute result
  end

  def test_has_suffix_returns_false_for_empty_model
    result = @canonicalizer.has_suffix?("", provider: "openrouter")

    refute result
  end

  # extract_suffix tests

  def test_extract_suffix_returns_suffix_without_colon
    result = @canonicalizer.extract_suffix("model:nitro")

    assert_equal "nitro", result
  end

  def test_extract_suffix_returns_last_suffix_for_multiple_colons
    # Model IDs like "org/model:suffix" should extract just "suffix"
    result = @canonicalizer.extract_suffix("openai/gpt-4:nitro")

    assert_equal "nitro", result
  end

  def test_extract_suffix_returns_nil_for_model_without_suffix
    result = @canonicalizer.extract_suffix("openai/gpt-4")

    assert_nil result
  end

  def test_extract_suffix_returns_nil_for_nil_input
    result = @canonicalizer.extract_suffix(nil)

    assert_nil result
  end

  def test_extract_suffix_returns_nil_for_empty_input
    result = @canonicalizer.extract_suffix("")

    assert_nil result
  end

  def test_extract_suffix_handles_colon_in_org_name
    # Edge case: org name with colon (unusual but should be handled)
    result = @canonicalizer.extract_suffix("some:org/model:nitro")

    assert_equal "nitro", result
  end

  # suffixes_for tests

  def test_suffixes_for_openrouter_returns_all_suffixes
    result = @canonicalizer.suffixes_for("openrouter")

    assert_includes result, "nitro"
    assert_includes result, "floor"
    assert_includes result, "online"
    assert_includes result, "free"
    assert_includes result, "extended"
    assert_includes result, "exacto"
    assert_includes result, "thinking"
  end

  def test_suffixes_for_unknown_provider_returns_empty_array
    result = @canonicalizer.suffixes_for("unknown")

    assert_equal [], result
  end

  def test_suffixes_for_nil_provider_returns_empty_array
    result = @canonicalizer.suffixes_for(nil)

    assert_equal [], result
  end

  # Real-world OpenRouter model examples from the issue

  def test_canonicalize_real_openrouter_models
    models = {
      "moonshotai/kimi-k2-0905:nitro" => "moonshotai/kimi-k2-0905",
      "openai/gpt-oss-120b:nitro" => "openai/gpt-oss-120b",
      "openai/gpt-oss-20b:nitro" => "openai/gpt-oss-20b",
      "qwen/qwen3-235b-a22b-2507:nitro" => "qwen/qwen3-235b-a22b-2507"
    }

    models.each do |original, expected|
      result = @canonicalizer.canonicalize(original, provider: "openrouter")
      assert_equal expected, result, "Failed to canonicalize #{original}"
    end
  end
end
