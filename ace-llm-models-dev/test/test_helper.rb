# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "ace/llm/models_dev"

# Base test case for ace-llm-models-dev
class ModelsDevTestCase < Minitest::Test
  # Sample provider data for tests
  def sample_provider_data
    {
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
    }
  end

  # Sample API response
  def sample_api_response
    {
      "test-provider" => sample_provider_data,
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
            }
          }
        }
      }
    }
  end

  # Create a temporary cache directory for tests
  def with_temp_cache
    Dir.mktmpdir("ace-llm-models-test") do |dir|
      yield dir
    end
  end
end
