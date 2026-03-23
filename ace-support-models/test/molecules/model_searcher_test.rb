# frozen_string_literal: true

require_relative "../test_helper"

class ModelSearcherTest < AceModelsTestCase
  def setup
    @temp_dir = Dir.mktmpdir("ace-models-test")
    @cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: @temp_dir)
    @searcher = Ace::Support::Models::Molecules::ModelSearcher.new(cache_manager: @cache_manager)

    # Setup test data
    setup_test_cache
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  # Test basic search
  def test_search_with_query
    results = @searcher.search("test")

    assert results.any?
    assert results.all? { |m| m.id.include?("test") || m.name&.downcase&.include?("test") }
  end

  def test_search_with_provider_filter
    results = @searcher.search("model", provider: "test-provider")

    assert results.any?
    assert results.all? { |m| m.provider_id == "test-provider" }
  end

  def test_search_with_limit
    results = @searcher.search(nil, limit: 1)

    assert_equal 1, results.size
  end

  # Test optional query (nil = match all)
  def test_search_without_query_returns_all
    results = @searcher.search(nil, limit: 100)

    assert_equal 2, results.size # All models from test data
  end

  def test_search_without_query_with_provider
    results = @searcher.search(nil, provider: "test-provider", limit: 100)

    assert_equal 1, results.size
    assert_equal "test-provider", results.first.provider_id
  end

  # Test filters parameter
  def test_search_with_filter_provider
    results = @searcher.search(nil, filters: {provider: "test-provider"})

    assert_equal 1, results.size
    assert_equal "test-provider", results.first.provider_id
  end

  def test_search_with_filter_tool_call
    results = @searcher.search(nil, filters: {tool_call: "true"})

    assert_equal 1, results.size
    assert results.first.capabilities[:tool_call]
  end

  def test_search_with_filter_min_context
    results = @searcher.search(nil, filters: {min_context: "100000"})

    assert results.all? { |m| m.context_limit >= 100_000 }
  end

  def test_search_with_multiple_filters
    results = @searcher.search(nil, filters: {provider: "test-provider", tool_call: "true"})

    assert_equal 1, results.size
    assert_equal "test-provider", results.first.provider_id
    assert results.first.capabilities[:tool_call]
  end

  def test_search_with_query_and_filters
    results = @searcher.search("test", filters: {tool_call: "true"})

    assert results.any?
    assert results.all? { |m| m.capabilities[:tool_call] }
  end

  def test_search_filters_applied_before_limit
    # Set up a search that would return 2 models, filter to 1, limit to 10
    results = @searcher.search(nil, filters: {provider: "test-provider"}, limit: 10)

    assert_equal 1, results.size
  end

  # Test with_total parameter for pagination metadata
  def test_search_with_total_returns_hash
    result = @searcher.search(nil, limit: 1, with_total: true)

    assert_kind_of Hash, result
    assert result.key?(:models)
    assert result.key?(:total)
    assert_equal 1, result[:models].size
    assert_equal 2, result[:total] # Both models exist
  end

  # Test memory-efficient path (no filters)
  def test_search_without_filters_only_instantiates_limited_models
    # When no filters provided, only the limited set should be instantiated
    # This test verifies the optimization works correctly by checking results
    result = @searcher.search(nil, limit: 1, with_total: true)

    # Should return correct pagination info
    assert_equal 1, result[:models].size
    assert_equal 2, result[:total]

    # The single returned model should be properly instantiated
    model = result[:models].first
    assert_kind_of Ace::Support::Models::Models::ModelInfo, model
    assert model.id
  end

  # Test that filters still work with the new implementation
  def test_search_with_filters_returns_correct_total
    result = @searcher.search(nil, filters: {provider: "test-provider"}, limit: 10, with_total: true)

    assert_equal 1, result[:models].size
    assert_equal 1, result[:total] # Only 1 model matches the filter
  end

  private

  def setup_test_cache
    test_data = {
      "test-provider" => {
        "id" => "test-provider",
        "name" => "Test Provider",
        "env" => ["TEST_API_KEY"],
        "models" => {
          "test-model" => {
            "id" => "test-model",
            "name" => "Test Model",
            "cost" => {
              "input" => 2.5,
              "output" => 10.0
            },
            "limit" => {
              "context" => 128_000,
              "output" => 4096
            },
            "modalities" => {
              "input" => ["text"],
              "output" => ["text"]
            },
            "tool_call" => true,
            "temperature" => true
          }
        }
      },
      "another-provider" => {
        "id" => "another-provider",
        "name" => "Another Provider",
        "env" => ["ANOTHER_API_KEY"],
        "models" => {
          "another-model" => {
            "id" => "another-model",
            "name" => "Another Model",
            "cost" => {
              "input" => 1.0,
              "output" => 5.0
            },
            "limit" => {
              "context" => 32_000,
              "output" => 2048
            },
            "tool_call" => false
          }
        }
      }
    }

    # Write the test cache file
    cache_path = File.join(@temp_dir, "api.json")
    File.write(cache_path, JSON.generate(test_data))
  end
end
