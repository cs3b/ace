# frozen_string_literal: true

require_relative "../../test_helper"

class ModelInfoTest < AceModelsTestCase
  def setup
    @model_hash = sample_provider_data["models"]["test-model"]
  end

  def test_from_hash
    model = Ace::Support::Models::Models::ModelInfo.from_hash(@model_hash, provider_id: "test-provider")

    assert_equal "test-model", model.id
    assert_equal "Test Model", model.name
    assert_equal "test-provider", model.provider_id
  end

  def test_full_id
    model = Ace::Support::Models::Models::ModelInfo.from_hash(@model_hash, provider_id: "test-provider")
    assert_equal "test-provider:test-model", model.full_id
  end

  def test_pricing
    model = Ace::Support::Models::Models::ModelInfo.from_hash(@model_hash, provider_id: "test-provider")

    assert_equal 2.5, model.pricing.input
    assert_equal 10.0, model.pricing.output
  end

  def test_limits
    model = Ace::Support::Models::Models::ModelInfo.from_hash(@model_hash, provider_id: "test-provider")

    assert_equal 128_000, model.context_limit
    assert_equal 4096, model.output_limit
  end

  def test_capabilities
    model = Ace::Support::Models::Models::ModelInfo.from_hash(@model_hash, provider_id: "test-provider")

    assert model.supports?(:tool_call)
    assert model.supports?(:temperature)
    refute model.supports?(:reasoning)
  end

  def test_deprecated
    model = Ace::Support::Models::Models::ModelInfo.new(status: "deprecated")
    assert model.deprecated?

    model2 = Ace::Support::Models::Models::ModelInfo.new(status: nil)
    refute model2.deprecated?
  end

  def test_preview
    %w[alpha beta preview].each do |status|
      model = Ace::Support::Models::Models::ModelInfo.new(status: status)
      assert model.preview?, "Expected #{status} to be preview"
    end

    model = Ace::Support::Models::Models::ModelInfo.new(status: nil)
    refute model.preview?
  end

  def test_to_h
    model = Ace::Support::Models::Models::ModelInfo.from_hash(@model_hash, provider_id: "test-provider")
    hash = model.to_h

    assert_equal "test-model", hash[:id]
    assert_equal "test-provider:test-model", hash[:full_id]
    assert_kind_of Hash, hash[:pricing]
    assert_kind_of Hash, hash[:capabilities]
  end
end
