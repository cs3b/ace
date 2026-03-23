# frozen_string_literal: true

require_relative "../test_helper"

class ModelValidatorTest < AceModelsTestCase
  def setup
    @temp_dir = Dir.mktmpdir("ace-models-test")
    @cache_manager = Ace::Support::Models::Molecules::CacheManager.new(cache_dir: @temp_dir)
    @validator = Ace::Support::Models::Molecules::ModelValidator.new(cache_manager: @cache_manager)

    # Setup test data
    setup_test_cache
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  # Test Levenshtein length cap
  def test_levenshtein_distance_caps_long_inputs
    # Access private method for testing
    validator = Ace::Support::Models::Molecules::ModelValidator.new(cache_manager: @cache_manager)

    # Normal inputs should return numeric distance
    normal_result = validator.send(:levenshtein_distance, "hello", "hallo")
    assert_kind_of Numeric, normal_result
    assert_equal 1, normal_result

    # Inputs exceeding MAX_LEVENSHTEIN_LENGTH should return infinity
    long_string = "a" * 501
    short_string = "hello"

    result_long_first = validator.send(:levenshtein_distance, long_string, short_string)
    assert_equal Float::INFINITY, result_long_first

    result_long_second = validator.send(:levenshtein_distance, short_string, long_string)
    assert_equal Float::INFINITY, result_long_second

    # Both long should also return infinity
    result_both_long = validator.send(:levenshtein_distance, long_string, long_string)
    assert_equal Float::INFINITY, result_both_long
  end

  def test_levenshtein_distance_at_boundary
    validator = Ace::Support::Models::Molecules::ModelValidator.new(cache_manager: @cache_manager)

    # Exactly at max length should work
    at_limit = "a" * 500
    result = validator.send(:levenshtein_distance, at_limit, at_limit)
    assert_equal 0, result

    # One over should fail
    over_limit = "a" * 501
    result = validator.send(:levenshtein_distance, over_limit, over_limit)
    assert_equal Float::INFINITY, result
  end

  def test_find_suggestions_handles_pathological_inputs
    # Ensure excessively long model names don't cause performance issues
    validator = Ace::Support::Models::Molecules::ModelValidator.new(cache_manager: @cache_manager)

    # Create a pathological target (long string)
    long_target = "x" * 600

    # The find_suggestions method should handle this gracefully
    # Due to the length delta filter, most candidates will be filtered out anyway
    # And the levenshtein cap will prevent O(n*m) blowups
    model_names = ["test-model", "another-model"]

    result = validator.send(:find_suggestions, model_names, long_target)
    assert_kind_of Array, result
  end

  def test_max_levenshtein_length_constant_defined
    assert_equal 500, Ace::Support::Models::Molecules::ModelValidator::MAX_LEVENSHTEIN_LENGTH
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
            "cost" => {"input" => 2.5, "output" => 10.0},
            "limit" => {"context" => 128_000, "output" => 4096}
          },
          "another-model" => {
            "id" => "another-model",
            "name" => "Another Model",
            "cost" => {"input" => 1.0, "output" => 5.0},
            "limit" => {"context" => 32_000, "output" => 2048}
          }
        }
      }
    }

    cache_path = File.join(@temp_dir, "api.json")
    File.write(cache_path, JSON.generate(test_data))
  end
end
