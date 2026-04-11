# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module B36ts
    module Molecules
      class ConfigResolverTest < Minitest::Test
        def setup
          ConfigResolver.reset!
        end

        def teardown
          ConfigResolver.reset!
        end

        # ===================
        # Default Configuration Tests
        # ===================

        def test_resolve_returns_default_year_zero
          config = ConfigResolver.resolve

          assert_equal 2000, config[:year_zero]
        end

        def test_resolve_returns_default_alphabet
          config = ConfigResolver.resolve

          assert_equal "0123456789abcdefghijklmnopqrstuvwxyz", config[:alphabet]
        end

        def test_resolve_returns_hash_with_symbol_keys
          config = ConfigResolver.resolve

          assert config.key?(:year_zero)
          assert config.key?(:alphabet)
          refute config.key?("year_zero")
          refute config.key?("alphabet")
        end

        # ===================
        # Override Tests
        # ===================

        def test_resolve_applies_runtime_overrides
          config = ConfigResolver.resolve(year_zero: 2025)

          assert_equal 2025, config[:year_zero]
        end

        def test_resolve_ignores_nil_overrides
          config = ConfigResolver.resolve(year_zero: nil)

          assert_equal 2000, config[:year_zero]
        end

        def test_resolve_accepts_string_keys_in_overrides
          config = ConfigResolver.resolve("year_zero" => 2025)

          assert_equal 2025, config[:year_zero]
        end

        def test_resolve_allows_custom_alphabet_override
          custom_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
          config = ConfigResolver.resolve(alphabet: custom_alphabet)

          assert_equal custom_alphabet, config[:alphabet]
        end

        # ===================
        # Convenience Method Tests
        # ===================

        def test_year_zero_returns_default_value
          result = ConfigResolver.year_zero

          assert_equal 2000, result
        end

        def test_year_zero_accepts_override
          result = ConfigResolver.year_zero(2025)

          assert_equal 2025, result
        end

        def test_alphabet_returns_default_value
          result = ConfigResolver.alphabet

          assert_equal "0123456789abcdefghijklmnopqrstuvwxyz", result
        end

        def test_alphabet_accepts_override
          result = ConfigResolver.alphabet("ABC")

          assert_equal "ABC", result
        end

        # ===================
        # Reset Tests
        # ===================

        def test_reset_clears_cached_config
          # Resolve once to cache
          ConfigResolver.resolve
          ConfigResolver.reset!

          # Should still work after reset
          config = ConfigResolver.resolve
          assert_equal 2000, config[:year_zero]
        end

        # ===================
        # Error Handling Tests
        # ===================

        def test_resolve_handles_missing_config_gracefully
          # Even without a config file, should return defaults
          ConfigResolver.reset!
          config = ConfigResolver.resolve

          assert_equal 2000, config[:year_zero]
          assert_equal "0123456789abcdefghijklmnopqrstuvwxyz", config[:alphabet]
        end

        # ===================
        # Validation Tests
        # ===================

        def test_resolve_raises_on_invalid_alphabet_length
          error = assert_raises(ArgumentError) do
            ConfigResolver.resolve(alphabet: "abc")
          end

          assert_match(/alphabet must be exactly 36 characters/, error.message)
        end

        def test_resolve_raises_on_nil_alphabet
          error = assert_raises(ArgumentError) do
            ConfigResolver.resolve(alphabet: "")
          end

          assert_match(/alphabet must be exactly 36 characters/, error.message)
        end

        def test_resolve_raises_on_duplicate_alphabet_characters
          error = assert_raises(ArgumentError) do
            ConfigResolver.resolve(alphabet: "0123456789abcdefghijklmnopqrstuvwxyy")
          end

          assert_match(/alphabet must contain 36 unique characters/, error.message)
        end

        def test_resolve_raises_on_year_zero_too_low
          error = assert_raises(ArgumentError) do
            ConfigResolver.resolve(year_zero: 1899)
          end

          assert_match(/year_zero must be between 1900-2100/, error.message)
        end

        def test_resolve_raises_on_year_zero_too_high
          error = assert_raises(ArgumentError) do
            ConfigResolver.resolve(year_zero: 2101)
          end

          assert_match(/year_zero must be between 1900-2100/, error.message)
        end

        def test_resolve_accepts_valid_custom_alphabet
          custom_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
          config = ConfigResolver.resolve(alphabet: custom_alphabet)

          assert_equal custom_alphabet, config[:alphabet]
        end

        def test_resolve_accepts_year_zero_at_boundaries
          # Test lower boundary
          config = ConfigResolver.resolve(year_zero: 1900)
          assert_equal 1900, config[:year_zero]

          ConfigResolver.reset!

          # Test upper boundary
          config = ConfigResolver.resolve(year_zero: 2100)
          assert_equal 2100, config[:year_zero]
        end

        def test_resolve_raises_on_invalid_default_format
          error = assert_raises(ArgumentError) do
            ConfigResolver.resolve(default_format: :invalid_format)
          end

          assert_match(/default_format must be one of/, error.message)
          assert_match(/invalid_format/, error.message)
        end

        def test_resolve_accepts_valid_default_format
          config = ConfigResolver.resolve(default_format: :"40min")
          assert_equal :"40min", config[:default_format]
        end

        def test_resolve_accepts_default_format_as_string
          config = ConfigResolver.resolve(default_format: "ms")
          # Validation converts string to symbol for comparison
          assert_equal "ms", config[:default_format]
        end
      end
    end
  end
end
