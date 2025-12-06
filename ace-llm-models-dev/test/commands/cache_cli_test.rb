# frozen_string_literal: true

require "test_helper"
require "json"

class CacheCLITest < ModelsDevTestCase
  def setup
    @cli = Ace::LLM::ModelsDev::Commands::CacheCLI.new
  end

  def test_status_shows_cache_info
    with_temp_cache do |cache_dir|
      # Setup cache with sample data
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: false } do
        output = capture_io { @cli.status }.first
        assert_match(/Cache Status:/, output)
        assert_match(/Cached: Yes/, output)
      end
    end
  end

  def test_status_json_output
    with_temp_cache do |cache_dir|
      # Setup cache with sample data
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: true } do
        output = capture_io { @cli.status }.first
        result = JSON.parse(output)
        assert result["cached"]
        assert result.key?("fresh")
      end
    end
  end

  def test_clear_clears_cache
    with_temp_cache do |cache_dir|
      # Setup cache with sample data
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)
      assert cache_manager.exists?

      # Clear it via CLI
      @cli.stub :options, { json: false } do
        # Need to stub the cache manager in the clear method
        cli = Ace::LLM::ModelsDev::Commands::CacheCLI.new
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { cli.clear }.first
          assert_match(/Cache cleared/, output)
        end
      end
    end
  end

  def test_clear_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::LLM::ModelsDev::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      @cli.stub :options, { json: true } do
        Ace::LLM::ModelsDev::Molecules::CacheManager.stub :new, cache_manager do
          output = capture_io { @cli.clear }.first
          result = JSON.parse(output)
          assert_equal :success.to_s, result["status"]
        end
      end
    end
  end
end
