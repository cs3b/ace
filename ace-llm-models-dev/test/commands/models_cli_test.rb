# frozen_string_literal: true

require "test_helper"
require "json"

class ModelsCLITest < ModelsDevTestCase
  def setup
    @cli = Ace::LLM::ModelsDev::Commands::ModelsCLI.new
  end

  def test_search_finds_models
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: false, limit: 20 } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.search("test") }.first
          assert_match(/test-provider:test-model/, output)
        end
      end
    end
  end

  def test_search_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: true, limit: 20 } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.search("test") }.first
          result = JSON.parse(output)
          assert result.key?("models")
          assert result.key?("showing")
          assert result.key?("total")
        end
      end
    end
  end

  def test_search_json_contract_shape
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: true, limit: 20 } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.search("test") }.first
          result = JSON.parse(output)

          # Validate exact JSON contract shape per README
          assert_instance_of Hash, result, "JSON output must be an object (not array)"
          assert_instance_of Array, result["models"], "models must be an array"
          assert_instance_of Integer, result["showing"], "showing must be an integer"
          assert_instance_of Integer, result["total"], "total must be an integer"

          # Validate model object shape
          model = result["models"].first
          assert_instance_of Hash, model, "Each model must be an object"
          assert model.key?("id"), "Model must have 'id' field"
          assert model.key?("provider_id"), "Model must have 'provider_id' field"
          assert model.key?("full_id"), "Model must have 'full_id' field"

          # Validate pagination values
          assert_equal result["models"].size, result["showing"], "showing should match models array size"
          assert result["total"] >= result["showing"], "total should be >= showing"
        end
      end
    end
  end

  def test_search_truncation_message
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      # Limit to 1 result
      @cli.stub :options, { json: false, limit: 1 } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.search }.first
          assert_match(/Showing 1 of \d+ results/, output)
        end
      end
    end
  end

  def test_info_brief_by_default
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: false, full: false } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.info("test-provider:test-model") }.first
          assert_match(/Test Model/, output)
          assert_match(/Use --full for complete details/, output)
          # Brief output should not have the full Capabilities section
          refute_match(/Capabilities:\n  Reasoning:/, output)
        end
      end
    end
  end

  def test_info_full_option
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: false, full: true } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.info("test-provider:test-model") }.first
          assert_match(/Model: Test Model/, output)
          assert_match(/Capabilities:/, output)
          assert_match(/Tool Call:/, output)
          refute_match(/Use --full for complete details/, output)
        end
      end
    end
  end

  def test_info_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: true } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.info("test-provider:test-model") }.first
          result = JSON.parse(output)
          assert_equal "test-model", result["id"]
          assert_equal "test-provider", result["provider_id"]
        end
      end
    end
  end

  def test_cost_shows_pricing
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: false, input: 1000, output: 500, reasoning: 0 } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.cost("test-provider:test-model") }.first
          # Should contain pricing info
          assert_match(/test-provider:test-model/, output)
        end
      end
    end
  end
end
