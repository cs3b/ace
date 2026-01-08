# frozen_string_literal: true

require "test_helper"
require "ace/llm/models_dev/cli"
require "json"

class ProvidersCLITest < ModelsDevTestCase
  def test_list_shows_providers
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::LLM::ModelsDev::Commands::Providers::List.new
        output = capture_io { cmd.call(json: false) }.first
        assert_match(/Providers/, output)
        assert_match(/test-provider/, output)
        assert_match(/another-provider/, output)
      end
    end
  end

  def test_list_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::LLM::ModelsDev::Commands::Providers::List.new
        output = capture_io { cmd.call(json: true) }.first
        result = JSON.parse(output)
        assert result.is_a?(Array)
        assert result.any? { |p| p["id"] == "test-provider" }
      end
    end
  end

  def test_show_provider_details
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::LLM::ModelsDev::Commands::Providers::Show.new
        output = capture_io { cmd.call(provider_id: "test-provider", json: false) }.first
        assert_match(/Provider: test-provider/, output)
        assert_match(/test-model/, output)
      end
    end
  end

  def test_show_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::LLM::ModelsDev::Commands::Providers::Show.new
        output = capture_io { cmd.call(provider_id: "test-provider", json: true) }.first
        result = JSON.parse(output)
        assert_equal "test-provider", result["id"]
        assert result["models"].is_a?(Array)
      end
    end
  end
end
