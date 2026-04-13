# frozen_string_literal: true

require "test_helper"
require "ace/support/models/cli"
require "json"

class CacheCommandsTest < AceModelsTestCase
  def test_status_shows_cache_info
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::Cache::Status.new
        output = capture_io { cmd.call(json: false) }.first
        assert_match(/Cache Status:/, output)
        assert_match(/Cached: Yes/, output)
      end
    end
  end

  def test_status_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::Cache::Status.new
        output = capture_io { cmd.call(json: true) }.first
        result = JSON.parse(output)
        assert result["cached"]
        assert result.key?("fresh")
      end
    end
  end

  def test_clear_clears_cache
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)
      assert cache_manager.exists?

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::Cache::Clear.new
        output = capture_io { cmd.call(json: false) }.first
        assert_match(/Cache cleared/, output)
      end
    end
  end

  def test_clear_json_output
    with_temp_cache do |cache_dir|
      cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: cache_dir)
      cache_manager.write(sample_api_response)

      Ace::Support::Models::Molecules::CacheManager.stub :new, cache_manager do
        cmd = Ace::Support::Models::CLI::Commands::Cache::Clear.new
        output = capture_io { cmd.call(json: true) }.first
        result = JSON.parse(output)
        assert_equal :success.to_s, result["status"]
      end
    end
  end
end
