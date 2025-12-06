# frozen_string_literal: true

require "test_helper"
require "json"

class ProvidersCLITest < ModelsDevTestCase
  def setup
    @cli = Ace::LLM::ModelsDev::Commands::ProvidersCLI.new
  end

  def test_list_shows_providers
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: false } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.list }.first
          assert_match(/Providers/, output)
          assert_match(/test-provider/, output)
          assert_match(/another-provider/, output)
        end
      end
    end
  end

  def test_list_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: true } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.list }.first
          result = JSON.parse(output)
          assert result.is_a?(Array)
          assert result.any? { |p| p["id"] == "test-provider" }
        end
      end
    end
  end

  def test_show_provider_details
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: false } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.show("test-provider") }.first
          assert_match(/Provider: test-provider/, output)
          assert_match(/test-model/, output)
        end
      end
    end
  end

  def test_show_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: true } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.show("test-provider") }.first
          result = JSON.parse(output)
          assert_equal "test-provider", result["id"]
          assert result["models"].is_a?(Array)
        end
      end
    end
  end
end
