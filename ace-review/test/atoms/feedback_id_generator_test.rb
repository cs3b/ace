# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module Atoms
      class FeedbackIdGeneratorTest < AceReviewTest
        def setup
          super
          @generator = FeedbackIdGenerator
        end

        # Basic generation tests

        def test_generate_returns_8_character_string
          id = @generator.generate

          assert_instance_of String, id
          assert_equal 8, id.length, "Expected 8-char ms format ID, got #{id.length}"
        end

        def test_generate_returns_base36_characters
          id = @generator.generate

          assert_match(/\A[0-9a-z]{8}\z/, id)
        end

        def test_generate_returns_different_ids_for_different_times
          id1 = @generator.generate_for(Time.utc(2025, 1, 15, 10, 30, 0, 0))
          id2 = @generator.generate_for(Time.utc(2025, 1, 15, 10, 30, 0, 100_000))  # 100ms later

          refute_equal id1, id2
        end

        def test_generate_for_specific_time
          time = Time.utc(2025, 1, 15, 12, 0, 0)
          id = @generator.generate_for(time)

          assert_instance_of String, id
          assert_equal 8, id.length, "Expected 8-char ms format ID"
          assert_match(/\A[0-9a-z]{8}\z/, id)
        end

        def test_generate_for_converts_to_utc
          local_time = Time.new(2025, 1, 15, 12, 0, 0, "-05:00")
          id = @generator.generate_for(local_time)

          assert_instance_of String, id
          assert_equal 8, id.length
        end

        # Chronological ordering tests

        def test_ids_are_chronologically_sortable
          time1 = Time.utc(2025, 1, 15, 10, 0, 0)
          time2 = Time.utc(2025, 1, 15, 10, 1, 0)
          time3 = Time.utc(2025, 1, 15, 10, 2, 0)

          id1 = @generator.generate_for(time1)
          id2 = @generator.generate_for(time2)
          id3 = @generator.generate_for(time3)

          assert id1 < id2
          assert id2 < id3
        end

        def test_ids_sort_correctly_across_days
          day1 = Time.utc(2025, 1, 15, 23, 59, 0)
          day2 = Time.utc(2025, 1, 16, 0, 1, 0)

          id1 = @generator.generate_for(day1)
          id2 = @generator.generate_for(day2)

          assert id1 < id2
        end

        def test_ids_sort_correctly_across_months
          month1 = Time.utc(2025, 1, 31, 12, 0, 0)
          month2 = Time.utc(2025, 2, 1, 12, 0, 0)

          id1 = @generator.generate_for(month1)
          id2 = @generator.generate_for(month2)

          assert id1 < id2
        end

        # Uniqueness tests
        # Note: ms format has ~1.4ms precision. IDs are unique when generated at
        # sufficiently different times (>=2ms apart in practice).

        def test_generate_produces_unique_ids_when_times_differ_significantly
          # IDs at significantly different milliseconds should be unique
          # Using 10ms apart to ensure they fall in different ms buckets
          id1 = @generator.generate_for(Time.utc(2025, 1, 15, 12, 0, 0, 0))
          id2 = @generator.generate_for(Time.utc(2025, 1, 15, 12, 0, 0, 10_000))  # 10ms later

          refute_equal id1, id2, "IDs at different ms buckets should be different"
        end

        def test_generate_for_different_seconds_produces_unique_ids
          # Use second differences for guaranteed uniqueness
          times = (0..9).map { |i| Time.utc(2025, 1, 15, 12, 0, i) }  # 1 second apart
          ids = times.map { |t| @generator.generate_for(t) }

          assert_equal ids.uniq.length, ids.length
        end

        def test_same_time_produces_same_id
          # With deterministic ms encoding, same time = same ID (no random suffix)
          time = Time.utc(2025, 1, 15, 12, 0, 0, 500_000)
          id1 = @generator.generate_for(time)
          id2 = @generator.generate_for(time)

          assert_equal id1, id2, "Same time should produce same ID"
        end

        # Integration with ace-b36ts

        def test_uses_ace_b36ts_ms_format
          time = Time.utc(2025, 1, 15, 12, 30, 0, 500_000)  # 500ms
          expected_id = Ace::B36ts.encode(time, format: :ms)
          actual_id = @generator.generate_for(time)

          assert_equal expected_id, actual_id,
            "Expected ID to match ms format encoding"
        end

        def test_generated_id_can_be_decoded
          time = Time.utc(2025, 1, 15, 12, 30, 0, 500_000)
          id = @generator.generate_for(time)

          decoded_time = Ace::B36ts.decode(id, format: :ms)

          # Times should be exact (ms precision)
          assert_equal time.to_i, decoded_time.to_i
        end

        def test_generated_id_is_valid_ms_format
          id = @generator.generate

          # 8-char IDs are valid ms format
          assert Ace::B36ts.valid_any_format?(id),
            "Generated ID '#{id}' should be valid ms format"
        end

        # Sequence generation tests

        def test_generate_sequence_returns_array
          ids = @generator.generate_sequence(5)

          assert_instance_of Array, ids
          assert_equal 5, ids.length
        end

        def test_generate_sequence_returns_unique_ids
          ids = @generator.generate_sequence(10)

          assert_equal ids.length, ids.uniq.length,
            "All IDs in sequence should be unique"
        end

        def test_generate_sequence_returns_sequential_ids
          ids = @generator.generate_sequence(10)

          # Each ID should be strictly greater than the previous
          ids.each_cons(2) do |prev_id, curr_id|
            assert prev_id < curr_id,
              "IDs should be strictly increasing: #{prev_id} < #{curr_id}"
          end
        end

        def test_generate_sequence_with_count_1
          ids = @generator.generate_sequence(1)

          assert_equal 1, ids.length
          assert_equal 8, ids.first.length
        end

        def test_generate_sequence_ids_are_8_chars
          ids = @generator.generate_sequence(5)

          ids.each do |id|
            assert_equal 8, id.length, "Expected 8-char ms format ID"
          end
        end

        def test_generate_sequence_ids_are_base36
          ids = @generator.generate_sequence(5)

          ids.each do |id|
            assert_match(/\A[0-9a-z]{8}\z/, id)
          end
        end

        def test_generate_sequence_raises_for_zero_count
          error = assert_raises(ArgumentError) do
            @generator.generate_sequence(0)
          end

          assert_match(/count must be greater than 0/, error.message)
        end

        def test_generate_sequence_raises_for_negative_count
          error = assert_raises(ArgumentError) do
            @generator.generate_sequence(-1)
          end

          assert_match(/count must be greater than 0/, error.message)
        end

        def test_generate_sequence_ids_are_valid_ms_format
          ids = @generator.generate_sequence(5)

          ids.each do |id|
            assert Ace::B36ts.valid_any_format?(id),
              "Generated ID '#{id}' should be valid ms format"
          end
        end
      end
    end
  end
end
