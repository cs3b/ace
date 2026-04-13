# frozen_string_literal: true

require "test_helper"
require "ace/support/models/cli"
require "json"

class ModelsCommandsTest < AceModelsTestCase
  def test_search_finds_models
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Search.new
        output = capture_io { cmd.call(query: "test", json: false, limit: 20) }.first
        assert_match(/test-provider:test-model/, output)
      end
    end
  end

  def test_search_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Search.new
        output = capture_io { cmd.call(query: "test", json: true, limit: 20) }.first
        result = JSON.parse(output)
        assert result.key?("models")
        assert result.key?("showing")
        assert result.key?("total")
      end
    end
  end

  def test_search_json_contract_shape
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Search.new
        output = capture_io { cmd.call(query: "test", json: true, limit: 20) }.first
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

  def test_search_truncation_message
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Search.new
        output = capture_io { cmd.call(query: nil, json: false, limit: 1) }.first
        assert_match(/Showing 1 of \d+ results/, output)
      end
    end
  end

  def test_info_brief_by_default
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Info.new
        output = capture_io { cmd.call(model_id: "test-provider:test-model", json: false, full: false) }.first
        assert_match(/Test Model/, output)
        assert_match(/Use --full for complete details/, output)
        # Brief output should not have the full Capabilities section
        refute_match(/Capabilities:\n  Reasoning:/, output)
      end
    end
  end

  def test_info_full_option
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Info.new
        output = capture_io { cmd.call(model_id: "test-provider:test-model", json: false, full: true) }.first
        assert_match(/Model: Test Model/, output)
        assert_match(/Capabilities:/, output)
        assert_match(/Tool Call:/, output)
        refute_match(/Use --full for complete details/, output)
      end
    end
  end

  def test_info_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Info.new
        output = capture_io { cmd.call(model_id: "test-provider:test-model", json: true) }.first
        result = JSON.parse(output)
        assert_equal "test-model", result["id"]
        assert_equal "test-provider", result["provider_id"]
      end
    end
  end

  def test_cost_shows_pricing
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Cost.new
        output = capture_io { cmd.call(model_id: "test-provider:test-model", json: false, input: 1000, output: 500, reasoning: 0) }.first
        assert_match(/test-provider:test-model/, output)
      end
    end
  end
end
