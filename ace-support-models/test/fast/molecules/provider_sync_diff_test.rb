# frozen_string_literal: true

require_relative "../../test_helper"

class ProviderSyncDiffTest < AceModelsTestCase
  def setup
    @diff = Ace::Support::Models::Molecules::ProviderSyncDiff.new(cache_manager: Minitest::Mock.new)
  end

  def test_diff_provider_keeps_exact_openrouter_suffix_models_stable
    config = {
      "name" => "openrouter",
      "models" => ["google/gemma-3-12b-it:free"]
    }
    provider_data = {
      "models" => {
        "google/gemma-3-12b-it:free" => {
          "name" => "Gemma 3 12B IT Free",
          "status" => "active",
          "limit" => {"context" => 262_144, "output" => 65_536}
        }
      }
    }

    result = @diff.diff_provider(config, provider_data, provider_name: "openrouter")

    assert_equal [], result[:added]
    assert_equal [], result[:removed]
    assert_equal ["google/gemma-3-12b-it:free"], result[:unchanged]
    assert_equal({"default" => {"context" => 262_144, "output" => 65_536}}, result[:desired_limits])
  end
end
