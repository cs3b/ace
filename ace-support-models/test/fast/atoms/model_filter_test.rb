# frozen_string_literal: true

require_relative "../../test_helper"

class ModelFilterTest < AceModelsTestCase
  def setup
    @filter = Ace::Support::Models::Atoms::ModelFilter
    @models = create_test_models
  end

  # Test provider filter
  def test_filter_by_provider
    result = @filter.apply(@models, {provider: "openai"})

    assert_equal 2, result.size
    assert result.all? { |m| m.provider_id == "openai" }
  end

  # Test capability filters
  def test_filter_by_reasoning_true
    result = @filter.apply(@models, {reasoning: "true"})

    assert_equal 2, result.size
    assert result.all? { |m| m.capabilities[:reasoning] == true }
  end

  def test_filter_by_reasoning_false
    result = @filter.apply(@models, {reasoning: "false"})

    assert_equal 3, result.size # gpt-4o, llama-3, gemini-2
    assert result.all? { |m| m.capabilities[:reasoning] == false }
  end

  def test_filter_by_tool_call
    result = @filter.apply(@models, {tool_call: "true"})

    assert_equal 3, result.size
    assert result.all? { |m| m.capabilities[:tool_call] == true }
  end

  def test_filter_by_attachment
    result = @filter.apply(@models, {attachment: "true"})

    assert_equal 1, result.size
    assert_equal "claude-4", result.first.id
  end

  # Test open_weights filter
  def test_filter_by_open_weights
    result = @filter.apply(@models, {open_weights: "true"})

    assert_equal 1, result.size
    assert_equal "llama-3", result.first.id
  end

  # Test modality filter
  def test_filter_by_modality_image
    result = @filter.apply(@models, {modality: "image"})

    assert_equal 3, result.size # gpt-4o, claude-4, gemini-2
    assert result.all? { |m| m.modalities[:input].include?("image") }
  end

  def test_filter_by_modality_audio
    result = @filter.apply(@models, {modality: "audio"})

    assert_equal 1, result.size
    assert_equal "gemini-2", result.first.id
  end

  # Test numeric filters
  def test_filter_by_min_context
    result = @filter.apply(@models, {min_context: "100000"})

    assert_equal 3, result.size # gpt-4o (128k), o1 (200k), claude-4 (200k)
    assert result.all? { |m| m.context_limit >= 100_000 }
  end

  def test_filter_by_max_input_cost
    result = @filter.apply(@models, {max_input_cost: "2"})

    assert_equal 2, result.size
    assert result.all? { |m| m.pricing.input <= 2 }
  end

  # Test filter combination (AND logic)
  def test_multiple_filters_and_logic
    result = @filter.apply(@models, {provider: "openai", reasoning: "true"})

    assert_equal 1, result.size
    assert_equal "o1", result.first.id
  end

  def test_multiple_capability_filters
    result = @filter.apply(@models, {tool_call: "true", reasoning: "true"})

    assert_equal 1, result.size
    assert_equal "claude-4", result.first.id
  end

  # Test unknown filter keys (should be ignored)
  def test_unknown_filter_key_ignored
    result = @filter.apply(@models, {unknown_filter: "value"})

    assert_equal 5, result.size # All models returned
  end

  def test_unknown_filter_combined_with_known
    result = @filter.apply(@models, {provider: "openai", unknown_filter: "value"})

    assert_equal 2, result.size # Only provider filter applied
  end

  # Test empty/nil filters
  def test_empty_filters_returns_all
    result = @filter.apply(@models, {})

    assert_equal 5, result.size
  end

  def test_nil_filters_returns_all
    result = @filter.apply(@models, nil)

    assert_equal 5, result.size
  end

  # Test parse method
  def test_parse_valid_filter
    result = @filter.parse("provider:openai")

    assert_equal [:provider, "openai"], result
  end

  def test_parse_filter_with_colon_in_value
    result = @filter.parse("key:value:with:colons")

    assert_equal [:key, "value:with:colons"], result
  end

  def test_parse_invalid_filter_no_colon
    result = @filter.parse("invalid")

    assert_nil result
  end

  def test_parse_invalid_filter_empty_key
    result = @filter.parse(":value")

    assert_nil result
  end

  def test_parse_invalid_filter_empty_value
    result = @filter.parse("key:")

    assert_nil result
  end

  def test_parse_nil_returns_nil
    result = @filter.parse(nil)

    assert_nil result
  end

  # Test parse_all method
  def test_parse_all_multiple_filters
    result = @filter.parse_all(["provider:openai", "reasoning:true"])

    assert_equal({provider: "openai", reasoning: "true"}, result)
  end

  def test_parse_all_skips_invalid_filters
    result = @filter.parse_all(["provider:openai", "invalid", "reasoning:true"])

    assert_equal({provider: "openai", reasoning: "true"}, result)
  end

  def test_parse_all_empty_array
    result = @filter.parse_all([])

    assert_equal({}, result)
  end

  def test_parse_all_nil
    result = @filter.parse_all(nil)

    assert_equal({}, result)
  end

  # Test validate method
  def test_validate_all_valid_filters
    result = @filter.validate(["provider:openai", "reasoning:true"])

    assert_empty result
  end

  def test_validate_returns_errors_for_invalid_filters
    result = @filter.validate(["provider:openai", "badfilter", "another_bad"])

    assert_equal 2, result.size
    assert_includes result[0], "badfilter"
    assert_includes result[1], "another_bad"
  end

  def test_validate_empty_array
    result = @filter.validate([])

    assert_empty result
  end

  def test_validate_nil
    result = @filter.validate(nil)

    assert_empty result
  end

  def test_validate_error_message_format
    result = @filter.validate(["invalid"])

    assert_equal ["Invalid filter format 'invalid'. Use key:value"], result
  end

  private

  def create_test_models
    [
      # OpenAI GPT-4o - text+image input, no reasoning, tool_call
      Ace::Support::Models::Models::ModelInfo.new(
        id: "gpt-4o",
        name: "GPT-4o",
        provider_id: "openai",
        pricing: Ace::Support::Models::Models::PricingInfo.new(input: 2.5, output: 10.0),
        context_limit: 128_000,
        modalities: {input: %w[text image], output: ["text"]},
        capabilities: {reasoning: false, tool_call: true, attachment: false},
        open_weights: false
      ),
      # OpenAI o1 - text only, reasoning, no tool_call
      Ace::Support::Models::Models::ModelInfo.new(
        id: "o1",
        name: "o1",
        provider_id: "openai",
        pricing: Ace::Support::Models::Models::PricingInfo.new(input: 15.0, output: 60.0),
        context_limit: 200_000,
        modalities: {input: ["text"], output: ["text"]},
        capabilities: {reasoning: true, tool_call: false, attachment: false},
        open_weights: false
      ),
      # Anthropic Claude 4 - text+image, reasoning, tool_call, attachment
      Ace::Support::Models::Models::ModelInfo.new(
        id: "claude-4",
        name: "Claude 4",
        provider_id: "anthropic",
        pricing: Ace::Support::Models::Models::PricingInfo.new(input: 3.0, output: 15.0),
        context_limit: 200_000,
        modalities: {input: %w[text image], output: ["text"]},
        capabilities: {reasoning: true, tool_call: true, attachment: true},
        open_weights: false
      ),
      # Meta Llama 3 - text only, no reasoning, tool_call, open_weights
      Ace::Support::Models::Models::ModelInfo.new(
        id: "llama-3",
        name: "Llama 3",
        provider_id: "meta",
        pricing: Ace::Support::Models::Models::PricingInfo.new(input: 0.5, output: 0.5),
        context_limit: 8192,
        modalities: {input: ["text"], output: ["text"]},
        capabilities: {reasoning: false, tool_call: true, attachment: false},
        open_weights: true
      ),
      # Google Gemini 2 - multimodal including audio
      Ace::Support::Models::Models::ModelInfo.new(
        id: "gemini-2",
        name: "Gemini 2",
        provider_id: "google",
        pricing: Ace::Support::Models::Models::PricingInfo.new(input: 1.0, output: 2.0),
        context_limit: 32_000,
        modalities: {input: %w[text image audio], output: ["text"]},
        capabilities: {reasoning: false, tool_call: false, attachment: false},
        open_weights: false
      )
    ]
  end
end
