# frozen_string_literal: true

require "test_helper"
require "ace/llm/models/fallback_config"

module Ace
  module LLM
    module Models
      class FallbackConfigTest < AceLlmTestCase
        def test_initializes_with_defaults
          config = FallbackConfig.new

          assert_equal true, config.enabled
          assert_equal 3, config.retry_count
          assert_equal 1.0, config.retry_delay
          assert_equal [], config.providers
          assert_equal 30.0, config.max_total_timeout
        end

        def test_initializes_with_custom_values
          config = FallbackConfig.new(
            enabled: false,
            retry_count: 5,
            retry_delay: 2.0,
            providers: ["claude-3.5-sonnet", "gpt-4"],
            max_total_timeout: 60.0
          )

          assert_equal false, config.enabled
          assert_equal 5, config.retry_count
          assert_equal 2.0, config.retry_delay
          assert_equal ["claude-3.5-sonnet", "gpt-4"], config.providers
          assert_equal 60.0, config.max_total_timeout
        end

        def test_enabled_predicate
          enabled_config = FallbackConfig.new(enabled: true)
          disabled_config = FallbackConfig.new(enabled: false)

          assert enabled_config.enabled?
          refute disabled_config.enabled?
        end

        def test_disabled_predicate
          enabled_config = FallbackConfig.new(enabled: true)
          disabled_config = FallbackConfig.new(enabled: false)

          refute enabled_config.disabled?
          assert disabled_config.disabled?
        end

        def test_has_providers_predicate
          with_providers = FallbackConfig.new(providers: ["claude"])
          without_providers = FallbackConfig.new(providers: [])

          assert with_providers.has_providers?
          refute without_providers.has_providers?
        end

        def test_from_hash_with_symbol_keys
          hash = {
            enabled: false,
            retry_count: 2,
            retry_delay: 1.5,
            providers: ["claude", "gpt"],
            max_total_timeout: 45.0
          }

          config = FallbackConfig.from_hash(hash)

          assert_equal false, config.enabled
          assert_equal 2, config.retry_count
          assert_equal 1.5, config.retry_delay
          assert_equal ["claude", "gpt"], config.providers
          assert_equal 45.0, config.max_total_timeout
        end

        def test_from_hash_with_string_keys
          hash = {
            "enabled" => false,
            "retry_count" => 2,
            "retry_delay" => 1.5,
            "providers" => ["claude", "gpt"],
            "max_total_timeout" => 45.0
          }

          config = FallbackConfig.from_hash(hash)

          assert_equal false, config.enabled
          assert_equal 2, config.retry_count
          assert_equal 1.5, config.retry_delay
          assert_equal ["claude", "gpt"], config.providers
          assert_equal 45.0, config.max_total_timeout
        end

        def test_from_hash_with_nil
          config = FallbackConfig.from_hash(nil)

          # Should create default config
          assert_equal true, config.enabled
          assert_equal 3, config.retry_count
        end

        def test_from_hash_with_partial_data
          hash = {
            retry_count: 5,
            providers: ["claude"]
          }

          config = FallbackConfig.from_hash(hash)

          # Uses defaults for missing values
          assert_equal true, config.enabled
          assert_equal 5, config.retry_count
          assert_equal 1.0, config.retry_delay
          assert_equal ["claude"], config.providers
          assert_equal 30.0, config.max_total_timeout
        end

        def test_to_h_returns_hash_representation
          config = FallbackConfig.new(
            enabled: false,
            retry_count: 2,
            retry_delay: 1.5,
            providers: ["claude"],
            max_total_timeout: 60.0
          )

          hash = config.to_h

          assert_equal false, hash[:enabled]
          assert_equal 2, hash[:retry_count]
          assert_equal 1.5, hash[:retry_delay]
          assert_equal ["claude"], hash[:providers]
          assert_equal 60.0, hash[:max_total_timeout]
        end

        def test_merge_with_another_config
          base = FallbackConfig.new(retry_count: 3, providers: ["claude"])
          other = FallbackConfig.new(retry_count: 5, retry_delay: 2.0)

          merged = base.merge(other)

          assert_equal 5, merged.retry_count
          assert_equal 2.0, merged.retry_delay
          # Providers from other (which is empty default)
          assert_equal [], merged.providers
        end

        def test_merge_with_hash
          base = FallbackConfig.new(retry_count: 3)
          hash = { retry_count: 5, providers: ["gpt"] }

          merged = base.merge(hash)

          assert_equal 5, merged.retry_count
          assert_equal ["gpt"], merged.providers
        end

        def test_validates_retry_count_is_integer
          error = assert_raises(Ace::LLM::ConfigurationError) do
            FallbackConfig.new(retry_count: "invalid")
          end

          assert_match(/retry_count must be a non-negative integer/, error.message)
        end

        def test_validates_retry_count_is_non_negative
          error = assert_raises(Ace::LLM::ConfigurationError) do
            FallbackConfig.new(retry_count: -1)
          end

          assert_match(/retry_count must be a non-negative integer/, error.message)
        end

        def test_validates_retry_delay_is_numeric
          error = assert_raises(Ace::LLM::ConfigurationError) do
            FallbackConfig.new(retry_delay: "invalid")
          end

          assert_match(/retry_delay must be a positive number/, error.message)
        end

        def test_validates_retry_delay_is_positive
          error = assert_raises(Ace::LLM::ConfigurationError) do
            FallbackConfig.new(retry_delay: 0)
          end

          assert_match(/retry_delay must be a positive number/, error.message)
        end

        def test_validates_providers_is_array
          error = assert_raises(Ace::LLM::ConfigurationError) do
            FallbackConfig.new(providers: "invalid")
          end

          assert_match(/providers must be an array/, error.message)
        end

        def test_validates_no_duplicate_providers
          error = assert_raises(Ace::LLM::ConfigurationError) do
            FallbackConfig.new(providers: ["claude", "gpt", "claude"])
          end

          assert_match(/providers contains duplicates/, error.message)
        end

        def test_validates_providers_are_strings
          error = assert_raises(Ace::LLM::ConfigurationError) do
            FallbackConfig.new(providers: [123, "claude"])
          end

          assert_match(/each provider must be a non-empty string/, error.message)
        end

        def test_validates_providers_are_non_empty
          error = assert_raises(Ace::LLM::ConfigurationError) do
            FallbackConfig.new(providers: [""])
          end

          assert_match(/each provider must be a non-empty string/, error.message)
        end

        def test_validates_max_total_timeout_is_numeric
          error = assert_raises(Ace::LLM::ConfigurationError) do
            FallbackConfig.new(max_total_timeout: "invalid")
          end

          assert_match(/max_total_timeout must be a positive number/, error.message)
        end

        def test_validates_max_total_timeout_is_positive
          error = assert_raises(Ace::LLM::ConfigurationError) do
            FallbackConfig.new(max_total_timeout: 0)
          end

          assert_match(/max_total_timeout must be a positive number/, error.message)
        end

        def test_providers_are_frozen
          config = FallbackConfig.new(providers: ["claude", "gpt"])

          assert config.providers.frozen?
        end

        def test_to_h_returns_unfrozen_providers_array
          config = FallbackConfig.new(providers: ["claude"])
          hash = config.to_h

          # Should be able to modify the returned array without affecting original
          hash[:providers] << "gpt"
          assert_equal ["claude"], config.providers
        end

        def test_zero_retry_count_is_valid
          config = FallbackConfig.new(retry_count: 0)
          assert_equal 0, config.retry_count
        end

        def test_float_retry_delay_is_valid
          config = FallbackConfig.new(retry_delay: 0.5)
          assert_equal 0.5, config.retry_delay
        end

        def test_integer_retry_delay_is_valid
          config = FallbackConfig.new(retry_delay: 2)
          assert_equal 2, config.retry_delay
        end
      end
    end
  end
end
