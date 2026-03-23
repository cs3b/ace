# frozen_string_literal: true

require_relative "test_helper"

module Ace
  class TimestampTest < Minitest::Test
    def setup
      Ace::B36ts.reset_config!
    end

    # ===================
    # Convenience Method Tests
    # ===================

    def test_encode_convenience_method
      time = Time.utc(2025, 1, 6, 12, 30, 0)
      result = Ace::B36ts.encode(time)

      assert_equal 6, result.length
      assert_match(/\A[0-9a-z]{6}\z/, result)
    end

    def test_encode_with_year_zero_override
      time = Time.utc(2025, 1, 1, 0, 0, 0)
      result = Ace::B36ts.encode(time, year_zero: 2025)

      assert_equal "000000", result
    end

    def test_decode_convenience_method
      result = Ace::B36ts.decode("000000")

      assert_instance_of Time, result
      assert_equal 2000, result.year
      assert_equal 1, result.month
      assert_equal 1, result.day
    end

    def test_decode_with_year_zero_override
      result = Ace::B36ts.decode("000000", year_zero: 2025)

      assert_equal 2025, result.year
    end

    def test_valid_convenience_method
      assert Ace::B36ts.valid?("abc123")
      refute Ace::B36ts.valid?("invalid!")
    end

    def test_detect_format_convenience_method
      assert_equal :"2sec", Ace::B36ts.detect_format("abc123")
      assert_equal :timestamp, Ace::B36ts.detect_format("20250101-120000")
      # "invalid" is 7 chars with valid base36 chars, so it matches 50ms pattern
      # Use a string with invalid characters to test nil return
      assert_nil Ace::B36ts.detect_format("invalid!")
    end

    def test_now_generates_current_time_id
      result = Ace::B36ts.now

      assert_equal 6, result.length
      assert_match(/\A[0-9a-z]{6}\z/, result)

      # Should decode to approximately current time
      decoded = Ace::B36ts.decode(result)
      assert_in_delta Time.now.utc.to_i, decoded.to_i, 10
    end

    def test_config_returns_hash
      config = Ace::B36ts.config

      assert_instance_of Hash, config
      assert config.key?(:year_zero)
      assert config.key?(:alphabet)
    end

    # ===================
    # Debug Mode Tests
    # ===================

    def test_debug_returns_false_by_default
      # Stub ENV to return nil for debug env vars (parallel-safe)
      ENV.stub(:[], ->(key) {}) do
        refute Ace::B36ts.debug?
      end
    end

    def test_debug_returns_true_when_ace_debug_set
      # Stub ENV to return "1" for ACE_DEBUG (parallel-safe)
      env_stub = ->(key) { (key == "ACE_DEBUG") ? "1" : nil }
      ENV.stub(:[], env_stub) do
        assert Ace::B36ts.debug?
      end
    end

    def test_debug_returns_true_when_debug_set
      # Stub ENV to return "1" for DEBUG (parallel-safe)
      env_stub = ->(key) { (key == "DEBUG") ? "1" : nil }
      ENV.stub(:[], env_stub) do
        assert Ace::B36ts.debug?
      end
    end

    # ===================
    # Integration Tests
    # ===================

    def test_encode_decode_roundtrip
      original = Time.utc(2025, 6, 15, 14, 30, 45)
      encoded = Ace::B36ts.encode(original)
      decoded = Ace::B36ts.decode(encoded)

      assert_equal original.year, decoded.year
      assert_equal original.month, decoded.month
      assert_equal original.day, decoded.day
      assert_in_delta original.to_i, decoded.to_i, 3
    end

    def test_module_error_class_exists
      assert_kind_of Class, Ace::B36ts::Error
      assert Ace::B36ts::Error < StandardError
    end
  end
end
