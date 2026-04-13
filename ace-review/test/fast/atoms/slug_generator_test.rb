# frozen_string_literal: true

require "test_helper"

class SlugGeneratorTest < AceReviewTest
  def setup
    super
    @generator = Ace::Review::Atoms::SlugGenerator
  end

  # Basic functionality tests
  def test_basic_slug_generation
    result = @generator.generate("hello-world")

    assert_equal "hello-world", result
  end

  def test_converts_to_lowercase
    result = @generator.generate("Hello-WORLD")

    assert_equal "hello-world", result
  end

  def test_preserves_underscores
    result = @generator.generate("hello_world")

    assert_equal "hello_world", result
  end

  # Provider:model format tests
  def test_model_with_provider_prefix
    result = @generator.generate("google:gemini-2.5-flash")

    assert_equal "google-gemini-2-5-flash", result
  end

  def test_model_with_dots_in_version
    result = @generator.generate("openai:gpt-4.5-turbo")

    assert_equal "openai-gpt-4-5-turbo", result
  end

  def test_simple_model_name
    result = @generator.generate("gpt-4")

    assert_equal "gpt-4", result
  end

  # Edge case: consecutive hyphens
  def test_collapses_consecutive_hyphens
    result = @generator.generate("model::name")

    assert_equal "model-name", result
  end

  def test_collapses_multiple_special_chars
    result = @generator.generate("model...name:::provider")

    assert_equal "model-name-provider", result
  end

  # Edge case: leading/trailing special characters
  def test_removes_leading_hyphen
    result = @generator.generate("@model-name")

    assert_equal "model-name", result
  end

  def test_removes_trailing_hyphen
    result = @generator.generate("model-name@")

    assert_equal "model-name", result
  end

  def test_removes_both_leading_and_trailing_hyphens
    result = @generator.generate("@model-name@")

    assert_equal "model-name", result
  end

  def test_handles_multiple_leading_special_chars
    result = @generator.generate("@@!!model-name")

    assert_equal "model-name", result
  end

  # Edge case: length truncation
  def test_truncates_long_slugs
    long_name = "a" * 100
    result = @generator.generate(long_name)

    assert_equal 64, result.length
    assert_equal "a" * 64, result
  end

  def test_custom_max_length
    result = @generator.generate("abcdefghij", max_length: 5)

    assert_equal "abcde", result
  end

  def test_preserves_short_slugs
    result = @generator.generate("short", max_length: 100)

    assert_equal "short", result
  end

  def test_removes_trailing_hyphen_after_truncation
    # "model-name-provider" truncated at 11 chars would be "model-name-"
    result = @generator.generate("model-name-provider", max_length: 11)

    # Should be "model-name" not "model-name-"
    assert_equal "model-name", result
    refute result.end_with?("-")
  end

  # Edge case: empty/nil input
  def test_handles_nil_input
    result = @generator.generate(nil)

    assert_equal "", result
  end

  def test_handles_empty_string
    result = @generator.generate("")

    assert_equal "", result
  end

  # Edge case: all special characters
  def test_handles_all_special_chars
    result = @generator.generate("@#$%^&*()")

    assert_equal "", result
  end

  # Real-world model name examples
  def test_anthropic_model
    result = @generator.generate("anthropic:claude-3-opus")

    assert_equal "anthropic-claude-3-opus", result
  end

  def test_codex_model
    result = @generator.generate("codex:gpt-5.1-codex-max")

    assert_equal "codex-gpt-5-1-codex-max", result
  end

  def test_gpro_alias
    result = @generator.generate("gpro")

    assert_equal "gpro", result
  end
end
